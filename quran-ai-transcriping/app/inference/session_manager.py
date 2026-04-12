"""
Recitation Session Manager

Manages per-connection recitation sessions for real-time word-level feedback.
Sessions are ephemeral and tied to WebSocket connections.
"""

import logging
import re
import time
import uuid
from typing import Dict, Optional, List, Tuple
from rapidfuzz import fuzz

logger = logging.getLogger(__name__)


class RecitationSessionManager:
    """Manages multiple recitation sessions (one per WebSocket connection)."""

    def __init__(self):
        self.sessions: Dict[str, 'RecitationSession'] = {}

    def create_session(self, surah_id: int, client_words: list = None) -> 'RecitationSession':
        """Create a new recitation session for a surah.

        Args:
            surah_id: Surah number
            client_words: Optional list of word dicts from the Flutter client.
                         Each dict has: ayah, word_index, text.
                         When provided, ensures the same Warsh text used by
                         Flutter/Laravel is used for alignment.
        """
        session = RecitationSession(surah_id, client_words=client_words)
        self.sessions[session.session_id] = session
        logger.info(f"Created session {session.session_id} for Surah {surah_id}")
        return session

    def get_session(self, session_id: str) -> Optional['RecitationSession']:
        """Retrieve an existing session by ID."""
        return self.sessions.get(session_id)

    def destroy_session(self, session_id: str) -> None:
        """Destroy a session and free resources."""
        if session_id in self.sessions:
            del self.sessions[session_id]
            logger.info(f"Destroyed session {session_id}")

    def cleanup_old_sessions(self, max_age_seconds: int = 3600) -> int:
        """Remove sessions older than max_age_seconds. Returns count removed."""
        now = time.time()
        old_sessions = [
            sid for sid, session in self.sessions.items()
            if now - session.created_at > max_age_seconds
        ]
        for sid in old_sessions:
            self.destroy_session(sid)
        return len(old_sessions)


class RecitationSession:
    """
    Represents a single recitation session.

    Tracks:
    - Reference text for the selected surah
    - Current position in recitation
    - Word-by-word status (correct/mistake/skipped)
    """

    # Look ahead N words when searching for skips
    SKIP_LOOKAHEAD = 3

    # Minimum match score for skip detection (stricter than normal match)
    SKIP_MATCH_THRESHOLD = 80

    # After this many consecutive misses, widen the lookahead to catch up
    # with where the user actually is in the surah
    RECOVERY_MISS_THRESHOLD = 5
    RECOVERY_LOOKAHEAD = 15

    # Completion safety: minimum ratios to allow surah completion
    MIN_CORRECT_RATIO_FOR_COMPLETION = 0.40
    MIN_PROCESSED_RATIO_FOR_COMPLETION = 0.30

    def __init__(self, surah_id: int, client_words: list = None):
        self.session_id = str(uuid.uuid4())
        self.surah_id = surah_id
        self.created_at = time.time()

        # Load reference text — prefer client-provided words (same Warsh source as UI)
        if client_words:
            self.reference_ayahs = self._load_from_client_words(client_words)
            logger.info(f"Session {self.session_id}: Using client-provided Warsh word data")
        else:
            self.reference_ayahs = self._load_surah_text(surah_id)
            logger.info(f"Session {self.session_id}: Using quran_ayah_lookup fallback")

        self.total_ayahs = len(self.reference_ayahs)

        # Build flat word list for easier alignment
        self.flat_words: List[Tuple[int, int, str, str]] = []  # (ayah_num, word_idx, display_text, normalized_text)
        for ayah in self.reference_ayahs:
            ayah_num = ayah['number']
            for word_idx, (display_word, norm_word) in enumerate(
                zip(ayah['words_display'], ayah['words_normalized'])
            ):
                self.flat_words.append((ayah_num, word_idx, display_word, norm_word))

        # Session state
        self.current_position = 0  # Index in flat_words
        self.word_statuses: List[Dict] = []  # List of word status dicts
        self.session_transcription = ""  # Accumulated transcription text
        self._last_processed_word_count = 0  # Track how many spoken words we've already aligned
        self.last_matched_norm = None  # Last matched normalized word (for repetition detection)
        self._consecutive_misses = 0  # Track consecutive mismatches

        logger.info(
            f"Session {self.session_id}: Loaded Surah {surah_id} "
            f"with {self.total_ayahs} ayahs, {len(self.flat_words)} words"
        )

    def get_reference_prompt(self, lookahead: int = 0) -> str:
        """
        Get reference Quran text to use as Whisper prompt conditioning.

        Returns a SLIDING WINDOW of reference text around the current position.
        Only the last ~30 words are included to stay within Whisper's 448-token
        limit. Using the ACTUAL reference text gives the model perfect context.

        NOTE: lookahead defaults to 0 — we only include CONFIRMED past words.
        Including unspoken future words confuses Whisper (it thinks they're
        already transcribed and produces empty output).
        """
        if not self.flat_words:
            return ""

        end_pos = min(self.current_position + lookahead, len(self.flat_words))

        # At the very start, seed with the first 4 words (typically bismillah)
        if end_pos == 0:
            seed_end = min(4, len(self.flat_words))
            words = [w[2] for w in self.flat_words[:seed_end]]
            return ' '.join(words)

        MAX_PROMPT_WORDS = 30
        start_pos = max(0, end_pos - MAX_PROMPT_WORDS)

        # Use display_text (index 2) which has diacritics — better for Whisper
        words = [w[2] for w in self.flat_words[start_pos:end_pos]]
        return ' '.join(words)

    def _load_from_client_words(self, words_data: list) -> List[Dict]:
        """
        Load reference text from words provided by the Flutter client.
        This ensures the same Warsh text used by Flutter/Laravel is used
        for alignment, eliminating the text source mismatch problem.

        Args:
            words_data: List of dicts with: ayah, word_index, text
        """
        ayahs_dict = {}
        for word in words_data:
            ayah_num = word['ayah']
            if ayah_num not in ayahs_dict:
                ayahs_dict[ayah_num] = {
                    'number': ayah_num,
                    'words_display': [],
                    'words_normalized': [],
                }
            display_text = word['text']
            normalized_text = self._normalize_arabic(display_text)
            ayahs_dict[ayah_num]['words_display'].append(display_text)
            ayahs_dict[ayah_num]['words_normalized'].append(normalized_text)

        ayahs = []
        for ayah_num in sorted(ayahs_dict.keys()):
            ayah = ayahs_dict[ayah_num]
            ayah['text'] = ' '.join(ayah['words_display'])
            ayah['text_normalized'] = ' '.join(ayah['words_normalized'])
            ayah['is_basmalah'] = (ayah_num == 1 and len(ayah['words_display']) >= 4)
            ayahs.append(ayah)

        return ayahs

    def _load_surah_text(self, surah_id: int) -> List[Dict]:
        """
        Load all ayahs for the surah using quran-ayah-lookup (fallback).
        Used when client does not provide word data.
        """
        try:
            import quran_ayah_lookup as qal
            results = qal.get_surah_verses(surah_id)
        except (AttributeError, ImportError) as e:
            raise ValueError(f"Could not retrieve verses for Surah {surah_id}: {e}")

        if not results:
            raise ValueError(f"Surah {surah_id} not found")

        ayahs = []
        for verse in results:
            words_display = verse.text.split()
            words_normalized = verse.text_normalized.split()

            ayahs.append({
                'number': verse.ayah_number,
                'text': verse.text,
                'text_normalized': verse.text_normalized,
                'words_display': words_display,
                'words_normalized': words_normalized,
                'is_basmalah': verse.is_basmalah
            })

        return ayahs

    def deduplicate_overlap(self, session_text: str, new_text: str) -> str:
        """
        Remove overlapping words between accumulated session text and new chunk text.

        Uses normalized fuzzy matching to detect overlap at the boundary:
        end of session_text vs start of new_text.

        This replaces the fragile SequenceMatcher-based merge that could
        produce nonsense text when overlap detection failed.

        Args:
            session_text: Previously accumulated transcription
            new_text: New chunk's transcription

        Returns:
            Combined text with overlap removed
        """
        if not session_text or not new_text:
            return (session_text + ' ' + new_text).strip()

        session_words = session_text.split()
        new_words = new_text.split()

        # Check for overlap: end of session matches start of new chunk
        max_check = min(len(session_words), len(new_words), 10)
        best_overlap = 0

        for overlap_len in range(max_check, 0, -1):
            tail = session_words[-overlap_len:]
            head = new_words[:overlap_len]

            matches = 0
            for t, h in zip(tail, head):
                t_norm = self._normalize_arabic(t)
                h_norm = self._normalize_arabic(h)
                if fuzz.ratio(t_norm, h_norm) > 80:
                    matches += 1

            # Require 70% of overlap words to match
            if matches >= max(1, int(overlap_len * 0.7)):
                best_overlap = overlap_len
                break

        if best_overlap > 0:
            remaining = ' '.join(new_words[best_overlap:])
            result = session_text + (' ' + remaining if remaining else '')
            logger.info(
                f"Session {self.session_id}: Removed {best_overlap}-word overlap at chunk boundary"
            )
        else:
            result = session_text + ' ' + new_text
            logger.debug(
                f"Session {self.session_id}: No overlap detected, concatenating chunks"
            )

        return result.strip()

    def align_transcription(self, new_transcription: str) -> Dict:
        """
        Align new transcription text against reference.
        Only processes words that haven't been aligned yet.

        Args:
            new_transcription: Full accumulated transcription text

        Returns:
            Dict with word statuses and current position
        """
        spoken_words = new_transcription.strip().split()

        if not spoken_words:
            return self._build_response()

        # Only process NEW words (skip already-aligned ones)
        new_words = spoken_words[self._last_processed_word_count:]
        self._last_processed_word_count = len(spoken_words)

        if not new_words:
            return self._build_response()

        # Sequential alignment starting from current position
        for spoken_word in new_words:
            if self.current_position >= len(self.flat_words):
                break  # Reached end of surah

            # Normalize spoken word for comparison
            spoken_norm = self._normalize_arabic(spoken_word)

            # Try to match at expected position
            ayah_num, word_idx, display_word, raw_norm_word = self.flat_words[self.current_position]
            expected_norm = self._normalize_arabic(raw_norm_word)

            # --- Repetition Handling ---
            # If the user repeats the LAST word (stuttering or correction),
            # ignore it instead of comparing to the NEXT word (which would mismatch).
            if self.last_matched_norm:
                repetition_score = fuzz.ratio(spoken_norm, self.last_matched_norm)

                # Only ignore if it looks like a repetition AND doesn't match the next expected word
                is_valid_next_word = fuzz.ratio(spoken_norm, expected_norm) >= self._get_threshold(expected_norm)

                if repetition_score > 92 and not is_valid_next_word:
                    logger.info(
                        f"Session {self.session_id}: Ignoring repetition "
                        f"spoken='{spoken_norm}' matches last='{self.last_matched_norm}' ({repetition_score}%)"
                    )
                    continue  # Skip this spoken word, do not advance cursor

            score = fuzz.ratio(spoken_norm, expected_norm)
            threshold = self._get_threshold(expected_norm)

            # Log alignment attempt for debugging
            logger.info(
                f"Session {self.session_id}: ALIGN pos={self.current_position} "
                f"spoken='{spoken_norm}' vs expected='{expected_norm}' "
                f"→ score={score} (thresh={threshold})"
            )

            if score >= threshold:
                # Direct match at expected position
                self._record_word_status(
                    ayah_num, word_idx, display_word, 'correct', spoken_word, score
                )
                self.current_position += 1
                self.last_matched_norm = spoken_norm
                self._consecutive_misses = 0
                continue

            # Look ahead for skip detection.
            # Normal mode: lookahead=3, threshold=80
            # Recovery mode: after 5+ consecutive misses, widen to 15 words
            #   with a lower threshold (70) to catch up with where the user
            #   actually is in the surah.
            if self._consecutive_misses >= self.RECOVERY_MISS_THRESHOLD:
                lookahead = self.RECOVERY_LOOKAHEAD
                skip_threshold = 70
            else:
                lookahead = self.SKIP_LOOKAHEAD
                skip_threshold = self.SKIP_MATCH_THRESHOLD

            best_ahead_score = 0
            best_ahead_offset = -1

            remaining = len(self.flat_words) - self.current_position
            for offset in range(1, min(lookahead + 1, remaining)):
                _, _, _, ahead_raw_norm = self.flat_words[self.current_position + offset]
                ahead_norm = self._normalize_arabic(ahead_raw_norm)

                ahead_score = fuzz.ratio(spoken_norm, ahead_norm)

                if ahead_score > best_ahead_score and ahead_score >= skip_threshold:
                    best_ahead_score = ahead_score
                    best_ahead_offset = offset

            if best_ahead_offset > 0:
                # Skip detected - mark skipped words as mistakes
                for skip_offset in range(best_ahead_offset):
                    skip_ayah, skip_word_idx, skip_display, _ = self.flat_words[self.current_position + skip_offset]
                    self._record_word_status(
                        skip_ayah, skip_word_idx, skip_display, 'mistake', None, 0
                    )

                if self._consecutive_misses >= self.RECOVERY_MISS_THRESHOLD:
                    logger.info(
                        f"Session {self.session_id}: RECOVERY after {self._consecutive_misses} misses "
                        f"— jumped {best_ahead_offset} words to pos={self.current_position + best_ahead_offset}"
                    )

                # Move position past skipped words
                self.current_position += best_ahead_offset

                # Mark the matched word as correct
                match_ayah, match_word_idx, match_display, _ = self.flat_words[self.current_position]
                self._record_word_status(
                    match_ayah, match_word_idx, match_display, 'correct', spoken_word, best_ahead_score
                )
                self.current_position += 1
                self.last_matched_norm = spoken_norm
                self._consecutive_misses = 0
            else:
                # Mistake - word doesn't match expected or any nearby word
                # DO NOT advance position (hold pointer)
                self._consecutive_misses += 1
                logger.info(
                    f"Session {self.session_id}: MISTAKE spoken='{spoken_norm}' "
                    f"best_ahead={best_ahead_score} consecutive_misses={self._consecutive_misses} "
                    f"- POINTER HELD at pos={self.current_position}"
                )
                self._record_word_status(
                    ayah_num, word_idx, display_word, 'mistake', spoken_word, score
                )

        return self._build_response()

    def _get_threshold(self, expected_norm: str) -> int:
        """Get adaptive match threshold based on word length.

        Thresholds raised from 50/70 to 60/65/75 to reduce false positives
        that were causing wrong words to advance the pointer.
        """
        word_len = len(expected_norm)
        if word_len <= 2:
            return 60   # was 50 — e.g. 2-char words need tighter match
        elif word_len <= 3:
            return 65   # was 50 — short words still need reasonable match
        else:
            return 75   # was 70 — longer words get stricter check

    def _record_word_status(
        self,
        ayah: int,
        word_index: int,
        expected: str,
        status: str,
        spoken: Optional[str],
        score: float
    ) -> None:
        """Record the status of a word."""
        word_status = {
            'ayah': ayah,
            'word_index': word_index,
            'expected': expected,
            'status': status,
            'spoken': spoken,
            'score': round(score, 2)
        }
        self.word_statuses.append(word_status)

        logger.debug(
            f"Session {self.session_id}: Surah {self.surah_id}:{ayah} "
            f"word {word_index} ({expected}) -> {status} "
            f"(spoken: {spoken}, score: {score:.1f})"
        )

    def _build_response(self) -> Dict:
        """Build response payload for client.

        Includes a completion safety check: surah completion requires
        minimum correct ratio and processed ratio to prevent false
        completion from bad fuzzy matches.
        """
        # Determine current ayah from position
        current_ayah = 1
        if self.current_position < len(self.flat_words):
            current_ayah = self.flat_words[self.current_position][0]
        elif self.flat_words:
            current_ayah = self.flat_words[-1][0]  # Last ayah

        # Completion safety check
        is_at_end = self.current_position >= len(self.flat_words)

        if is_at_end and self.flat_words:
            correct_count = sum(1 for w in self.word_statuses if w['status'] == 'correct')
            total_processed = len(self.word_statuses)
            total_words = len(self.flat_words)

            correct_ratio = correct_count / max(total_processed, 1)
            processed_ratio = total_processed / max(total_words, 1)

            is_final = (
                correct_ratio >= self.MIN_CORRECT_RATIO_FOR_COMPLETION and
                processed_ratio >= self.MIN_PROCESSED_RATIO_FOR_COMPLETION
            )

            if not is_final:
                logger.warning(
                    f"Session {self.session_id}: Position at end but completion BLOCKED "
                    f"(correct={correct_count}/{total_processed}={correct_ratio:.1%}, "
                    f"processed={total_processed}/{total_words}={processed_ratio:.1%})"
                )
        else:
            is_final = False

        return {
            'type': 'recitation_update',
            'session_id': self.session_id,
            'surah_id': self.surah_id,
            'current_ayah': current_ayah,
            'current_word_index': self.current_position,
            'words': self.word_statuses,
            'total_ayahs_in_surah': self.total_ayahs,
            'total_words': len(self.flat_words),
            'is_final': is_final
        }

    @staticmethod
    def _normalize_arabic(text: str) -> str:
        """
        Normalize Arabic text for comparison.

        Removes:
        - Tashkeel (diacritics)
        - Tatweel (kashida)

        Normalizes:
        - Alef variants (إ أ آ ٱ → ا)
        - Taa marbuta (ة → ه)
        - Yaa/Alef Maksura (ى → ي)
        """
        # Remove tashkeel (diacritics) — comprehensive range
        text = re.sub(r'[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06ED]', '', text)

        # Normalize alef variants (إ أ آ ٱ → ا)
        text = re.sub(r'[إأآٱ]', 'ا', text)

        # Normalize taa marbuta
        text = text.replace('ة', 'ه')

        # Normalize yaa / alef maksura
        text = text.replace('ى', 'ي')

        # Remove tatweel
        text = text.replace('\u0640', '')

        # Remove any remaining non-Arabic characters (spaces preserved)
        text = re.sub(r'[^\u0600-\u06FF\s]', '', text)

        return text.strip()


# Global session manager instance
session_manager = RecitationSessionManager()

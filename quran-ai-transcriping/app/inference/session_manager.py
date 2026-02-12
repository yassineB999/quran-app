"""
Recitation Session Manager

Manages per-connection recitation sessions for real-time word-level feedback.
Sessions are ephemeral and tied to WebSocket connections.
"""

import logging
import time
import uuid
from typing import Dict, Optional, List, Tuple
import quran_ayah_lookup as qal
from rapidfuzz import fuzz

logger = logging.getLogger(__name__)


class RecitationSessionManager:
    """Manages multiple recitation sessions (one per WebSocket connection)."""
    
    def __init__(self):
        self.sessions: Dict[str, 'RecitationSession'] = {}
    
    def create_session(self, surah_id: int) -> 'RecitationSession':
        """Create a new recitation session for a surah."""
        session = RecitationSession(surah_id)
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
    - Audio buffer for sliding window processing
    """
    
    # Fuzzy matching threshold (0-100)
    # Lower threshold because Arabic with diacritics has many Unicode variants
    MATCH_THRESHOLD = 60
    
    # Look ahead N words when searching for skips
    SKIP_LOOKAHEAD = 5
    
    def __init__(self, surah_id: int):
        self.session_id = str(uuid.uuid4())
        self.surah_id = surah_id
        self.created_at = time.time()
        
        # Load reference text
        self.reference_ayahs = self._load_surah_text(surah_id)
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
        
        Args:
            lookahead: How many words ahead of current_position to include.
                       Default 0 to prevent empty transcription bug.
        
        Returns:
            Reference text string for use as Whisper prompt
        """
        if not self.flat_words:
            return ""
        
        # Include text up to current position + lookahead
        end_pos = min(self.current_position + lookahead, len(self.flat_words))
        
        # Special case: at the very start (pos=0, no confirmed words yet),
        # seed with the first 4 words (typically bismillah) so Whisper knows
        # this is Quran recitation from the beginning
        if end_pos == 0:
            seed_end = min(4, len(self.flat_words))
            words = [w[2] for w in self.flat_words[:seed_end]]
            return ' '.join(words)
        
        # Use a sliding window — only the LAST 30 words to stay within
        # Whisper's 448-token decoder limit (~30 Arabic words ≈ 100-150 tokens)
        MAX_PROMPT_WORDS = 30
        start_pos = max(0, end_pos - MAX_PROMPT_WORDS)
        
        # Use display_text (index 2) which has diacritics — better for Whisper
        words = [w[2] for w in self.flat_words[start_pos:end_pos]]
        return ' '.join(words)
    
    def _load_surah_text(self, surah_id: int) -> List[Dict]:
        """
        Load all ayahs for the surah using quran-ayah-lookup.
        
        Returns:
            List of dicts with ayah metadata and word lists
        """
        try:
            results = qal.get_surah_verses(surah_id)
        except AttributeError:
            # Fallback for older versions or if method name is different
            # Try to get verses directly from database if accessible
            # But based on inspection, get_surah_verses should exist
            raise ValueError(f"Could not retrieve verses for Surah {surah_id}")
        
        if not results:
            raise ValueError(f"Surah {surah_id} not found")
        
        ayahs = []
        for verse in results:
            # Split text into words
            words_display = verse.text.split()  # With tashkeel
            words_normalized = verse.text_normalized.split()  # Without tashkeel
            
            ayahs.append({
                'number': verse.ayah_number,
                'text': verse.text,
                'text_normalized': verse.text_normalized,
                'words_display': words_display,
                'words_normalized': words_normalized,
                'is_basmalah': verse.is_basmalah
            })
        
        return ayahs
    
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
            
            # CRITICAL FIX: Re-normalize the expected word using OUR function
            # This ensures both sides are in the exact same normalized space (e.g. ى -> ي)
            expected_norm = self._normalize_arabic(raw_norm_word)
            
            # --- Repetition Handling ---
            # If the user repeats the LAST word (stuttering or correction),
            # we should ignore it instead of comparing it to the NEXT word (which would be a mismatch).
            if hasattr(self, 'last_matched_norm') and self.last_matched_norm:
                repetition_score = fuzz.ratio(spoken_norm, self.last_matched_norm)
                
                # Check if it matches the CURRENT expected word
                # If it matches the expected word, it's NOT a repetition we should ignore
                # (e.g. "Iyyaaka" ... "Wa-iyyaaka" -> similar but distinct valid sequence)
                is_valid_next_word = fuzz.ratio(spoken_norm, expected_norm) >= (50 if len(expected_norm) <= 3 else 70)
                
                # Only ignore if it looks like a repetition AND doesn't look like the next word
                if repetition_score > 92 and not is_valid_next_word:
                    logger.info(
                        f"Session {self.session_id}: Ignoring repetition "
                        f"spoken='{spoken_norm}' matches last='{self.last_matched_norm}' ({repetition_score}%)"
                    )
                    continue # Skip this spoken word, do not advance cursor
            
            score = fuzz.ratio(spoken_norm, expected_norm)
            
            # Adaptive threshold based on word length
            # Short words (<=3 chars) are punished heavily by fuzz.ratio for single char diffs
            word_len = len(expected_norm)
            if word_len <= 3:
                threshold = 50  # Allow more leniency for short words (e.g. 2 chars with 1 diff = 50%)
            else:
                threshold = 70  # Stricter for long words to avoid false positives
            
            # Log alignment attempt for debugging
            logger.info(
                f"Session {self.session_id}: ALIGN pos={self.current_position} "
                f"spoken='{spoken_norm}' vs expected='{expected_norm}' (len={word_len}) → score={score} (thresh={threshold})"
            )
            
            if score >= threshold:
                # Direct match at expected position
                self._record_word_status(
                    ayah_num, word_idx, display_word, 'correct', spoken_word, score
                )
                self.current_position += 1
                self.last_matched_norm = spoken_norm # Track for repetition check
                continue
            
            # Look ahead for skip detection
            best_ahead_score = 0
            best_ahead_offset = -1
            
            for offset in range(1, min(self.SKIP_LOOKAHEAD + 1, len(self.flat_words) - self.current_position)):
                _, _, _, ahead_raw_norm = self.flat_words[self.current_position + offset]
                ahead_norm = self._normalize_arabic(ahead_raw_norm)
                
                ahead_score = fuzz.ratio(spoken_norm, ahead_norm)
                
                # Use same adaptive threshold for lookahead
                ahead_len = len(ahead_norm)
                ahead_thresh = 50 if ahead_len <= 3 else 70
                
                if ahead_score > best_ahead_score and ahead_score >= ahead_thresh:
                    best_ahead_score = ahead_score
                    best_ahead_offset = offset
            
            if best_ahead_offset > 0:
                # Skip detected - mark skipped words as mistakes (Tarteel-style: green/red only)
                for skip_offset in range(best_ahead_offset):
                    skip_ayah, skip_word_idx, skip_display, _ = self.flat_words[self.current_position + skip_offset]
                    self._record_word_status(
                        skip_ayah, skip_word_idx, skip_display, 'mistake', None, 0
                    )
                
                # Move position past skipped words
                self.current_position += best_ahead_offset
                
                # Mark the matched word as correct
                match_ayah, match_word_idx, match_display, _ = self.flat_words[self.current_position]
                self._record_word_status(
                    match_ayah, match_word_idx, match_display, 'correct', spoken_word, best_ahead_score
                )
                self.current_position += 1
                self.last_matched_norm = spoken_norm # Track for repetition check
            else:
                # Mistake - word doesn't match expected or any nearby word
                # DO NOT advance position (hold pointer)
                logger.info(
                    f"Session {self.session_id}: MISTAKE spoken='{spoken_norm}' "
                    f"best_ahead_score={best_ahead_score} - POINTER HELD"
                )
                self._record_word_status(
                    ayah_num, word_idx, display_word, 'mistake', spoken_word, score
                )
                # self.current_position += 1  <-- REMOVED to hold pointer
        
        return self._build_response()
    
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
        """Build response payload for client."""
        # Determine current ayah from position
        current_ayah = 1
        if self.current_position < len(self.flat_words):
            current_ayah = self.flat_words[self.current_position][0]
        elif self.flat_words:
            current_ayah = self.flat_words[-1][0]  # Last ayah
        
        return {
            'type': 'recitation_update',
            'session_id': self.session_id,
            'surah_id': self.surah_id,
            'current_ayah': current_ayah,
            'current_word_index': self.current_position,
            'words': self.word_statuses,
            'total_ayahs_in_surah': self.total_ayahs,
            'total_words': len(self.flat_words),
            'is_final': self.current_position >= len(self.flat_words)
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
        import re
        
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

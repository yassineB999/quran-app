# 🕌 Quran Real-Time Recitation — Implementation Roadmap

## Table of Contents
1. [Current Architecture Analysis](#1-current-architecture-analysis)
2. [Architecture Gap Analysis](#2-architecture-gap-analysis)
3. [Target Architecture](#3-target-architecture)
4. [Phase 1 — MVP: Surah-Aware Near Real-Time Recitation](#4-phase-1--mvp)
5. [Phase 2 — Word-Level Alignment & Mistake Detection](#5-phase-2--word-level-alignment)
6. [Phase 3 — Polish & Long-Term Improvements](#6-phase-3--polish--long-term)
7. [UI/UX Design Specification](#7-uiux-design-specification)
8. [Data Flow Diagrams](#8-data-flow-diagrams)
9. [Trade-offs & Risks](#9-trade-offs--risks)

---

## 1. Current Architecture Analysis

### 1.1 Flutter App (`quranapp/`)

**Quran Reading Page** (`quran_reading_page.dart`) — 603 lines
- Page-based Mushaf view (604 pages) with `PageView.builder`
- Verse selection with long-press → play audio from CDN
- `QuranReaderBloc` handles: page loading, progress save/restore
- `AudioPlayerBloc` handles: play/pause/stop audio from URL playlists
- Verse entity: `{ number, text, translation, numberInSurah, juz, page }`
- **No recitation/recording capability integrated here**

**Mushaf Recitation Page** (`mushaf_recitation_page.dart`) — 364 lines
- Surah-scoped view with `MushafBloc`
- Record audio → stop → submit as WAV file → batch check via API
- Record-then-check flow (one ayah at a time)
- `MushafSession` tracks: `surahId, currentAyahNumberInSurah, completedAyahs, ayahFeedback`
- `AyahWordFeedback` entity exists but only uses `isCorrect` boolean (no word-level data)

**Live Recitation Page** (`live_recitation_page.dart`) — 197 lines
- WebSocket streaming to Python AI service
- PCM 16-bit, 16kHz, mono audio via `record` package
- Receives `partial_result` → displays words in a `Wrap` widget
- **Problems**: No surah context sent, mock error highlighting, only displays raw transcription text, no word alignment

**WebSocket Data Source** (`websocket_data_source.dart`) — 59 lines
- Clean WebSocket wrapper with connect/disconnect/sendAudioChunk
- Returns `Stream<Map<String, dynamic>>` for responses
- **Missing**: Session initialization (surah_id), structured response handling

### 1.2 Laravel API (`quran-api/`)

**Routes** (`api.php`):
- `GET /surahs` — list all surahs
- `GET /surahs/{id}` — surah detail with ayahs
- `GET /surahs/{id}/pages` — page range for surah  
- `GET /pages/{page}` — verses on a page
- `POST /recitation/check` — forwards audio to Python AI, returns correctness

**RecitationController** (`RecitationController.php`) — 143 lines:
- Accepts audio file (multipart or raw binary)
- Forwards to Python AI at `PYTHON_API_URL` (env-configured)
- Returns `{ success: bool, data: { transcription, analysis } }`
- **Role**: Pure proxy/coordinator — no session state, no auth

**Database Models**: `Surah`, `Ayah` with columns including `surah_number`, `ayah_number`, `text`, `text_normalized`, `page`

### 1.3 Python AI Service (`quran-ai-transcriping/`)

**Model**: `tarteel-ai/whisper-base-ar-quran` (Whisper base fine-tuned on Quran recitations)
- Base: `openai/whisper-base` generation config
- Device: CUDA or CPU auto-detect
- Max 30 seconds per chunk

**Batch Pipeline** (10 steps):
1. `AudioResamplingStep` → 16kHz
2. `SilenceDetectionStep` → find pauses
3. `ChunkMergingStep` → group small chunks
4. `ChunkTranscriptionStep` → Whisper transcribe each chunk
5. `DuplicateRemovalStep` → remove repeated content
6. `TranscriptionCombiningStep` → merge all text
7. `VerseMatchingStep` → match to Quran using `quran-ayah-lookup` + `rapidfuzz`
8. `TranscriptionAlignmentStep` → Wav2Vec2 forced alignment (word-level timestamps)
9. `TimestampCalculationStep` → precise timestamps
10. `AudioSplittingStep` → split into verse-level audio files

**WebSocket Endpoint** (`/ws/recite`) — already exists:
- Sliding window: processes every 2s, keeps 6s context buffer
- Uses `transcription_service.transcribe_bytes()` directly
- Merges via `remove_overlap_with_sequencematcher()`
- Returns `{ type: "partial_result", text: session_text }`
- **Missing**: Surah context, word-level alignment, verse tracking, mistake detection

**Existing `/recognize` endpoint** (in `quranai/main.py`):
- Upload audio → transcribe → `match_verses()` with optional surah filter
- Returns `{ transcription, analysis: { surah, ayah, text, score, is_correct } }`

### 1.4 Existing Assets We Can Reuse

| Component | Reusable? | Notes |
|-----------|-----------|-------|
| Whisper model (`tarteel-ai/whisper-base-ar-quran`) | ✅ Yes | Core transcription engine |
| `transcription_service.transcribe_bytes()` | ✅ Yes | Real-time chunk transcription |
| `remove_overlap_with_sequencematcher()` | ✅ Yes | Text deduplication across chunks |
| `VerseMatchingStep` + `quran-ayah-lookup` | ✅ Partially | Need to adapt for incremental matching |
| `TranscriptionAlignmentStep` (Wav2Vec2) | 🔄 Later | Word-level timestamps for Phase 2 |
| WebSocket endpoint (`/ws/recite`) | ✅ Yes | Foundation for streaming |
| `WebSocketDataSource` (Flutter) | ✅ Yes | Client-side WebSocket |
| `MushafSession` entity | ✅ Yes | Session state tracking |
| `AyahWordFeedback` entity | ✅ Yes | Per-word feedback |
| `Verse` entity (text, numberInSurah) | ✅ Yes | Reference text source |
| Laravel Surah/Ayah database | ✅ Yes | Normalized verse text |
| Flutter `record` package | ✅ Yes | Audio capture |
| `QuranReadingPage` book-style UI | ✅ Yes | Base UI to enhance |

---

## 2. Architecture Gap Analysis

### What needs to change

| Current | Target | Gap |
|---------|--------|-----|
| No surah context in WebSocket | Surah ID sent on session start | Protocol change |
| Raw transcription text returned | Word-aligned, verse-mapped response | Server-side alignment |
| No reference text on server | Server loads surah text on session start | Server-side state |
| Generic text display | Word-by-word Quran text with highlighting | New Flutter UI |
| Batch ayah-by-ayah checking | Continuous free-form recitation | Session state machine |
| No mistake detection | Word-level alignment + diff vs reference | New algorithm |
| Separate recitation page | Integrated into reading page | UI merge |

---

## 3. Target Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Flutter App                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │    QuranReadingPage (enhanced)                      │  │
│  │    ┌─────────────┐  ┌───────────────────────────┐   │  │
│  │    │ Surah       │  │ Word-by-Word Display      │   │  │
│  │    │ Selector    │  │ (RTL, Amiri font)         │   │  │
│  │    │             │  │ ┌──────────────────────┐  │   │  │
│  │    │ ───────►    │  │ │ بسم الله الرحمن الرحيم│  │   │  │
│  │    │ Surah #     │  │ │ (green=correct,      │  │   │  │
│  │    │ selected    │  │ │  red=mistake,         │  │   │  │
│  │    │             │  │ │  gray=pending)        │  │   │  │
│  │    └─────────────┘  │ └──────────────────────┘  │   │  │
│  │                     └───────────────────────────┘   │  │
│  │    ┌──────────────────────────┐                     │  │
│  │    │ 🎤 Recitation Controls   │                     │  │
│  │    │ [Start] [Stop] [Reset]   │                     │  │
│  │    └──────────────────────────┘                     │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                │
│        PCM Audio chunks  │  WebSocket                     │
│        (16kHz, mono)     │  (bidirectional)               │
│                          ▼                                │
├──────────────────────────────────────────────────────────┤
│                                                          │
│                 Laravel API (coordinator)                 │
│         ┌────────────────────────────────┐               │
│         │ No direct involvement in WS    │               │
│         │ Provides: GET /surahs/{id}     │               │
│         │ (verse text for pre-loading)   │               │
│         └────────────────────────────────┘               │
│                                                          │
├──────────────────────────────────────────────────────────┤
│                                                          │
│              Python AI Service (FastAPI)                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  WebSocket /ws/recite                                │  │
│  │  ┌────────────┐  ┌──────────────┐  ┌────────────┐   │  │
│  │  │ Session    │  │ Whisper      │  │ Word       │   │  │
│  │  │ Manager    │  │ Transcriber  │  │ Aligner    │   │  │
│  │  │            │  │              │  │            │   │  │
│  │  │ • surah_id │  │ • 2s chunks  │  │ • DTW/fuzz │   │  │
│  │  │ • ayah_idx │  │ • 6s buffer  │  │ • vs ref   │   │  │
│  │  │ • word_idx │  │ • sliding    │  │ • mistakes │   │  │
│  │  │ • ref_text │  │   window     │  │ • position │   │  │
│  │  └────────────┘  └──────────────┘  └────────────┘   │  │
│  └─────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## 4. Phase 1 — MVP: Surah-Aware Near Real-Time Recitation

**Goal**: User selects surah → opens mic → sees Quran words appearing in real-time as they recite → basic correctness indication  
**Timeline**: ~2-3 weeks

### Step 1.1 — Enhanced WebSocket Protocol

**File**: `quran-ai-transcriping/app/api/routes.py`

**Changes to `/ws/recite`**:

1. **Session initialization**: First message from client is JSON with `{ "type": "init", "surah_id": 1 }` 
2. **Server loads reference text**: On init, load all ayahs for the surah using `quran-ayah-lookup`
3. **Session state**: Track `current_ayah_index`, `current_word_index`, `matched_words[]`
4. **Enhanced response format**:

```python
# New response structure
{
    "type": "recitation_update",
    "session_id": "uuid",
    "surah_id": 1,
    "current_ayah": 1,           # 1-indexed ayah number in surah
    "current_word_index": 5,     # 0-indexed word position in current ayah
    "words": [
        {
            "ayah": 1,
            "word_index": 0,
            "expected": "بِسْمِ",      # Reference word (with tashkeel)
            "status": "correct",       # correct | mistake | skipped | pending
            "spoken": "بسم",           # What was actually said (normalized)
        },
        {
            "ayah": 1,
            "word_index": 1,
            "expected": "اللَّهِ",
            "status": "correct",
            "spoken": "الله",
        },
        # ... more words
    ],
    "total_ayahs_in_surah": 7,
    "is_final": false
}
```

**Implementation approach**:

```python
# Pseudo-code for enhanced WebSocket handler
class RecitationSession:
    def __init__(self, surah_id: int):
        self.surah_id = surah_id
        self.reference_ayahs = self._load_surah_text(surah_id)
        self.current_ayah_idx = 0
        self.current_word_idx = 0
        self.confirmed_words = []  # Words that are finalized
        self.all_word_statuses = []  # Full word-by-word status list
    
    def _load_surah_text(self, surah_id):
        """Load all ayahs for surah using quran-ayah-lookup."""
        import quran_ayah_lookup as qal
        surah = qal.get_surah(surah_id)
        ayahs = []
        for ayah in surah:
            words = ayah.text_normalized.split()
            words_with_tashkeel = ayah.text.split()
            ayahs.append({
                'number': ayah.ayah_number,
                'words_normalized': words,
                'words_display': words_with_tashkeel,
                'text_normalized': ayah.text_normalized,
                'text': ayah.text
            })
        return ayahs
    
    def align_transcription(self, new_text: str):
        """
        Align new transcription against reference text.
        Uses greedy sequential matching with fuzzy tolerance.
        """
        spoken_words = new_text.strip().split()
        
        # Build flat reference word list from current position onwards
        ref_words = []
        ref_positions = []
        for ayah_idx in range(len(self.reference_ayahs)):
            ayah = self.reference_ayahs[ayah_idx]
            start_word = 0
            if ayah_idx == 0:
                start_word = 0  # Start from beginning for now
            for word_idx in range(start_word, len(ayah['words_normalized'])):
                ref_words.append(ayah['words_normalized'][word_idx])
                ref_positions.append((ayah_idx, word_idx))
        
        # Sequential alignment using fuzzy matching
        word_statuses = []
        ref_ptr = 0
        
        for spoken_word in spoken_words:
            if ref_ptr >= len(ref_words):
                break
            
            # Try to match spoken word against reference
            best_score = 0
            best_offset = 0
            
            # Look ahead up to 3 words for skips
            for offset in range(min(3, len(ref_words) - ref_ptr)):
                score = fuzz.ratio(spoken_word, ref_words[ref_ptr + offset])
                if score > best_score:
                    best_score = score
                    best_offset = offset
            
            # Mark skipped words
            for skip in range(best_offset):
                ayah_idx, word_idx = ref_positions[ref_ptr]
                word_statuses.append({
                    'ayah': self.reference_ayahs[ayah_idx]['number'],
                    'word_index': word_idx,
                    'expected': self.reference_ayahs[ayah_idx]['words_display'][word_idx],
                    'status': 'skipped',
                    'spoken': None
                })
                ref_ptr += 1
            
            # Match current word
            if ref_ptr < len(ref_words):
                ayah_idx, word_idx = ref_positions[ref_ptr]
                status = 'correct' if best_score >= 75 else 'mistake'
                word_statuses.append({
                    'ayah': self.reference_ayahs[ayah_idx]['number'],
                    'word_index': word_idx,
                    'expected': self.reference_ayahs[ayah_idx]['words_display'][word_idx],
                    'status': status,
                    'spoken': spoken_word
                })
                ref_ptr += 1
        
        # Update session state
        if ref_positions and ref_ptr > 0 and ref_ptr <= len(ref_positions):
            last_matched = ref_positions[min(ref_ptr - 1, len(ref_positions) - 1)]
            self.current_ayah_idx = last_matched[0]
            self.current_word_idx = last_matched[1]
        
        self.all_word_statuses = word_statuses
        return word_statuses
```

### Step 1.2 — WebSocket Session Init from Flutter

**File**: `quranapp/lib/features/audio/data/datasources/websocket_data_source.dart`

**Changes**:
```dart
Future<void> connect({int? surahId}) async {
  _channel = WebSocketChannel.connect(Uri.parse(_url));
  
  // Send session initialization
  if (surahId != null) {
    _channel!.sink.add(jsonEncode({
      'type': 'init',
      'surah_id': surahId,
    }));
  }
  
  _channel!.stream.listen(/* ... existing ... */);
}
```

### Step 1.3 — New RecitationBloc (State Management)

**New file**: `quranapp/lib/features/quran/presentation/bloc/recitation/`

This replaces the ad-hoc state in `LiveRecitationPage`:

```dart
// recitation_state.dart
class RecitationWord {
  final int ayah;
  final int wordIndex;
  final String expected;     // Display text (with tashkeel)
  final String status;       // correct | mistake | skipped | pending
  final String? spoken;
}

class RecitationState extends Equatable {
  final RecitationStatus status;     // idle | connecting | reciting | paused | error
  final int surahId;
  final String surahName;
  final int currentAyah;
  final int currentWordIndex;
  final List<RecitationWord> words;  // All words with their status
  final int totalAyahs;
  final String? errorMessage;
}
```

### Step 1.4 — Integrate Recitation into QuranReadingPage

**File**: `quranapp/lib/features/quran/presentation/pages/quran_reading_page.dart`

**Key changes**:
- Add a floating action button (🎤) to enter recitation mode
- When entering recitation mode:
  - Determine which surah the user is on (from the current page's verses)
  - Switch the page content from standard `RichText` to word-by-word recitation view
  - Show the recitation control bar at the bottom
- The word-by-word view displays ALL words of the selected surah with color coding:
  - **Default (gray/dimmed)**: Words not yet recited (pending)
  - **Green/teal**: Correctly recited words
  - **Red with underline**: Mistakes or incorrect words  
  - **Orange with strikethrough**: Skipped words
  - **White/active**: Currently being spoken (with subtle pulse animation)

### Step 1.5 — Laravel Changes (Minimal)

**New optional endpoint** `GET /surahs/{id}/words`:
```php
// Returns word-level data for a surah
public function words($id) {
    $ayahs = Ayah::where('surah_number', (int)$id)
        ->orderBy('number_in_surah')
        ->get(['number_in_surah', 'text', 'text_normalized']);
    
    $words = [];
    foreach ($ayahs as $ayah) {
        $ayahWords = explode(' ', $ayah->text);
        $normalizedWords = explode(' ', $ayah->text_normalized ?? $ayah->text);
        foreach ($ayahWords as $idx => $word) {
            $words[] = [
                'ayah' => $ayah->number_in_surah,
                'index' => $idx,
                'text' => $word,
                'normalized' => $normalizedWords[$idx] ?? $word,
            ];
        }
    }
    
    return response()->json(['data' => $words]);
}
```

This is used by Flutter to pre-load all words for the surah before starting recitation (so the UI can show them immediately as "pending").

---

## 5. Phase 2 — Word-Level Alignment & Mistake Detection

**Goal**: Accurate word-level alignment using existing pipeline components, prevent drift and skipped words  
**Timeline**: ~2-3 weeks after Phase 1

### Step 2.1 — Enhanced Alignment Algorithm (Python)

**Key insight**: The existing `TranscriptionAlignmentStep` uses Wav2Vec2 for **forced alignment** — this gives word-level timestamps. We can adapt this for real-time:

**New module**: `quran-ai-transcriping/app/inference/realtime_aligner.py`

```python
class RealtimeAligner:
    """
    Aligns spoken words to reference Quran text incrementally.
    
    Strategy:
    1. Maintain a "confirmed" prefix (words we're confident about)
    2. Only re-align the "active window" (last ~10 words)
    3. Use rapidfuzz for fuzzy matching with Arabic text normalization
    4. Handle common recitation patterns:
       - Pauses (silence detection → don't move pointer)
       - Repetitions (same word spoken again → keep position)
       - Corrections (wrong word → right word → mark first as mistake)
       - Skips (jump ahead → mark missed words as skipped)
    """
    
    MATCH_THRESHOLD = 70       # Minimum fuzzy match score
    SKIP_LOOKAHEAD = 5         # Look ahead N words for skip detection
    CONFIRMED_WINDOW = 3       # Confirm words after N subsequent matches
    
    def __init__(self, reference_words: list):
        self.reference_words = reference_words
        self.confirmed_up_to = 0        # Index of last confirmed word
        self.word_statuses = {}          # {ref_idx: {status, spoken}}
        self.pending_matches = []        # Recent unconfirmed matches
    
    def process_new_words(self, spoken_words: list) -> dict:
        """
        Process newly transcribed words against reference.
        Returns updated word statuses.
        """
        ref_ptr = self.confirmed_up_to
        
        for spoken in spoken_words:
            if ref_ptr >= len(self.reference_words):
                break
            
            # Normalize Arabic text for comparison
            spoken_norm = self._normalize_arabic(spoken)
            
            # Try exact position first
            ref_norm = self._normalize_arabic(self.reference_words[ref_ptr])
            score = fuzz.ratio(spoken_norm, ref_norm)
            
            if score >= self.MATCH_THRESHOLD:
                # Direct match at expected position
                self._record_match(ref_ptr, spoken, score)
                ref_ptr += 1
                continue
            
            # Look ahead for skip detection
            best_ahead_score = 0
            best_ahead_idx = -1
            for ahead in range(1, min(self.SKIP_LOOKAHEAD + 1, 
                                      len(self.reference_words) - ref_ptr)):
                ahead_ref = self._normalize_arabic(
                    self.reference_words[ref_ptr + ahead])
                ahead_score = fuzz.ratio(spoken_norm, ahead_ref)
                if ahead_score > best_ahead_score:
                    best_ahead_score = ahead_score
                    best_ahead_idx = ahead
            
            if best_ahead_score >= self.MATCH_THRESHOLD:
                # Skip detected — mark intermediate words
                for skip in range(best_ahead_idx):
                    self._record_skip(ref_ptr + skip)
                ref_ptr += best_ahead_idx
                self._record_match(ref_ptr, spoken, best_ahead_score)
                ref_ptr += 1
            else:
                # Mistake — word doesn't match any nearby reference
                self._record_mistake(ref_ptr, spoken, score)
                ref_ptr += 1
        
        # Confirm words that have enough subsequent matches
        self._confirm_pending()
        
        return self._build_status_update()
    
    def _normalize_arabic(self, text: str) -> str:
        """Remove diacritics and normalize Arabic text."""
        import re
        # Remove tashkeel (diacritics)
        text = re.sub(r'[\u064B-\u0652\u0670]', '', text)
        # Normalize alef variants
        text = re.sub(r'[إأآ]', 'ا', text)
        # Normalize taa marbuta
        text = text.replace('ة', 'ه')
        # Remove tatweel
        text = text.replace('\u0640', '')
        return text.strip()
```

### Step 2.2 — Preventing Drift and Skipped Words

**Problem**: As audio chunks are processed, the sliding window approach can cause:
1. **Hallucinated words**: Whisper generates text not spoken
2. **Duplicate words**: Overlap between chunks produces repetitions
3. **Drift**: Position tracker gets out of sync

**Solutions**:

1. **Anchor-based alignment**: After every chunk, verify the position by matching a window of N words around the cursor against both the transcription AND the reference text. If they diverge, snap back to the last confirmed position.

2. **Reference-guided decoding** (advanced): Use Whisper's `initial_prompt` parameter with the expected text to bias the model:
```python
# In transcribe_bytes, add initial_prompt
expected_context = ' '.join(ref_words[current_pos:current_pos+20])
result = self._transcribe_single_chunk(
    audio_array, 
    initial_prompt=expected_context  # Biases Whisper toward expected words
)
```

3. **Overlap deduplication**: Already exists in `remove_overlap_with_sequencematcher()`. Enhance it to also check against reference text.

4. **Monotonic constraint**: The reciter moves forward through the surah. Never allow the word pointer to move backward more than 2 positions (allows for corrections but prevents drift).

### Step 2.3 — Session State on Python Server

**New file**: `quran-ai-transcriping/app/inference/session_manager.py`

```python
class RecitationSessionManager:
    """Manages per-connection recitation sessions."""
    
    sessions: Dict[str, RecitationSession] = {}
    
    def create_session(self, session_id: str, surah_id: int) -> RecitationSession:
        session = RecitationSession(surah_id)
        self.sessions[session_id] = session
        return session
    
    def get_session(self, session_id: str) -> Optional[RecitationSession]:
        return self.sessions.get(session_id)
    
    def destroy_session(self, session_id: str):
        self.sessions.pop(session_id, None)


class RecitationSession:
    def __init__(self, surah_id: int):
        self.session_id = str(uuid.uuid4())
        self.surah_id = surah_id
        self.aligner = RealtimeAligner(self._load_reference(surah_id))
        self.audio_buffer = bytearray()
        self.session_text = ""
        self.created_at = time.time()
    
    def _load_reference(self, surah_id: int) -> list:
        """Load flat word list for surah."""
        import quran_ayah_lookup as qal
        surah = qal.get_surah(surah_id)
        words = []
        for ayah in surah:
            for word in ayah.text.split():
                words.append(word)
        return words
```

### Step 2.4 — No Authentication, Session by Connection

Since there's no auth system, sessions are tied to WebSocket connections:
- Each WebSocket connection = one recitation session
- Session is created on `init` message, destroyed on disconnect
- No persistence needed (session is ephemeral)
- If the user disconnects and reconnects, they start fresh
- **Future**: Add device ID or anonymous UUID for basic session continuity

---

## 6. Phase 3 — Polish & Long-Term Improvements

**Timeline**: Ongoing after Phase 2

### 6.1 — True Streaming (Lower Latency)

Current: 2-second chunks → ~1-2s processing → ~3-4s latency  
Target: 500ms chunks → ~500ms processing → ~1s latency

**Approach**: Use Whisper's `WhisperForConditionalGeneration` with streaming-capable alternatives:
- **Option A**: CTranslate2 Whisper (faster-whisper) — 3-4x speedup
- **Option B**: Whisper.cpp — native C++ inference
- **Option C**: Silero VAD for voice activity detection + only send voiced segments

### 6.2 — Forced Alignment Integration

Reuse the existing `TranscriptionAlignmentStep._align_with_wav2vec2()` method:
- Run forced alignment on each chunk's audio against the matched reference text
- Get precise word-level timestamps
- Use timestamps to sync highlighting with audio playback

### 6.3 — Advanced Mistake Categories

```python
class MistakeType(Enum):
    CORRECT = "correct"
    TAJWEED_ERROR = "tajweed"        # Pronunciation issue
    WORD_SUBSTITUTION = "substitution" # Wrong word entirely
    WORD_ADDITION = "addition"       # Added extra word  
    WORD_OMISSION = "omission"       # Skipped a word
    WORD_REPETITION = "repetition"   # Repeated a word
    ORDER_ERROR = "order"            # Words in wrong order
```

### 6.4 — Offline Mode

- Cache Whisper model on device (if feasible) for offline use
- Or: Record audio offline, sync and process when online
- Store session state locally with Hive/SharedPreferences

### 6.5 — Performance Optimization

- **GPU inference**: Ensure CUDA is used in production
- **Model quantization**: Use INT8 quantized model for 2x speedup
- **Connection pooling**: Handle multiple simultaneous users
- **Audio compression**: Send Opus instead of raw PCM to reduce bandwidth

---

## 7. UI/UX Design Specification

### 7.1 — Recitation Mode in QuranReadingPage

The `quran_reading_page.dart` needs to support a **recitation overlay mode** that activates when the user taps the mic button.

**Layout (Recitation Active)**:

```
┌──────────────────────────────────────────┐
│  ← Back      الفاتحة      Ayah 1/7 📊   │  ← App Bar with surah name + progress
├──────────────────────────────────────────┤
│                                          │
│  ┌──────────────────────────────────────┐│
│  │         بِسْمِ اللَّهِ الرَّحْمَنِ      ││  ← Reference text (all words shown)
│  │              الرَّحِيمِ               ││
│  │                                      ││
│  │      الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ  ││  ← Words color-coded by status
│  │                                      ││
│  │      الرَّحْمَنِ الرَّحِيمِ             ││
│  │                                      ││
│  │     مَالِكِ يَوْمِ الدِّينِ             ││
│  │                                      ││
│  │  ... (remaining ayahs dimmed) ...    ││
│  └──────────────────────────────────────┘│
│                                          │
│  ┌──────────────────────────────────────┐│
│  │ ● Live  |  Ayah 2 of 7  |  85% ✓   ││  ← Status bar
│  └──────────────────────────────────────┘│
│                                          │
│  ┌──────────────────────────────────────┐│
│  │                                      ││
│  │         🔴  Stop Recording           ││  ← Control bar
│  │     ○ ○ ○ ○ ○ (waveform viz)        ││
│  │                                      ││
│  └──────────────────────────────────────┘│
└──────────────────────────────────────────┘
```

### 7.2 — Word Status Colors

```dart
Color _getWordColor(String status, bool isDark) {
  switch (status) {
    case 'correct':
      return isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);  // Green
    case 'mistake':
      return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);  // Red
    case 'skipped':
      return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);  // Amber
    case 'active':
      return AppTheme.primaryTeal;  // Teal with pulse animation
    case 'pending':
    default:
      return isDark 
          ? Colors.white.withOpacity(0.3) 
          : Colors.black.withOpacity(0.25);  // Dimmed
  }
}
```

### 7.3 — Mistake Persistence

When a mistake is detected:
1. The incorrect word remains highlighted in **red** for at least 3 seconds
2. A subtle tooltip/badge shows what was spoken vs. what was expected
3. The red persists even as the user continues (no overwriting)
4. After the session, a summary view shows all mistakes

### 7.4 — Smooth Animations

```dart
// Word appearance animation
AnimatedDefaultTextStyle(
    duration: const Duration(milliseconds: 300),
    style: TextStyle(
        color: _getWordColor(word.status, isDark),
        fontSize: 24,
        fontFamily: 'Amiri',
        fontWeight: word.status == 'active' 
            ? FontWeight.bold 
            : FontWeight.normal,
    ),
    child: Text(word.expected),
)

// Pulse animation for active word
class _PulseAnimation extends StatefulWidget { ... }
// Uses AnimationController with repeat() for subtle scale pulsing
```

### 7.5 — Auto-scroll

As the user recites past the visible area, the view auto-scrolls smoothly:
```dart
// When current word is near bottom of visible area
if (currentWordGlobalPosition.dy > viewportHeight * 0.7) {
    _scrollController.animateTo(
        _scrollController.offset + lineHeight,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
    );
}
```

---

## 8. Data Flow Diagrams

### 8.1 — Session Lifecycle

```
User taps "Start Recitation" on Surah Al-Fatiha
    │
    ├── 1. Flutter loads all words for Surah 1 from Laravel API
    │       GET /surahs/1 → verse texts
    │       (Words displayed as "pending" immediately)
    │
    ├── 2. Flutter opens WebSocket to Python AI
    │       ws://host:8000/ws/recite
    │
    ├── 3. Flutter sends init message
    │       { "type": "init", "surah_id": 1 }
    │
    ├── 4. Python creates RecitationSession
    │       Loads reference words for Surah 1
    │       Returns { "type": "session_ready", "total_words": 29 }
    │
    ├── 5. User starts speaking → mic captures PCM audio
    │
    ├── 6. Audio chunks sent every ~100ms to WebSocket
    │       (raw PCM bytes)
    │
    ├── 7. Python buffers until 2 seconds accumulated
    │
    ├── 8. Python transcribes buffer (Whisper)
    │       "بسم الله الرحمن الرحيم"
    │
    ├── 9. Python aligns transcription to reference
    │       word 0: بسم → بِسْمِ (score 92 → correct)
    │       word 1: الله → اللَّهِ (score 95 → correct)
    │       word 2: الرحمن → الرَّحْمَنِ (score 90 → correct)
    │       word 3: الرحيم → الرَّحِيمِ (score 88 → correct)
    │
    ├── 10. Python sends update to Flutter
    │       { "type": "recitation_update", "words": [...], "current_ayah": 1 }
    │
    ├── 11. Flutter updates word colors in UI
    │       All 4 words turn green
    │       Remaining words stay pending/dimmed
    │
    └── 12. Repeat 6-11 as user continues...
```

### 8.2 — Mistake Handling Flow

```
User says "الحمد لربي العالمين" (mistake: لربي instead of لله + skip: رب)
    │
    ├── Transcription: "الحمد لربي العالمين"
    │
    ├── Alignment against reference "الحمد لله رب العالمين":
    │   word 0: الحمد → الحمد (correct ✓)
    │   word 1: لربي → لله (score 40 → no match at position)
    │           → look ahead: رب (score 55), العالمين (score 30)
    │           → still no good match → mark لله as MISTAKE (spoken: لربي)
    │   word 2: (already consumed by #1's lookahead)
    │   word 3: العالمين → العالمين (correct ✓)
    │   Remaining: رب was SKIPPED
    │
    ├── Response:
    │   { words: [
    │       {expected: "الحمد", status: "correct"},
    │       {expected: "لله", status: "mistake", spoken: "لربي"},
    │       {expected: "رب", status: "skipped"},
    │       {expected: "العالمين", status: "correct"}
    │   ]}
    │
    └── UI: الحمد(green) لله(red) رب(orange) العالمين(green)
                          ↑ shows tooltip: "you said: لربي"
```

---

## 9. Trade-offs & Risks

### 9.1 — Latency vs. Accuracy

| Chunk Size | Latency | Accuracy | Recommendation |
|-----------|---------|----------|----------------|
| 1 second | ~1-2s | Lower (hallucinations) | Too aggressive |
| **2 seconds** | **~2-3s** | **Good** | **MVP default** |
| 3 seconds | ~3-4s | Best | Fallback for slow devices |
| 5+ seconds | ~5s+ | Best but slow | Not recommended |

**Decision**: Start with 2-second chunks. The 6-second sliding window context helps accuracy.

### 9.2 — Server-side vs. Client-side Alignment

| Approach | Pros | Cons |
|----------|------|------|
| **Server-side** (chosen) | Single source of truth, consistent | Needs WebSocket, depends on network |
| Client-side | No latency, works offline | Needs model on device, inconsistent |

**Decision**: Server-side for MVP. Client-side as Phase 3 offline enhancement.

### 9.3 — Whisper Limitations

- **30-second limit**: Handled by chunking (already solved)
- **Arabic diacritics**: Whisper outputs without tashkeel → must normalize both sides for comparison
- **Background noise**: May degrade accuracy → add VAD (voice activity detection) as enhancement
- **Hallucinations**: Short silence periods may produce phantom text → filter using reference text anchoring

### 9.4 — No Authentication

- Sessions tied to WebSocket connections (ephemeral)
- No persistence between sessions
- **Risk**: Can't track user progress across app restarts
- **Mitigation**: Store last session state in SharedPreferences locally (Flutter)
- **Future**: Add anonymous device-based sessions via Laravel

---

## Implementation Checklist

### Phase 1 — MVP (~2-3 weeks)

#### Python AI Service
- [ ] Create `RecitationSession` class with surah loading and state tracking
- [ ] Create `RecitationSessionManager` singleton
- [ ] Create `RealtimeAligner` with sequential fuzzy matching
- [ ] Modify `/ws/recite` to accept `init` message with `surah_id`
- [ ] Modify `/ws/recite` to use session-based alignment
- [ ] Modify response format to include word-level statuses
- [ ] Add Arabic text normalization utility (remove tashkeel)
- [ ] Add initial_prompt parameter to Whisper for reference-guided decoding

#### Laravel API
- [ ] Add `GET /surahs/{id}/words` endpoint for word-level data
- [ ] Ensure `Ayah` model has `text_normalized` column (or compute it)

#### Flutter App
- [ ] Create `RecitationWord` entity
- [ ] Create `RecitationState` and `RecitationEvent` classes
- [ ] Create `RecitationBloc` with WebSocket integration
- [ ] Modify `WebSocketDataSource` to support `init` message with `surahId`
- [ ] Add recitation mode toggle to `QuranReadingPage`
- [ ] Build word-by-word display widget with color coding
- [ ] Add recitation control bar (start/stop/reset)
- [ ] Implement auto-scroll during recitation
- [ ] Add surah selection dialog before starting recitation
- [ ] Register new bloc and dependencies in DI container

### Phase 2 — Word-Level Alignment (~2-3 weeks)
- [ ] Implement `RealtimeAligner` with skip/mistake/repetition detection
- [ ] Add monotonic constraint to prevent backward drift
- [ ] Add confirmed word window for stability
- [ ] Implement mistake persistence (red stays for 3+ seconds)
- [ ] Add post-session summary view
- [ ] Implement reference-guided Whisper decoding (`initial_prompt`)
- [ ] Add word-level tooltip showing "spoken vs. expected"
- [ ] Tune fuzzy matching thresholds with real recitation data

### Phase 3 — Polish (Ongoing)
- [ ] Faster inference (faster-whisper / CTranslate2)
- [ ] Voice Activity Detection (Silero VAD)
- [ ] Offline mode with local session storage
- [ ] Advanced mistake categories (tajweed, repetition, etc.)
- [ ] Waveform visualization during recording
- [ ] Haptic feedback on mistakes
- [ ] Session history and progress tracking
- [ ] Multi-user support with anonymous device IDs

---

## File Changes Summary

### New Files
| File | Description |
|------|-------------|
| `quran-ai-transcriping/app/inference/realtime_aligner.py` | Word-level alignment engine |
| `quran-ai-transcriping/app/inference/session_manager.py` | Per-connection session management |
| `quranapp/lib/features/quran/presentation/bloc/recitation/recitation_bloc.dart` | Recitation state management |
| `quranapp/lib/features/quran/presentation/bloc/recitation/recitation_state.dart` | State classes |
| `quranapp/lib/features/quran/presentation/bloc/recitation/recitation_event.dart` | Event classes |
| `quranapp/lib/features/quran/presentation/widgets/recitation_word_display.dart` | Word-by-word UI widget |
| `quranapp/lib/features/quran/presentation/widgets/recitation_control_bar.dart` | Mic/recording controls |

### Modified Files
| File | Changes |
|------|---------|
| `quran-ai-transcriping/app/api/routes.py` | Enhanced `/ws/recite` with session support |
| `quranapp/lib/features/audio/data/datasources/websocket_data_source.dart` | Add `surahId` to connect |
| `quranapp/lib/features/quran/presentation/pages/quran_reading_page.dart` | Add recitation mode overlay |
| `quranapp/lib/core/di/injection_container.dart` | Register RecitationBloc |
| `quran-api/routes/api.php` | Add `/surahs/{id}/words` route |
| `quran-api/app/Http/Controllers/Api/SurahController.php` | Add `words()` method |

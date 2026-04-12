#!/usr/bin/env python3
"""
Tests for recitation alignment logic.

Validates:
- Correct words advance the pointer
- Wrong words hold the pointer
- False completion is blocked
- Repetition handling works
- Overlap deduplication works
- Skip detection works correctly
- Arabic normalization is consistent

Run from the quran-ai-transcriping directory:
    python -m pytest tests/test_alignment.py -v
    # or directly:
    python tests/test_alignment.py
"""

import sys
import os

# Add parent dir to path so we can import app modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.inference.session_manager import RecitationSession


def make_session(words_by_ayah):
    """Helper to create a session with specific test words (no external deps)."""
    client_words = []
    for ayah_num, words in words_by_ayah.items():
        for idx, word in enumerate(words):
            client_words.append({
                'ayah': ayah_num,
                'word_index': idx,
                'text': word,
            })
    return RecitationSession(surah_id=999, client_words=client_words)


# --- Alignment Tests ---

def test_perfect_recitation():
    """Perfect recitation should mark all words as correct."""
    session = make_session({
        1: ['بِسْمِ', 'ٱللَّهِ', 'ٱلرَّحْمَٰنِ', 'ٱلرَّحِيمِ'],
    })
    result = session.align_transcription('بسم الله الرحمن الرحيم')

    correct = sum(1 for w in result['words'] if w['status'] == 'correct')
    assert correct == 4, f"Expected 4 correct, got {correct}. Statuses: {result['words']}"
    assert result['current_word_index'] == 4


def test_wrong_words_hold_pointer():
    """Wrong words should not advance the pointer."""
    session = make_session({
        1: ['بِسْمِ', 'ٱللَّهِ', 'ٱلرَّحْمَٰنِ', 'ٱلرَّحِيمِ'],
    })
    result = session.align_transcription('كلام خاطئ تماما لا يشبه القرآن')

    assert result['current_word_index'] <= 1, \
        f"Pointer advanced too far on wrong words: pos={result['current_word_index']}"


def test_false_completion_blocked():
    """Wrong text should NOT trigger surah completion."""
    session = make_session({
        1: ['بِسْمِ', 'ٱللَّهِ'],
        2: ['ٱلْحَمْدُ', 'لِلَّهِ'],
    })

    # Feed many wrong words — should not trigger is_final
    wrong_text = ' '.join(['خطأ'] * 30)
    result = session.align_transcription(wrong_text)

    assert not result['is_final'], \
        "Surah should not be marked complete with wrong text"


def test_repetition_handling():
    """Repeated last-word should be ignored, not cause false mismatches."""
    session = make_session({
        1: ['بِسْمِ', 'ٱللَّهِ', 'ٱلرَّحْمَٰنِ'],
    })

    # User says "بسم" then stutters "بسم" again, then continues
    result = session.align_transcription('بسم بسم الله الرحمن')

    correct = sum(1 for w in result['words'] if w['status'] == 'correct')
    assert correct == 3, f"Expected 3 correct (with repetition skipped), got {correct}"


def test_skip_detection():
    """Skipping a word should mark it as mistake and continue."""
    session = make_session({
        1: ['بِسْمِ', 'ٱللَّهِ', 'ٱلرَّحْمَٰنِ', 'ٱلرَّحِيمِ'],
    })

    # Skip "الله" — go straight to "الرحمن"
    result = session.align_transcription('بسم الرحمن الرحيم')

    # Build status lookup by word_index
    statuses = {}
    for w in result['words']:
        key = w['word_index']
        statuses[key] = w['status']

    assert statuses.get(0) == 'correct', f"Word 0 should be correct: {statuses}"
    assert statuses.get(1) == 'mistake', f"Word 1 (skipped) should be mistake: {statuses}"
    assert statuses.get(2) == 'correct', f"Word 2 should be correct: {statuses}"


def test_completion_requires_minimum_accuracy():
    """Completion must meet minimum correct/processed ratios."""
    session = make_session({
        1: ['بِسْمِ', 'ٱللَّهِ'],
    })

    # Manually force position to end but with no correct words
    session.current_position = len(session.flat_words)
    session.word_statuses = [
        {'ayah': 1, 'word_index': 0, 'expected': 'بِسْمِ', 'status': 'mistake', 'spoken': 'خطأ', 'score': 10},
        {'ayah': 1, 'word_index': 1, 'expected': 'ٱللَّهِ', 'status': 'mistake', 'spoken': 'خطأ', 'score': 10},
    ]

    response = session._build_response()
    assert not response['is_final'], \
        "Completion should be blocked when all words are mistakes"


# --- Overlap Dedup Tests ---

def test_deduplicate_overlap_basic():
    """Should remove overlapping words at chunk boundary."""
    session = make_session({1: ['test']})

    merged = session.deduplicate_overlap(
        'بسم الله الرحمن الرحيم',
        'الرحمن الرحيم الحمد لله'
    )

    words = merged.split()
    assert words.count('الرحمن') == 1, f"Duplicate 'الرحمن' found: {merged}"
    assert words.count('الرحيم') == 1, f"Duplicate 'الرحيم' found: {merged}"
    assert 'الحمد' in words, f"Missing 'الحمد': {merged}"


def test_deduplicate_no_overlap():
    """No overlap should result in simple concatenation."""
    session = make_session({1: ['test']})

    merged = session.deduplicate_overlap(
        'بسم الله',
        'مالك يوم الدين'
    )

    expected = 'بسم الله مالك يوم الدين'
    assert merged == expected, f"Unexpected merge result"


def test_deduplicate_empty_inputs():
    """Empty inputs should be handled gracefully."""
    session = make_session({1: ['test']})

    assert session.deduplicate_overlap('', 'الحمد لله') == 'الحمد لله'
    assert session.deduplicate_overlap('بسم الله', '') == 'بسم الله'
    assert session.deduplicate_overlap('', '') == ''


# --- Normalization Tests ---

def test_normalize_arabic():
    """Arabic normalization should handle diacritics, alef variants, etc."""
    norm = RecitationSession._normalize_arabic

    # Diacritics removal
    assert norm('بِسْمِ') == norm('بسم'), f"Diacritics: '{norm('بِسْمِ')}' vs '{norm('بسم')}'"

    # Alef normalization
    assert norm('إله') == norm('اله')
    assert norm('أحد') == norm('احد')
    assert norm('آمنوا') == norm('امنوا')

    # Taa marbuta
    assert norm('رحمة') == norm('رحمه')

    # Yaa normalization
    assert norm('هدى') == norm('هدي')

    # Alef with hamza above
    assert norm('ٱلرَّحْمَٰنِ') == norm('الرحمن')


def test_client_words_loading():
    """Client-provided words should be loaded correctly."""
    words = [
        {'ayah': 1, 'word_index': 0, 'text': 'بِسْمِ'},
        {'ayah': 1, 'word_index': 1, 'text': 'ٱللَّهِ'},
        {'ayah': 2, 'word_index': 0, 'text': 'ٱلْحَمْدُ'},
    ]

    session = RecitationSession(surah_id=999, client_words=words)

    assert len(session.flat_words) == 3
    assert session.flat_words[0][2] == 'بِسْمِ'  # display text preserved
    assert session.flat_words[1][2] == 'ٱللَّهِ'
    assert session.flat_words[2][0] == 2  # ayah number
    assert session.total_ayahs == 2


# --- Edge Cases ---

def test_incremental_alignment():
    """Alignment should handle incremental text (new words only)."""
    session = make_session({
        1: ['بِسْمِ', 'ٱللَّهِ', 'ٱلرَّحْمَٰنِ', 'ٱلرَّحِيمِ'],
    })

    # First chunk
    r1 = session.align_transcription('بسم الله')
    assert r1['current_word_index'] == 2

    # Second chunk (accumulated text includes first chunk)
    r2 = session.align_transcription('بسم الله الرحمن الرحيم')
    assert r2['current_word_index'] == 4

    correct = sum(1 for w in r2['words'] if w['status'] == 'correct')
    assert correct == 4


def test_consecutive_misses_tracked():
    """Consecutive misses should be tracked for debugging."""
    session = make_session({
        1: ['بِسْمِ', 'ٱللَّهِ'],
    })

    session.align_transcription('خطأ خطأ خطأ')

    assert session._consecutive_misses > 0, \
        "Consecutive misses should be tracked"


# --- Runner ---

if __name__ == '__main__':
    tests = [
        ("Perfect recitation", test_perfect_recitation),
        ("Wrong words hold pointer", test_wrong_words_hold_pointer),
        ("False completion blocked", test_false_completion_blocked),
        ("Repetition handling", test_repetition_handling),
        ("Skip detection", test_skip_detection),
        ("Completion requires min accuracy", test_completion_requires_minimum_accuracy),
        ("Overlap dedup basic", test_deduplicate_overlap_basic),
        ("Overlap dedup no overlap", test_deduplicate_no_overlap),
        ("Overlap dedup empty inputs", test_deduplicate_empty_inputs),
        ("Arabic normalization", test_normalize_arabic),
        ("Client words loading", test_client_words_loading),
        ("Incremental alignment", test_incremental_alignment),
        ("Consecutive misses tracked", test_consecutive_misses_tracked),
    ]

    passed = 0
    failed = 0

    for name, test_fn in tests:
        try:
            test_fn()
            print(f"  PASS  {name}")
            passed += 1
        except AssertionError as e:
            print(f"  FAIL  {name}: {e}")
            failed += 1
        except Exception as e:
            # Use ascii-safe repr to avoid Windows encoding issues
            print(f"  ERROR {name}: {type(e).__name__}: {repr(e)}")
            failed += 1

    print(f"\n{passed}/{passed + failed} tests passed")
    if failed > 0:
        sys.exit(1)

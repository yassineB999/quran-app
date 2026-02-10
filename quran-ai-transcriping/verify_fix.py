import logging
import sys
import os

# Ensure project root is in path
sys.path.append(os.getcwd())

# Simulate main.py behavior
if sys.platform == "win32":
    # Reconfigure stdout/stderr to utf-8
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

# Configure logging
logging.basicConfig(level=logging.INFO, stream=sys.stdout)

try:
    from app.inference.transcription import transcription_service
except ImportError:
    # If standard import fails, try modifying path
    sys.path.append(os.path.join(os.getcwd(), 'app'))
    from app.inference.transcription import transcription_service

print("Testing removal of overlap with Arabic text...")

# Test with Arabic text that triggered the issue
text1 = "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ START_HAL"
# Overlap: "الرَّحْمَنِ الرَّحِيمِ"
text2 = "END_HAL الرَّحْمَنِ الرَّحِيمِ مَالِكِ يَوْمِ الدِّينِ"

# This might not trigger deep sequence match if the text is short/different than logic expects
# The logic requires match length > 20 chars.
# "الرَّحْمَنِ الرَّحِيمِ" is about 22 chars.

# Let's use the exact text from the log if possible or close to it
# Log said: "Found matching sequence (~3 words, 23 chars): 'بِسْمِ اللَّهِ الرَّحْم'..."
# So text1 had "بِسْمِ اللَّهِ الرَّحْم" and text2 had it too.

text1 = "PRE A B C بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ HALLUCINATION" 
text2 = "HALLUCINATION بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ POST X Y Z"

# Force a match
result = transcription_service.remove_overlap_with_sequencematcher(text1, text2)

print("\nResult:", result)
print("\nIf you see this and no UnicodeEncodeError, the fix works!")

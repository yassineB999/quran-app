import io
import torch
import librosa
import numpy as np
import pyquran as q
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from typing import Optional
from contextlib import asynccontextmanager
from transformers import Wav2Vec2ForCTC, Wav2Vec2Processor
from lang_trans.arabic import buckwalter
from nltk import edit_distance

# --- Global Variables to hold the model in memory ---
ml_models = {}
quran_data = {}

# --- Setup Logic (Runs once on startup) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Loading models... this may take a minute.")
    
    # 1. Load Model
    # Using the Fine-Tuned model as per your preference
    # Load model from the current directory (where main.py is located)
    import os
    model_dir = os.path.dirname(os.path.abspath(__file__))
    ml_models["model"] = Wav2Vec2ForCTC.from_pretrained(model_dir).eval()
    
    # Load processor from the Hub since local files (vocab.json, etc.) are missing
    # Base model used: elgeish/wav2vec2-large-xlsr-53-arabic
    ml_models["processor"] = Wav2Vec2Processor.from_pretrained("elgeish/wav2vec2-large-xlsr-53-arabic")
    
    # 2. Prepare Quran Reference Text (All 114 Surahs)
    print("Preparing Quran text (indexing all ayahs)...")
    quran_data["ayahs"] = []
    
    # Load all 114 Surahs
    for surah_num in range(1, 115):
        # get_sura returns a list of strings, each string is an ayah
        # We assume basmalah=False to avoid "Bismillah" repeating (except Surah 1 where it's part of it usually)
        # But pyquran behavior: for Surah 1, basmalah is verse 1 if basmalah=True?
        # Let's use standard text.
        ayahs = q.quran.get_sura(surah_num, with_tashkeel=True, basmalah=False)
        
        for i, text in enumerate(ayahs):
            ayah_num = i + 1
            quran_data["ayahs"].append({
                "surah": surah_num,
                "ayah": ayah_num,
                "text": text
            })
            
    print(f"Indexed {len(quran_data['ayahs'])} ayahs.")
    
    print("System ready!")
    yield
    # Clean up resources if needed
    ml_models.clear()
    quran_data.clear()

app = FastAPI(lifespan=lifespan)

# --- Helper Functions ---

def predict_text(audio_array):
    processor = ml_models["processor"]
    model = ml_models["model"]
    
    # Normalize inputs
    inputs = processor(audio_array, sampling_rate=16000, return_tensors="pt", padding=True)
    
    with torch.no_grad():
        predicted = torch.argmax(model(inputs.input_values).logits, dim=-1)
    
    predicted[predicted == -100] = processor.tokenizer.pad_token_id
    pred_str = processor.tokenizer.batch_decode(predicted)[0]
    
    # Convert Buckwalter back to Arabic
    return buckwalter.untrans(pred_str)

def find_best_match(transcribed_text, surah_filter=None, ayah_filter=None):
    print(f"DEBUG: Entering find_best_match V4 (Surah: {surah_filter}, Ayah: {ayah_filter})")
    all_ayahs = quran_data["ayahs"]
    
    if not transcribed_text:
        return {"error": "No speech detected"}

    # 1. Filter by Surah and/or Ayah if provided
    ayahs = all_ayahs
    
    if surah_filter:
        ayahs = [a for a in ayahs if a["surah"] == int(surah_filter)]
        if not ayahs:
            return {"error": f"Surah {surah_filter} not found in index"}
            
    if ayah_filter:
        ayahs = [a for a in ayahs if a["ayah"] == int(ayah_filter)]
        if not ayahs:
            return {"error": f"Ayah {ayah_filter} not found in filtered list"}

    t_len = len(transcribed_text)
    
    # Optimization: Filter by length to reduce search space
    # We only apply this if we are searching a large set (more than 1 candidate)
    candidates = []
    
    if len(ayahs) > 1:
        for entry in ayahs:
            # Simple length heuristic
            a_len = len(entry["text"])
            if abs(a_len - t_len) < max(20, t_len * 0.6): # Allow +/- 20 chars or 60% diff
                candidates.append(entry)
        
        # If no candidates (e.g. text is too long or too short), fall back to checking all (within the filter)
        if not candidates:
            candidates = ayahs
    else:
        candidates = ayahs

    best_entry = None
    min_dist = float('inf')
    
    for entry in candidates:
        dist = edit_distance(transcribed_text, entry["text"])
        
        if dist < min_dist:
            min_dist = dist
            best_entry = entry
            
    if best_entry:
        # Calculate similarity score (0.0 to 1.0)
        # Score = 1 - (distance / max_length)
        max_len = max(len(best_entry["text"]), t_len)
        score = 1.0 - (min_dist / max_len) if max_len > 0 else 0
        
        # Threshold for "Correct"
        # 0.8 is a decent starting point for Wav2Vec2 + Arabic
        is_correct = score >= 0.75
        
        return {
            "surah": best_entry["surah"],
            "ayah": best_entry["ayah"],
            "text": best_entry["text"],
            "score": round(score, 2),
            "is_correct": is_correct,
            "min_distance": min_dist
        }
    else:
        return {"error": "No match found"}

# --- API Endpoints ---

@app.get("/")
def home():
    return {"message": "Quran Recitation API is running. POST audio to /recognize"}

@app.post("/recognize")
async def recognize_audio(
    file: UploadFile = File(...),
    surah: Optional[int] = Form(None),
    ayah: Optional[int] = Form(None)
):
    # Validate file type
    if not file.content_type.startswith('audio/'):
        raise HTTPException(status_code=400, detail="File must be an audio file")

    try:
        # 1. Read the uploaded file
        contents = await file.read()
        
        # 2. Load audio using Librosa
        # We wrap bytes in io.BytesIO so librosa can read it like a file
        # target_sr=16000 is CRITICAL for Wav2Vec2
        audio, sr = librosa.load(io.BytesIO(contents), sr=16000)
        
        # 3. Transcribe
        transcribed_arabic = predict_text(audio)
        
        # 4. Find Match in Quran (with optional filter)
        match_result = find_best_match(transcribed_arabic, surah_filter=surah, ayah_filter=ayah)
        
        return {
            "transcription": transcribed_arabic,
            "filters_received": {"surah": surah, "ayah": ayah},
            "analysis": match_result
        }
        
    except Exception as e:
        # Log the full error for debugging
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
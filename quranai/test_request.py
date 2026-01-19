import requests
import os

url = "http://127.0.0.1:8000/recognize"
file_path = r"c:\Users\HP\Desktop\quran-app\quranai\001.mp3"

if not os.path.exists(file_path):
    print(f"File {file_path} not found!")
    exit(1)

with open(file_path, "rb") as f:
    # 1. Test Correct Surah and Correct Ayah (Surah 1, Ayah 1)
    print("\n--- Test 1: Correct Surah (1) & Correct Ayah (1) ---")
    f.seek(0)
    files = {"audio": (file_path, f, "audio/mpeg")}
    data = {"surah": 1, "ayah": 1} 
    
    try:
        response = requests.post(url, files=files, data=data)
        if response.status_code == 200:
             res_json = response.json()
             print("SUCCESS")
             print(f"Match: {res_json.get('analysis', {}).get('text')}")
             print(f"Is Correct: {res_json.get('analysis', {}).get('is_correct')}")
        else:
             print(f"Error: {response.text}")
    except Exception as e:
        print(f"Exception: {e}")

    # 2. Test Correct Surah but Wrong Ayah (Surah 1, Ayah 2)
    print("\n--- Test 2: Correct Surah (1) & Wrong Ayah (2) ---")
    f.seek(0)
    files = {"file": (file_path, f, "audio/mpeg")}
    data = {"surah": 1, "ayah": 2} # This audio is Ayah 1, so forcing Ayah 2 should fail or have high distance
    
    try:
        response = requests.post(url, files=files, data=data)
        if response.status_code == 200:
             res_json = response.json()
             # We expect is_correct to be False or a very low score
             print("SUCCESS (Response Received)")
             print(f"Match: {res_json.get('analysis', {}).get('text')}")
             print(f"Is Correct: {res_json.get('analysis', {}).get('is_correct')}")
             print(f"Score: {res_json.get('analysis', {}).get('score')}")
        else:
             print(f"Error: {response.text}")
    except Exception as e:
        print(f"Exception: {e}")

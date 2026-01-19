import requests
import os

url = "http://127.0.0.1:8000/recognize"
file_path = r"c:\Users\HP\Desktop\quran-app\quranai\001.mp3"

if not os.path.exists(file_path):
    print(f"File {file_path} not found!")
    exit(1)

def run_test(name, surah, ayah):
    print(f"\n--- Test: {name} (Surah={surah}, Ayah={ayah}) ---")
    with open(file_path, "rb") as f:
        files = {"file": (file_path, f, "audio/mpeg")}
        data = {}
        if surah is not None: data["surah"] = surah
        if ayah is not None: data["ayah"] = ayah
        
        try:
            response = requests.post(url, files=files, data=data)
            if response.status_code == 200:
                res = response.json()
                print("SUCCESS")
                print(f"Filters Received: {res.get('filters_received')}")
                print(f"Transcription: {res.get('transcription')}")
                analysis = res.get('analysis', {})
                print(f"Match: Surah {analysis.get('surah')}, Ayah {analysis.get('ayah')}")
                print(f"Text: {analysis.get('text')}")
                print(f"Is Correct: {analysis.get('is_correct')}")
            else:
                print(f"Error {response.status_code}: {response.text}")
        except Exception as e:
            print(f"Exception: {e}")

# Run Tests
run_test("Filter Surah 1 Only", 1, None)
run_test("Filter Surah 1 Ayah 1", 1, 1)
run_test("Filter Surah 1 Ayah 4", 1, 4)

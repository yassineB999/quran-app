import requests
import os

# Laravel API URL
url = "http://127.0.0.1:8001/api/recitation/check"
file_path = r"c:\Users\HP\Desktop\quran-app\quranai\001.mp3"

if not os.path.exists(file_path):
    print(f"File {file_path} not found!")
    exit(1)

def run_test(name, surah_id, ayah_id):
    print(f"\n--- Test: {name} (Surah={surah_id}, Ayah={ayah_id}) ---")
    with open(file_path, "rb") as f:
        files = {"audio": (file_path, f, "audio/mpeg")}
        data = {}
        if surah_id is not None: data["surah_id"] = surah_id
        if ayah_id is not None: data["ayah_id"] = ayah_id
        
        try:
            response = requests.post(url, files=files, data=data)
            print(f"Status: {response.status_code}")
            if response.status_code == 200:
                res = response.json()
                print(f"Response: {res}")
                success = res.get('success')
                print(f"Success: {success}")
                if 'data' in res and 'analysis' in res['data']:
                    analysis = res['data']['analysis']
                    print(f"Match: Surah {analysis.get('surah')}, Ayah {analysis.get('ayah')}")
                    print(f"Is Correct (AI): {analysis.get('is_correct')}")
            else:
                print(f"Error: {response.text}")
        except Exception as e:
            print(f"Exception: {e}")

# Run Tests
# 1. Expect Failure (Mismatch)
run_test("Laravel Filter Mismatch", 1, 1)

# 2. Expect Success (Match)
run_test("Laravel Filter Match", 1, 4)

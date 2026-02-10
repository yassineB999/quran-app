"""
Test script for quran-ai-transcriping async API
"""
import requests
import time

# Note: You need an audio file to test. Using the test_async_api.py from the project
url = "http://localhost:8001/transcribe/async"

# Use a sample audio file - you'll need to have one available
file_path = r"c:\Users\HP\Desktop\quran-app\quranai\001.mp3"

print("Testing async transcription API...")
print(f"Uploading: {file_path}")

with open(file_path, "rb") as f:
    files = {"audio_file": (file_path, f, "audio/mpeg")}
    response = requests.post(url, files=files)
    
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        job_id = result['job_id']
        print(f"✅ Job created: {job_id}")
        print(f"Status URL: {result['status_url']}")
        
        # Poll for completion
        status_url = f"http://localhost:8001{result['status_url']}"
        print("\nWaiting for transcription...")
        
        for i in range(30):  # Try for 30 seconds
            time.sleep(1)
            status_response = requests.get(status_url)
            status_data = status_response.json()
            
            print(f"Status: {status_data['status']}", end='\r')
            
            if status_data['status'] == 'completed':
                print(f"\n✅ Transcription completed!")
                
                # Get metadata
                metadata_url = f"http://localhost:8001/jobs/{job_id}/metadata"
                metadata_response = requests.get(metadata_url)
                metadata = metadata_response.json()
                
                print(f"\nTranscription: {metadata.get('transcription', 'N/A')[:100]}...")
                if 'verses' in metadata:
                    print(f"Matched verses: {len(metadata['verses'])}")
                    for v in metadata['verses'][:3]:  # Show first 3
                        print(f"  Surah {v['surah_number']}:{v['ayah_number']} - {v['text'][:50]}...")
                break
            elif status_data['status'] == 'failed':
                print(f"\n❌ Failed: {status_data.get('error_message')}")
                break
    else:
        print("❌ Error!")
        print(response.text)

import requests
import os

url = "http://127.0.0.1:8000/recognize"
file_path = "001.mp3"

if not os.path.exists(file_path):
    print(f"File {file_path} not found!")
    exit(1)

with open(file_path, "rb") as f:
    files = {"file": (file_path, f, "audio/mpeg")}
    try:
        print(f"Sending to {url}...")
        response = requests.post(url, files=files)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
    except Exception as e:
        print(f"Error: {e}")
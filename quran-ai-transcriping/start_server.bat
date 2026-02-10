@echo off
echo Starting Quran AI Transcription Server...

REM Check if venv exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
    echo Installing dependencies...
    call venv\Scripts\activate
    pip install --upgrade pip
    pip install -r requirements.txt
) else (
    call venv\Scripts\activate
)

echo Starting Server...
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

pause

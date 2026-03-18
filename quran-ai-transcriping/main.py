"""
Root-level entry point for uvicorn.

Allows running: uvicorn main:app --host 127.0.0.1 --port 8000 --reload

This simply re-exports the FastAPI app from app.main so both
'uvicorn main:app' and 'uvicorn app.main:app' work correctly.
"""
from app.main import app  # noqa: F401

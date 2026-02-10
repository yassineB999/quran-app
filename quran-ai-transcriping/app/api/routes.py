"""
API Routes - FastAPI endpoints for job management.

This module defines all HTTP endpoints for the Quran AI API.
It only handles HTTP concerns - all business logic is in other modules.
"""

import os
import logging
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, File, UploadFile, HTTPException, WebSocket, WebSocketDisconnect
import numpy as np
from app.inference.transcription import transcription_service
from fastapi.responses import FileResponse, JSONResponse, HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.queue.job_queue import job_queue
from app.queue.worker import background_worker

logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    """
    Create and configure the FastAPI application.
    
    Returns:
        Configured FastAPI app instance
    """
    app = FastAPI(
        title="Quran AI Transcription API",
        description="API for transcribing Quran recitations with verse-level timestamps",
        version="2.0.0"
    )
    
    # Configure CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Mount static files if they exist
    static_dir = Path(__file__).parent.parent / "static"
    if static_dir.exists():
        app.mount("/assets", StaticFiles(directory=str(static_dir / "assets")), name="assets")
    
    # Register routes
    _register_routes(app)
    
    return app


def _register_routes(app: FastAPI):
    """Register all API routes."""
    
    @app.get("/api/info")
    async def api_info():
        """API information endpoint."""
        return {
            "service": "Quran AI Transcription API",
            "version": "2.0.0",
            "status": "running",
            "endpoints": {
                "health": "/health",
                "transcribe_async": "/transcribe/async",
                "job_status": "/jobs/{job_id}/status",
                "job_metadata": "/jobs/{job_id}/metadata",
                "download_result": "/jobs/{job_id}/download",
                "list_jobs": "/jobs",
                "resume_queue": "/jobs/resume",
                "clear_finished": "/jobs/finished"
            }
        }
    
    @app.get("/")
    async def root():
        """Serve the web UI."""
        static_dir = Path(__file__).parent.parent / "static"
        index_file = static_dir / "index.html"
        
        if index_file.exists():
            with open(index_file, 'r') as f:
                content = f.read()
            return HTMLResponse(content=content)
        else:
            # Fallback to API info if UI not built
            return {
                "service": "Quran AI Transcription API",
                "version": "2.0.0",
                "status": "running",
                "message": "Web UI not built. Run 'cd frontend && npm install && npm run build' to build the UI.",
                "endpoints": {
                    "health": "/health",
                    "transcribe_async": "/transcribe/async",
                    "job_status": "/jobs/{job_id}/status",
                    "job_metadata": "/jobs/{job_id}/metadata",
                    "download_result": "/jobs/{job_id}/download",
                    "list_jobs": "/jobs",
                    "resume_queue": "/jobs/resume",
                    "clear_finished": "/jobs/finished"
                }
            }
    
    @app.get("/health")
    async def health_check():
        """Health check endpoint."""
        return {
            "status": "healthy",
            "worker_running": background_worker.is_running,
            "worker_processing": background_worker.is_processing,
            "queue_size": job_queue.get_queue_size()
        }
    
    @app.post("/transcribe/async")
    async def transcribe_async(audio_file: UploadFile = File(...)):
        """
        Submit an audio file for asynchronous transcription.
        
        The file is queued for processing and a job ID is returned.
        Use the job ID to check status and retrieve results.
        
        Args:
            audio_file: Audio file (MP3, WAV, M4A, etc.)
            
        Returns:
            Job ID and status URL
        """
        try:
            # Validate file
            if not audio_file.filename:
                raise HTTPException(status_code=400, detail="No filename provided")
            
            # Save uploaded file
            upload_dir = Path(__file__).parent.parent.parent / "data" / "uploads"
            upload_dir.mkdir(parents=True, exist_ok=True)
            
            # Generate unique filename
            import uuid
            file_id = str(uuid.uuid4())
            file_ext = Path(audio_file.filename).suffix
            saved_path = upload_dir / f"{file_id}{file_ext}"
            
            # Save file
            with open(saved_path, "wb") as f:
                content = await audio_file.read()
                f.write(content)
            
            logger.info(f"Saved uploaded file: {saved_path}")
            
            # Create job
            job_id = job_queue.create_job(
                audio_file_path=str(saved_path),
                original_filename=audio_file.filename
            )
            
            # Trigger worker
            background_worker.trigger_processing()
            
            return {
                "job_id": job_id,
                "status": "queued",
                "message": "Job created successfully",
                "status_url": f"/jobs/{job_id}/status",
                "download_url": f"/jobs/{job_id}/download"
            }
            
        except Exception as e:
            logger.error(f"Error creating job: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=str(e))
    
    @app.get("/jobs/{job_id}/status")
    async def get_job_status(job_id: str):
        """
        Get the status of a transcription job.
        
        Args:
            job_id: Job ID
            
        Returns:
            Job status information
        """
        job = job_queue.get_job(job_id)
        
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")
        
        response = {
            "job_id": job_id,
            "status": job['status'],
            "created_at": job['created_at'],
            "updated_at": job['updated_at'],
            "original_filename": job['original_filename']
        }
        
        # Add error message if failed
        if job.get('error_message'):
            response['error_message'] = job['error_message']
        
        # Add download URL if completed
        if job['status'] == 'completed' and job.get('result_zip_path'):
            response['download_url'] = f"/jobs/{job_id}/download"
            response['metadata_url'] = f"/jobs/{job_id}/metadata"
        
        return response
    
    @app.get("/jobs/{job_id}/metadata")
    async def get_job_metadata(job_id: str):
        """
        Get the metadata of a completed job.
        
        Args:
            job_id: Job ID
            
        Returns:
            Job metadata including transcription and verse details
        """
        job = job_queue.get_job(job_id)
        
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")
        
        if job['status'] != 'completed':
            raise HTTPException(
                status_code=400,
                detail=f"Job is not completed. Current status: {job['status']}"
            )
        
        metadata = job_queue.get_job_metadata(job_id)
        
        if not metadata:
            raise HTTPException(status_code=404, detail="Metadata not found")
        
        return metadata
    
    @app.get("/jobs/{job_id}/download")
    async def download_result(job_id: str):
        """
        Download the result ZIP file of a completed job.
        
        Args:
            job_id: Job ID
            
        Returns:
            ZIP file containing audio segments and metadata
        """
        job = job_queue.get_job(job_id)
        
        if not job:
            raise HTTPException(status_code=404, detail="Job not found")
        
        if job['status'] != 'completed':
            raise HTTPException(
                status_code=400,
                detail=f"Job is not completed. Current status: {job['status']}"
            )
        
        result_path = job_queue.get_job_result_path(job_id)
        
        if not result_path or not result_path.exists():
            raise HTTPException(status_code=404, detail="Result file not found")
        
        # Generate filename using original uploaded filename
        original_filename = job.get('original_filename', 'audio')
        # Remove extension from original filename
        from pathlib import Path
        filename_without_ext = Path(original_filename).stem
        download_filename = f"{filename_without_ext}_trs_{job_id}.zip"
        
        return FileResponse(
            path=str(result_path),
            media_type="application/zip",
            filename=download_filename
        )
    
    @app.get("/jobs")
    async def list_jobs(status: Optional[str] = None):
        """
        List all jobs, optionally filtered by status.
        
        Args:
            status: Optional status filter (queued, processing, completed, failed)
            
        Returns:
            List of jobs
        """
        jobs = job_queue.get_all_jobs()
        
        # Filter by status if provided
        if status:
            jobs = [job for job in jobs if job['status'] == status]
        
        return {
            "total": len(jobs),
            "jobs": jobs
        }
    
    @app.post("/jobs/resume")
    async def resume_queue():
        """
        Resume the job queue by resetting processing jobs to queued.
        
        Useful after a server restart or crash.
        
        Returns:
            Success message
        """
        try:
            job_queue.reset_processing_jobs()
            background_worker.trigger_processing()
            
            return {
                "message": "Job queue resumed successfully",
                "queue_size": job_queue.get_queue_size()
            }
        except Exception as e:
            logger.error(f"Error resuming queue: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=str(e))
    
    @app.delete("/jobs/finished")
    async def clear_finished_jobs():
        """
        Delete all finished jobs (completed or failed).
        
        Returns:
            Number of jobs deleted
        """
        try:
            count = job_queue.clear_finished_jobs()
            
            return {
                "message": f"Deleted {count} finished jobs",
                "deleted_count": count
            }
        except Exception as e:
            logger.error(f"Error clearing finished jobs: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail=str(e))
    
    @app.delete("/jobs/{job_id}")
    async def delete_job(job_id: str):
        """
        Delete a specific job.
        
        Args:
            job_id: Job ID
            
        Returns:
            Success message
        """
        success = job_queue.delete_job(job_id)
        
        if not success:
            raise HTTPException(status_code=404, detail="Job not found")
        
        return {
            "message": f"Job {job_id} deleted successfully"
        }

    @app.websocket("/ws/recite")
    async def websocket_endpoint(websocket: WebSocket):
        """
        WebSocket endpoint for real-time recitation with word-level feedback.
        
        Uses a "fresh chunk" approach:
        - Audio accumulates in a buffer until enough data is ready
        - Only NEW audio is transcribed (buffer is cleared after extraction)
        - Whisper runs in a background thread so audio keeps arriving
        - Each chunk's text is appended to session_text (no overlap detection needed)
        
        Protocol:
        1. Client sends JSON: {"type": "init", "surah_id": 1}
        2. Server creates session and responds with session_ready
        3. Client sends binary audio chunks (PCM 16-bit, 16kHz, mono)
        4. Server transcribes, aligns words, and returns recitation_update
        """
        from app.inference.session_manager import session_manager
        import json
        import asyncio
        
        await websocket.accept()
        recitation_session = None
        session_id = None
        
        # Fresh chunk parameters
        chunk_duration = 3.0  # Transcribe every 3 seconds of NEW audio (shorter = faster feedback)
        bytes_per_second = 16000 * 2  # 16kHz * 16-bit = 32000 bytes/sec
        CHUNK_SIZE = int(bytes_per_second * chunk_duration)
        SILENCE_ENERGY_THRESHOLD = 0.01  # RMS energy below this = too quiet for reliable transcription
        
        buffer = bytearray()
        session_text = ""
        last_transcription = ""
        is_processing = False  # Prevent overlapping transcriptions
        surah_completed = False  # Stop processing when surah is done
        
        try:
            logger.info("WebSocket client connected")
            
            # First message should be session initialization
            init_data = await websocket.receive_text()
            try:
                init_msg = json.loads(init_data)
                if init_msg.get('type') == 'init':
                    surah_id = init_msg.get('surah_id')
                    if not surah_id:
                        await websocket.send_json({
                            "type": "error",
                            "message": "surah_id is required in init message"
                        })
                        await websocket.close()
                        return
                    
                    # Create recitation session
                    recitation_session = session_manager.create_session(surah_id)
                    session_id = recitation_session.session_id
                    
                    # Send session ready confirmation
                    await websocket.send_json({
                        "type": "session_ready",
                        "session_id": session_id,
                        "surah_id": surah_id,
                        "total_ayahs": recitation_session.total_ayahs,
                        "total_words": len(recitation_session.flat_words)
                    })
                    
                    logger.info(
                        f"Session {session_id} initialized for Surah {surah_id}"
                    )
                else:
                    await websocket.send_json({
                        "type": "error",
                        "message": "First message must be {type: 'init', surah_id: N}"
                    })
                    await websocket.close()
                    return
            except json.JSONDecodeError:
                await websocket.send_json({
                    "type": "error",
                    "message": "Invalid JSON in init message"
                })
                await websocket.close()
                return
            
            # Main loop: receive audio chunks and process
            while True:
                # Receive audio chunk (bytes)
                data = await websocket.receive_bytes()
                buffer.extend(data)
                
                # Skip processing if surah is already completed
                if surah_completed:
                    buffer.clear()
                    continue
                
                # Process when we have enough NEW audio and not already processing
                if len(buffer) >= CHUNK_SIZE and not is_processing:
                    is_processing = True
                    
                    # Extract ALL audio
                    chunk_bytes = bytes(buffer)
                    
                    try:
                        # Convert bytes to numpy array (float32, normalized)
                        audio_int16 = np.frombuffer(chunk_bytes, dtype=np.int16)
                        audio_float32 = audio_int16.astype(np.float32) / 32768.0
                        
                        # Define overlap samples (0.5s * 16000Hz)
                        OVERLAP_SAMPLES = int(16000 * 0.5)
                        
                        # Check audio energy on NEW data only (ignore the overlap part)
                        # buffer = [Old Overlap (0.5s)] + [New Audio (2.5s)]
                        # We want to check if the NEW audio is silent.
                        if len(audio_float32) > OVERLAP_SAMPLES:
                            new_audio = audio_float32[OVERLAP_SAMPLES:]
                        else:
                            new_audio = audio_float32 # Fallback if shorter
                            
                        rms_energy = np.sqrt(np.mean(new_audio ** 2))
                        
                        if rms_energy < SILENCE_ENERGY_THRESHOLD:
                            logger.info(
                                f"Session {session_id}: Skipping quiet chunk "
                                f"(energy={rms_energy:.4f} < {SILENCE_ENERGY_THRESHOLD})"
                            )
                            # Clear buffer on silence to reset context
                            # This is crucial: it prevents dragging old overlap into a long silence
                            buffer.clear()
                            is_processing = False
                            continue
                        
                        # Digital Audio Gain (Normalization)
                        # Whisper works best with normalized audio closer to -3dB or -6dB.
                        # If the audio is too quiet (peak < 0.5), we boost it.
                        max_val = np.max(np.abs(audio_float32))
                        if max_val > 0 and max_val < 0.5:
                            # Target peak 0.5 (-6dB) is safe headroom
                            target_peak = 0.5
                            gain = target_peak / max_val
                            
                            # Cap gain at 5.0x to avoid exploding background noise
                            gain = min(gain, 5.0)
                            
                            audio_float32 = audio_float32 * gain
                            logger.info(
                                f"Session {session_id}: Boosted audio volume by {gain:.2f}x "
                                f"(peak {max_val:.4f} -> {np.max(np.abs(audio_float32)):.4f})"
                            )
                        
                        # Audio Overlap Management
                        # Keep the last 0.5s of audio in the buffer for the next chunk
                        OVERLAP_DURATION = 0.5
                        OVERLAP_SIZE = int(bytes_per_second * OVERLAP_DURATION)
                        buffer = bytearray(buffer[-OVERLAP_SIZE:])
                        
                        audio_duration = len(audio_float32) / 16000.0
                        logger.info(
                            f"Session {session_id}: Processing chunk with overlap "
                            f"({audio_duration:.2f}s, energy={rms_energy:.4f})"
                        )
                        
                        # Run Whisper in a background thread with prompt conditioning
                        # Use the REFERENCE Quran text as prompt (not Whisper's
                        # error-prone transcriptions) — this gives perfect context
                        # about what the user is reciting, preventing error propagation
                        ref_prompt = recitation_session.get_reference_prompt()
                        result = await asyncio.to_thread(
                            transcription_service.transcribe_bytes,
                            audio_float32,
                            prompt_text=ref_prompt if ref_prompt else None
                        )
                        current_text = result.get('text', '').strip()
                        
                        # Hallucination detection: if a word repeats 3+ times
                        # in a row, Whisper is hallucinating on noise/silence
                        if current_text:
                            words = current_text.split()
                            if len(words) >= 3:
                                # Check if any word repeats 3 consecutive times
                                is_hallucination = False
                                for i in range(len(words) - 2):
                                    if words[i] == words[i+1] == words[i+2]:
                                        is_hallucination = True
                                        break
                                if is_hallucination:
                                    logger.info(
                                        f"Session {session_id}: Discarding hallucinated "
                                        f"transcription (repeated words): {current_text[:60]}..."
                                    )
                                    current_text = ""
                        
                        if current_text:
                            # Merge text with overlap handling
                            if session_text and last_transcription:
                                # Merge (last_chunk + new_chunk) dealing with overlap
                                merged_segment = transcription_service.remove_overlap_with_sequencematcher(
                                    last_transcription, current_text
                                )
                                
                                # Update session_text: remove the raw last_transcription and add merged version
                                base_text = session_text
                                if base_text.endswith(last_transcription):
                                    base_text = base_text[:-len(last_transcription)].strip()
                                
                                if base_text:
                                    session_text = base_text + ' ' + merged_segment
                                else:
                                    session_text = merged_segment
                                
                                logger.info(f"Session {session_id}: Merged '{last_transcription}' + '{current_text}' -> '{merged_segment}'")
                            else:
                                if session_text:
                                    session_text = session_text + ' ' + current_text
                                else:
                                    session_text = current_text
                            
                            # Update last_transcription for next iteration
                            last_transcription = current_text
                            
                            logger.info(
                                f"Session {session_id}: Accumulated "
                                f"{len(session_text.split())} words total"
                            )
                            
                            # Align full transcription against reference text
                            alignment_result = recitation_session.align_transcription(
                                session_text
                            )
                            
                            # Check if surah is completed
                            if alignment_result.get('is_final', False):
                                surah_completed = True
                                logger.info(
                                    f"Session {session_id}: Surah {surah_id} "
                                    f"recitation completed!"
                                )
                            
                            # Send word-level update to client
                            await websocket.send_json(alignment_result)
                    
                    except Exception as proc_error:
                        logger.error(
                            f"Session {session_id}: Processing error: {proc_error}",
                            exc_info=True
                        )
                    finally:
                        is_processing = False
        
        except WebSocketDisconnect:
            logger.info(f"WebSocket client disconnected (session: {session_id})")
        except Exception as e:
            logger.error(f"WebSocket error: {e}", exc_info=True)
            try:
                await websocket.send_json({
                    "type": "error",
                    "message": str(e)
                })
                await websocket.close()
            except:
                pass
        finally:
            # Cleanup session on disconnect
            if session_id:
                session_manager.destroy_session(session_id)

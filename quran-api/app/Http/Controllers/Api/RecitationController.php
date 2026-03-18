<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;

class RecitationController extends Controller
{
    public function check(Request $request)
    {
        Log::info('=== RECITATION CHECK REQUEST STARTED ===');

        $audioFile = null;
        $tempPath = null;

        // Check for binary raw body content
        if (
            $request->header('Content-Type') === 'audio/mpeg' ||
            $request->header('Content-Type') === 'application/octet-stream' ||
            !$request->hasFile('audio')
        ) {

            Log::info('Handling request as binary/raw content...');
            $content = $request->getContent();

            if (empty($content)) {
                Log::error('Validation failed: No audio content provided in body');
                return response()->json(['message' => 'The audio content is required.'], 422);
            }

            // Save raw content to a temporary file so Http::attach can read it
            $tempPath = tempnam(sys_get_temp_dir(), 'audio_');
            file_put_contents($tempPath, $content);

            // Create a pseudo file object for logging/processing if needed, or just use path
            Log::info('Binary content saved to: ' . $tempPath . ' (Size: ' . strlen($content) . ')');

            // Manually set path for downstream logic
            $audioPath = $tempPath;
            $originalName = 'recording.mp3'; // Default name
        } else {
            // Standard Multipart Form Data
            // 1. Validation
            try {
                $request->validate([
                    'audio' => 'required|file|mimes:webm,ogg,wav,mp3,m4a,mp4',
                    'ayah_id' => 'nullable|string',
                    'surah_id' => 'nullable|integer',
                ]);
                Log::info('Validation passed');
            } catch (\Exception $e) {
                Log::error('Validation failed: ' . $e->getMessage());
                throw $e;
            }

            $audioFile = $request->file('audio');
            $audioPath = $audioFile->getPathname();
            $originalName = $audioFile->getClientOriginalName();

            Log::info('Audio file details:', [
                'original_name' => $originalName,
                'mime_type' => $audioFile->getMimeType(),
                'size_bytes' => $audioFile->getSize(),
                'path' => $audioPath,
            ]);
        }

        // 2. Forward to Python AI API
        // Ensure we are using the internal docker network URL if running inside docker, 
        // or the provided env var.
        $pythonApiUrl = env('PYTHON_API_URL', 'http://quran_ai_service:8000/recognize');
        Log::info("Forwarding request to Python API: {$pythonApiUrl}");

        // Prepare parameters
        $params = [];
        if ($request->has('surah_id')) {
            $params['surah'] = $request->input('surah_id');
        }
        if ($request->has('ayah_id')) {
            $params['ayah'] = $request->input('ayah_id');
        }

        try {
            $response = Http::timeout(300) // 5 minutes timeout for slow AI processing
                ->connectTimeout(10) // 10 seconds connection timeout
                ->attach(
                    'file',
                    file_get_contents($audioPath),
                    $originalName
                )->post($pythonApiUrl, $params);

            // Clean up temp file if used
            if ($tempPath && file_exists($tempPath)) {
                unlink($tempPath);
            }

            if ($response->successful()) {
                $data = $response->json();
                Log::info('Python API Response:', $data);

                // User Requirement: "if this what he said correct put it if not dont"
                // Check 'is_correct' flag from Python API
                $analysis = $data['analysis'] ?? [];

                if (isset($analysis['is_correct']) && $analysis['is_correct'] === true) {
                    // Match found and correct
                    return response()->json([
                        'success' => true,
                        'data' => $data
                    ]);
                } else {
                    // Match found but incorrect (low score) OR No match found
                    // We treat this as "Don't put it" / "Not correct"
                    return response()->json([
                        'success' => false,
                        'message' => 'Recitation not recognized or incorrect.',
                        'data' => $data // Optional: return data for debugging/feedback if needed
                    ], 200); // Keep 200 OK but success=false, or use 422? Let's stick to 200 with success=false flag as per common API patterns
                }
            } else {
                Log::error('Python API Error: ' . $response->body());
                return response()->json([
                    'success' => false,
                    'message' => 'Failed to process audio with AI engine',
                    'details' => $response->json() ?? $response->body()
                ], $response->status());
            }
        } catch (\Exception $e) {
            Log::error('Connection to Python API failed: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'AI Service unavailable',
            ], 503);
        }
    }
}

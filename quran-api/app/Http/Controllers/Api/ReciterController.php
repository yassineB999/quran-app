<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Reciter;
use App\Models\Surah;
use Illuminate\Http\Request;

class ReciterController extends Controller
{
    public function index()
    {
        $reciters = Reciter::where('rewaya', 'warsh')->orWhere('rewaya', 'like', '%Warsh%')->get();
        return response()->json(['data' => $reciters]);
    }

    public function audio($reciterId, $surahId)
    {
        $reciter = Reciter::where('reciter_id', (int)$reciterId)
            ->orWhere('reciter_id', $reciterId)
            ->orWhere('id', $reciterId)
            ->first();

        if (!$reciter) {
            return response()->json(['message' => 'Reciter not found'], 404);
        }

        $formattedSurahId = str_pad($surahId, 3, '0', STR_PAD_LEFT);

        $baseUrl = rtrim(trim($reciter->server_url), '/');
        $audioUrl = "{$baseUrl}/{$formattedSurahId}.mp3";

        return response()->json([
            'reciter_id' => $reciter->reciter_id,
            'surah_id' => $surahId,
            'audio_url' => $audioUrl
        ]);
    }
}

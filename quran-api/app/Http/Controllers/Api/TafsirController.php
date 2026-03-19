<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;

class TafsirController extends Controller
{
    public function show($surah, $ayah)
    {
        $cacheKey = "tafsir_{$surah}_{$ayah}_v2";

        // Cache for 30 days
        $data = Cache::remember($cacheKey, now()->addDays(30), function () use ($surah, $ayah) {
            // Fetch Arabic Tafsir (Al-Muyassar)
            $arabicResponse = Http::timeout(5)->get("http://api.alquran.cloud/v1/ayah/{$surah}:{$ayah}/ar.muyassar");
            
            // Fetch French translation (Hamidullah)
            $frenchResponse = Http::timeout(5)->get("http://api.alquran.cloud/v1/ayah/{$surah}:{$ayah}/fr.hamidullah");

            // Fetch English translation (Sahih)
            $englishResponse = Http::timeout(5)->get("http://api.alquran.cloud/v1/ayah/{$surah}:{$ayah}/en.sahih");

            $arabicTafsir = $arabicResponse->successful() ? $arabicResponse->json('data.text') : null;
            $frenchTranslation = $frenchResponse->successful() ? $frenchResponse->json('data.text') : null;
            $englishTranslation = $englishResponse->successful() ? $englishResponse->json('data.text') : null;

            if (!$arabicTafsir) {
                return null;
            }

            return [
                'surah' => (int)$surah,
                'ayah' => (int)$ayah,
                'tafsir_arabic' => $arabicTafsir,
                'translation_french' => $frenchTranslation,
                'translation_english' => $englishTranslation,
            ];
        });

        if (!$data) {
            return response()->json(['message' => 'Tafsir not found'], 404);
        }

        return response()->json(['data' => $data]);
    }
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Surah;
use App\Models\Ayah;
use Illuminate\Http\Request;

class SurahController extends Controller
{
    public function index()
    {
        $surahs = Surah::orderBy('number', 'asc')->get();
        return response()->json(['data' => $surahs]);
    }

    public function show($id)
    {
        $surah = Surah::where('number', (int)$id)->with('ayahs')->first();

        if (!$surah) {
            return response()->json(['message' => 'Surah not found'], 404);
        }

        return response()->json(['data' => $surah]);
    }

    /**
     * Get the page range for a specific surah.
     * Returns the first and last page numbers where this surah appears.
     */
    public function pages($id)
    {
        $surahNumber = (int)$id;

        // Get min and max page from ayahs belonging to this surah
        $minPage = Ayah::where('surah_number', $surahNumber)->min('page');
        $maxPage = Ayah::where('surah_number', $surahNumber)->max('page');

        if ($minPage === null) {
            return response()->json(['message' => 'Surah not found'], 404);
        }

        return response()->json([
            'data' => [
                'surah_number' => $surahNumber,
                'first_page' => $minPage,
                'last_page' => $maxPage,
            ]
        ]);
    }

    /**
     * Get word-level data for a specific surah.
     * Returns all words with their ayah numbers and normalized text.
     * Used by the real-time recitation feature for pre-loading reference text.
     */
    public function words($id)
    {
        $surahNumber = (int)$id;

        // Get all ayahs for this surah
        $ayahs = Ayah::where('surah_number', $surahNumber)
            ->orderBy('number_in_surah', 'asc')
            ->get();

        if ($ayahs->isEmpty()) {
            return response()->json(['message' => 'Surah not found or no ayahs'], 404);
        }

        // DEBUG: Return first ayah to see structure
        // return response()->json(['debug_first_ayah' => $ayahs->first()]);

        $words = [];

        foreach ($ayahs as $ayah) {
            // Check if text exists
            // Use text_warsh if text is missing, based on model definition
            $displayText = $ayah->text ?? ($ayah->text_warsh ?? '');

            if (empty($displayText)) continue;

            // Normalize: remove tashkeel if normalized field is missing
            $normalizedText = $ayah->text_normalized ?? $this->removeTashkeel($displayText);

            // Split text into words
            $wordsDisplay = preg_split('/\s+/', $displayText, -1, PREG_SPLIT_NO_EMPTY);
            $wordsNormalized = preg_split('/\s+/', $normalizedText, -1, PREG_SPLIT_NO_EMPTY);

            // Ensure both arrays have the same length (fallback to display if normalized is missing)
            $wordCount = count($wordsDisplay);

            for ($idx = 0; $idx < $wordCount; $idx++) {
                $words[] = [
                    'ayah' => $ayah->number_in_surah,
                    'word_index' => $idx,
                    'text' => $wordsDisplay[$idx] ?? '',
                    'normalized' => $wordsNormalized[$idx] ?? ($wordsDisplay[$idx] ?? ''),
                ];
            }
        }

        return response()->json([
            'data' => [
                'surah_number' => $surahNumber,
                'total_words' => count($words),
                'words' => $words
            ]
        ]);
    }

    private function removeTashkeel($text)
    {
        // Remove Arabic diacritics
        $tashkeel = ['ِ', 'u', 'َ', 'ً', 'ُ', 'ٌ', 'ٍ', 'ْ', 'ّ', 'ـ'];
        // Unicode ranges for tashkeel: 064B-0652, 0670, 06D6-06ED (approx)
        return preg_replace('/[\x{064B}-\x{065F}\x{0670}\x{06D6}-\x{06DC}\x{06DF}-\x{06E8}\x{06EA}-\x{06ED}]/u', '', $text);
    }
}

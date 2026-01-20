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
}

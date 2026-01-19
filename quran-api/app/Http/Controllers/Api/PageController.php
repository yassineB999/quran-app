<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ayah;
use Illuminate\Http\Request;

class PageController extends Controller
{
    public function show($page)
    {
        // Validate page range (1-604 for standard Mushaf)
        $pageNumber = (int)$page;
        if ($pageNumber < 1 || $pageNumber > 604) {
            return response()->json(['message' => 'Page not found'], 404);
        }

        // Fetch ayahs for this page, sorted by surah and number within surah
        // Also load Surah info to display headers
        $ayahs = Ayah::with('surah')
            ->where('page', $pageNumber)
            ->orderBy('surah_number')
            ->orderBy('number_in_surah')
            ->get();

        if ($ayahs->isEmpty()) {
            return response()->json(['message' => 'Page not found'], 404);
        }

        return response()->json(['data' => $ayahs]);
    }
}

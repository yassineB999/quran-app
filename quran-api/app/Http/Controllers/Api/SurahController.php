<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Surah;
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
}

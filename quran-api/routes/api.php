<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\SurahController;
use App\Http\Controllers\Api\ReciterController;
use App\Http\Controllers\Api\PageController;
use App\Http\Controllers\Api\HadithController;
use App\Http\Controllers\Api\AdhkarController;
use App\Http\Controllers\Api\HijriCalendarController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::controller(SurahController::class)->group(function () {
    Route::get('/surahs', 'index');
    Route::get('/surahs/{id}', 'show');
    Route::get('/surahs/{id}/pages', 'pages');
});

Route::controller(ReciterController::class)->group(function () {
    Route::get('/reciters', 'index');
    Route::get('/audio/{reciter_id}/{surah_id}', 'audio');
});

Route::controller(PageController::class)->group(function () {
    Route::get('/pages/{page}', 'show');
});

Route::post('/recitation/check', [\App\Http\Controllers\Api\RecitationController::class, 'check']);

Route::controller(HadithController::class)->group(function () {
    Route::get('/hadith/editions', 'editions');
    Route::get('/hadith/daily', 'daily');
    Route::get('/hadith/{edition}', 'show');
});

Route::get('/adhkar/{category}', [AdhkarController::class, 'show']);

Route::controller(HijriCalendarController::class)->group(function () {
    Route::get('/hijri/calendar/{year}', 'year');
    Route::get('/hijri/calendar/{year}/{month}', 'month');
});

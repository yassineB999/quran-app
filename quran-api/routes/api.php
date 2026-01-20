<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\SurahController;
use App\Http\Controllers\Api\ReciterController;
use App\Http\Controllers\Api\PageController;

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

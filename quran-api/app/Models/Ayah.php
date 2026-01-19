<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Ayah extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'ayahs';

    protected $fillable = [
        'number',
        'number_in_surah',
        'surah_number',
        'text_warsh',
        'juz',
        'page',
        'hizb',
        'manzil',
        'translation_en',
    ];

    public function surah()
    {
        return $this->belongsTo(Surah::class, 'surah_number', 'number');
    }
}

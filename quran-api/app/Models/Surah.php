<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Surah extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'surahs';

    protected $fillable = [
        'number',
        'name_simple',
        'name_arabic',
        'verses_count',
        'revelation_place',
    ];

    public function ayahs()
    {
        return $this->hasMany(Ayah::class, 'surah_number', 'number');
    }
}

<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class HadithCache extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'hadith_cache';

    protected $fillable = [
        'type',
        'edition',
        'hadith_number',
        'section_number',
        'payload',
        'source_url',
        'fetched_at',
    ];

    protected $casts = [
        'payload' => 'array',
        'fetched_at' => 'datetime',
        'hadith_number' => 'integer',
        'section_number' => 'integer',
    ];
}

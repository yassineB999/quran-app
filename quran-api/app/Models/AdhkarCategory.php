<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class AdhkarCategory extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'adhkar_categories';

    protected $fillable = [
        'category',
        'language',
        'title',
        'payload',
        'source_url',
        'fetched_at',
    ];

    protected $casts = [
        'payload' => 'array',
        'fetched_at' => 'datetime',
    ];
}

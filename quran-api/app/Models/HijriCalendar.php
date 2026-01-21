<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class HijriCalendar extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'hijri_calendars';

    protected $fillable = [
        'gregorian_year',
        'month',
        'payload',
        'source_url',
        'fetched_at',
    ];

    protected $casts = [
        'payload' => 'array',
        'fetched_at' => 'datetime',
        'gregorian_year' => 'integer',
        'month' => 'integer',
    ];
}

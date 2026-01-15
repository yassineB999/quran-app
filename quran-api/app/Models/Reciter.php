<?php

namespace App\Models;

use MongoDB\Laravel\Eloquent\Model;

class Reciter extends Model
{
    protected $connection = 'mongodb';
    protected $collection = 'reciters';

    protected $fillable = [
        'name',
        'reciter_id',
        'rewaya',
        'server_url',
    ];
}

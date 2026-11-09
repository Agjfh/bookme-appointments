<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkingHour extends Model
{
    protected $fillable = ['provider_id', 'weekday', 'opens_at', 'closes_at'];

    protected function casts(): array
    {
        return ['weekday' => 'integer'];
    }
}

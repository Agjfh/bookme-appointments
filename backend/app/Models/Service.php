<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Service extends Model
{
    protected $fillable = ['provider_id', 'name', 'duration_minutes', 'price', 'is_active'];

    protected function casts(): array
    {
        return ['price' => 'decimal:2', 'duration_minutes' => 'integer', 'is_active' => 'boolean'];
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }
}

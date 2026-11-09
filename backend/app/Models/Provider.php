<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Provider extends Model
{
    protected $fillable = [
        'owner_id', 'name', 'category', 'about', 'address', 'city',
        'phone', 'image_url', 'rating', 'slot_minutes',
    ];

    protected function casts(): array
    {
        return ['rating' => 'decimal:1', 'slot_minutes' => 'integer'];
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function services(): HasMany
    {
        return $this->hasMany(Service::class);
    }

    public function workingHours(): HasMany
    {
        return $this->hasMany(WorkingHour::class)->orderBy('weekday');
    }

    public function appointments(): HasMany
    {
        return $this->hasMany(Appointment::class);
    }
}

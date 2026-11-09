<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Appointment extends Model
{
    public const STATUSES = ['confirmed', 'completed', 'cancelled', 'no_show'];

    /** Customers can cancel up to this many hours before the appointment. */
    public const CANCEL_NOTICE_HOURS = 2;

    protected $fillable = [
        'user_id', 'provider_id', 'service_id', 'starts_at', 'ends_at', 'price', 'status', 'notes',
    ];

    protected function casts(): array
    {
        return ['starts_at' => 'datetime', 'ends_at' => 'datetime', 'price' => 'decimal:2'];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function provider(): BelongsTo
    {
        return $this->belongsTo(Provider::class);
    }

    public function service(): BelongsTo
    {
        return $this->belongsTo(Service::class);
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', 'confirmed');
    }

    /** Active appointments that overlap the given time range. */
    public function scopeOverlapping(Builder $query, $start, $end): Builder
    {
        return $query->active()->where('starts_at', '<', $end)->where('ends_at', '>', $start);
    }

    public function isCancellable(): bool
    {
        return $this->status === 'confirmed'
            && $this->starts_at->greaterThan(now()->addHours(self::CANCEL_NOTICE_HOURS));
    }
}

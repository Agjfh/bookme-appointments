<?php

namespace App\Services;

use App\Exceptions\SlotUnavailableException;
use App\Models\Appointment;
use App\Models\Provider;
use App\Models\Service;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

class AvailabilityService
{
    /**
     * Free start times for a service on a date, e.g. ["09:00", "09:30", ...].
     *
     * @return list<string>
     */
    public function slots(Provider $provider, Service $service, CarbonImmutable $date): array
    {
        $hours = $provider->workingHours()->where('weekday', $date->dayOfWeek)->first();
        if (! $hours) {
            return [];
        }

        $opens = $date->setTimeFromTimeString($hours->opens_at);
        $closes = $date->setTimeFromTimeString($hours->closes_at);
        $step = max(5, $provider->slot_minutes);

        $booked = $provider->appointments()
            ->active()
            ->where('starts_at', '<', $closes)
            ->where('ends_at', '>', $opens)
            ->get(['starts_at', 'ends_at']);

        $earliest = CarbonImmutable::now()->addMinutes(30);
        $slots = [];

        for ($start = $opens; $start->addMinutes($service->duration_minutes)->lte($closes); $start = $start->addMinutes($step)) {
            $end = $start->addMinutes($service->duration_minutes);

            if ($start->lt($earliest)) {
                continue;
            }

            $clash = $booked->contains(fn ($a) => $a->starts_at->lt($end) && $a->ends_at->gt($start));
            if (! $clash) {
                $slots[] = $start->format('H:i');
            }
        }

        return $slots;
    }

    /** Books a slot. The provider row is locked so the same slot can't be double-booked. */
    public function book(User $user, Service $service, CarbonImmutable $startsAt, ?string $notes = null): Appointment
    {
        return DB::transaction(function () use ($user, $service, $startsAt, $notes) {
            $provider = Provider::whereKey($service->provider_id)->lockForUpdate()->firstOrFail();

            if (! in_array($startsAt->format('H:i'), $this->slots($provider, $service, $startsAt->startOfDay()), true)) {
                throw new SlotUnavailableException('This time is no longer available. Please pick another slot.');
            }

            $alreadyBusy = $user->appointments()
                ->overlapping($startsAt, $startsAt->addMinutes($service->duration_minutes))
                ->exists();
            if ($alreadyBusy) {
                throw new SlotUnavailableException('You already have another appointment at this time.');
            }

            return Appointment::create([
                'user_id' => $user->id,
                'provider_id' => $provider->id,
                'service_id' => $service->id,
                'starts_at' => $startsAt,
                'ends_at' => $startsAt->addMinutes($service->duration_minutes),
                'price' => $service->price,
                'status' => 'confirmed',
                'notes' => $notes,
            ])->load(['provider', 'service']);
        });
    }
}

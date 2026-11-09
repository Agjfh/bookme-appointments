<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProviderResource extends JsonResource
{
    private const DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'category' => $this->category,
            'about' => $this->about,
            'address' => $this->address,
            'city' => $this->city,
            'phone' => $this->phone,
            'image_url' => $this->image_url,
            'rating' => (float) $this->rating,
            'starting_price' => $this->whenHas('services_min_price', fn () => (float) $this->services_min_price),
            'services' => ServiceResource::collection($this->whenLoaded('services')),
            'working_hours' => $this->whenLoaded('workingHours', fn () => $this->workingHours->map(fn ($h) => [
                'weekday' => $h->weekday,
                'day' => self::DAYS[$h->weekday],
                'opens_at' => substr($h->opens_at, 0, 5),
                'closes_at' => substr($h->closes_at, 0, 5),
            ])),
        ];
    }
}

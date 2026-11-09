<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AppointmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
            'starts_at' => $this->starts_at->toIso8601String(),
            'ends_at' => $this->ends_at->toIso8601String(),
            'price' => (float) $this->price,
            'notes' => $this->notes,
            'can_cancel' => $this->isCancellable(),
            'provider' => new ProviderResource($this->whenLoaded('provider')),
            'service' => new ServiceResource($this->whenLoaded('service')),
            'customer' => $this->whenLoaded('user', fn () => [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'phone' => $this->user->phone,
            ]),
        ];
    }
}

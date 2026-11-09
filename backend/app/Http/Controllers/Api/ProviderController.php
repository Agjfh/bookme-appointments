<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ProviderResource;
use App\Models\Provider;
use App\Services\AvailabilityService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ProviderController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
            'category' => ['nullable', 'string', 'max:50'],
            'city' => ['nullable', 'string', 'max:50'],
        ]);

        $providers = Provider::query()
            ->withMin(['services' => fn ($q) => $q->where('is_active', true)], 'price')
            ->when($request->q, fn ($q, $term) => $q->where(fn ($w) => $w
                ->where('name', 'like', "%{$term}%")
                ->orWhereHas('services', fn ($s) => $s->where('name', 'like', "%{$term}%"))))
            ->when($request->category, fn ($q, $c) => $q->where('category', $c))
            ->when($request->city, fn ($q, $c) => $q->where('city', $c))
            ->orderByDesc('rating')
            ->paginate(20);

        return ProviderResource::collection($providers);
    }

    public function categories(): JsonResponse
    {
        return response()->json(Provider::query()->distinct()->orderBy('category')->pluck('category'));
    }

    public function show(Provider $provider): ProviderResource
    {
        return new ProviderResource($provider->load([
            'services' => fn ($q) => $q->where('is_active', true)->orderBy('price'),
            'workingHours',
        ]));
    }

    public function slots(Request $request, Provider $provider, AvailabilityService $availability): JsonResponse
    {
        $data = $request->validate([
            'service_id' => ['required', 'integer'],
            'date' => ['required', 'date_format:Y-m-d', 'after_or_equal:today', 'before:+60 days'],
        ]);

        $service = $provider->services()->where('is_active', true)->findOrFail($data['service_id']);

        return response()->json([
            'date' => $data['date'],
            'service_id' => $service->id,
            'slots' => $availability->slots($provider, $service, CarbonImmutable::parse($data['date'])),
        ]);
    }
}

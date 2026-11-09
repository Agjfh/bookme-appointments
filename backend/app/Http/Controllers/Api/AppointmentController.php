<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AppointmentResource;
use App\Models\Appointment;
use App\Models\Service;
use App\Services\AvailabilityService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class AppointmentController extends Controller
{
    public function __construct(private readonly AvailabilityService $availability)
    {
    }

    public function index(Request $request): AnonymousResourceCollection
    {
        $scope = $request->validate(['scope' => ['nullable', Rule::in(['upcoming', 'past'])]])['scope'] ?? 'upcoming';

        $appointments = $request->user()->appointments()
            ->with(['provider', 'service'])
            ->when($scope === 'upcoming',
                fn ($q) => $q->where('starts_at', '>=', now())->where('status', 'confirmed')->orderBy('starts_at'),
                fn ($q) => $q->where(fn ($w) => $w->where('starts_at', '<', now())->orWhere('status', '!=', 'confirmed'))
                    ->orderByDesc('starts_at'))
            ->paginate(20);

        return AppointmentResource::collection($appointments);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'service_id' => ['required', 'integer', 'exists:services,id'],
            'starts_at' => ['required', 'date_format:Y-m-d H:i', 'after:now'],
            'notes' => ['nullable', 'string', 'max:500'],
        ]);

        $appointment = $this->availability->book(
            $request->user(),
            Service::where('is_active', true)->findOrFail($data['service_id']),
            CarbonImmutable::createFromFormat('Y-m-d H:i', $data['starts_at']),
            $data['notes'] ?? null,
        );

        return (new AppointmentResource($appointment))->response()->setStatusCode(201);
    }

    public function cancel(Request $request, Appointment $appointment): AppointmentResource
    {
        abort_unless($appointment->user_id === $request->user()->id, 404);
        abort_unless(
            $appointment->isCancellable(),
            422,
            'Appointments can be cancelled up to '.Appointment::CANCEL_NOTICE_HOURS.' hours before they start.'
        );

        $appointment->update(['status' => 'cancelled']);

        return new AppointmentResource($appointment->load(['provider', 'service']));
    }

    /** Schedule for providers owned by the signed-in user. */
    public function schedule(Request $request): AnonymousResourceCollection
    {
        $date = CarbonImmutable::parse($request->validate(['date' => ['nullable', 'date']])['date'] ?? today()->toDateString());

        $appointments = Appointment::whereIn('provider_id', $request->user()->providers()->pluck('id'))
            ->whereBetween('starts_at', [$date->startOfDay(), $date->endOfDay()])
            ->with(['service', 'user', 'provider'])
            ->orderBy('starts_at')
            ->get();

        return AppointmentResource::collection($appointments);
    }

    public function updateStatus(Request $request, Appointment $appointment): AppointmentResource
    {
        abort_unless($appointment->provider->owner_id === $request->user()->id, 403);
        $data = $request->validate(['status' => ['required', Rule::in(Appointment::STATUSES)]]);

        $appointment->update($data);

        return new AppointmentResource($appointment->load(['service', 'user', 'provider']));
    }
}

<?php

namespace Tests\Feature;

use App\Models\Provider;
use App\Models\Service;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AppointmentTest extends TestCase
{
    use RefreshDatabase;

    private Provider $provider;

    private Service $service;

    private CarbonImmutable $day;

    protected function setUp(): void
    {
        parent::setUp();

        $this->day = CarbonImmutable::now()->addDays(3)->startOfDay();
        $this->provider = Provider::create([
            'owner_id' => User::factory()->create()->id,
            'name' => 'Smile Dental',
            'category' => 'Dental',
            'address' => 'Nasr City',
            'city' => 'Cairo',
            'slot_minutes' => 30,
        ]);
        $this->service = $this->provider->services()->create([
            'name' => 'Check-up', 'duration_minutes' => 30, 'price' => 300,
        ]);
        $this->provider->workingHours()->create([
            'weekday' => $this->day->dayOfWeek, 'opens_at' => '09:00', 'closes_at' => '11:00',
        ]);
    }

    private function slots(): array
    {
        return $this->getJson("/api/providers/{$this->provider->id}/slots?service_id={$this->service->id}&date={$this->day->toDateString()}")
            ->assertOk()
            ->json('slots');
    }

    public function test_slots_follow_working_hours(): void
    {
        $this->assertSame(['09:00', '09:30', '10:00', '10:30'], $this->slots());
    }

    public function test_booking_removes_the_slot(): void
    {
        $this->actingAs(User::factory()->create())->postJson('/api/appointments', [
            'service_id' => $this->service->id,
            'starts_at' => $this->day->toDateString().' 09:30',
        ])->assertCreated()->assertJsonPath('status', 'confirmed');

        $this->assertSame(['09:00', '10:00', '10:30'], $this->slots());
    }

    public function test_the_same_slot_cannot_be_booked_twice(): void
    {
        $payload = ['service_id' => $this->service->id, 'starts_at' => $this->day->toDateString().' 10:00'];

        $this->actingAs(User::factory()->create())->postJson('/api/appointments', $payload)->assertCreated();
        $this->actingAs(User::factory()->create())->postJson('/api/appointments', $payload)->assertUnprocessable();
    }

    public function test_closed_days_have_no_slots(): void
    {
        $closed = $this->day->addDay()->toDateString();

        $this->getJson("/api/providers/{$this->provider->id}/slots?service_id={$this->service->id}&date={$closed}")
            ->assertOk()
            ->assertJsonPath('slots', []);
    }

    public function test_cancelling_frees_the_slot(): void
    {
        $user = User::factory()->create();
        $id = $this->actingAs($user)->postJson('/api/appointments', [
            'service_id' => $this->service->id,
            'starts_at' => $this->day->toDateString().' 09:00',
        ])->json('id');

        $this->actingAs($user)->postJson("/api/appointments/{$id}/cancel")
            ->assertOk()
            ->assertJsonPath('status', 'cancelled');

        $this->assertContains('09:00', $this->slots());
    }
}

<?php

namespace Database\Seeders;

use App\Models\Provider;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        User::factory()->create(['name' => 'Demo Customer', 'email' => 'demo@bookme.test', 'phone' => '01000000001']);
        $owner = User::factory()->create(['name' => 'Business Owner', 'email' => 'owner@bookme.test']);

        $providers = [
            ['Smile Dental Clinic', 'Dental', 'Nasr City', 'Cairo', 4.8, [
                ['Check-up & consultation', 30, 300], ['Teeth cleaning', 45, 600], ['Teeth whitening', 60, 2500],
            ]],
            ['Elite Barber Studio', 'Barber', 'Maadi', 'Cairo', 4.7, [
                ['Haircut', 30, 150], ['Haircut & beard', 45, 220], ['Hot towel shave', 30, 120],
            ]],
            ['Glow Beauty Salon', 'Beauty', 'Smouha', 'Alexandria', 4.6, [
                ['Hair styling', 60, 400], ['Manicure', 45, 250], ['Facial treatment', 60, 650],
            ]],
            ['FitLife Physiotherapy', 'Physiotherapy', '10th of Ramadan', 'Sharkia', 4.9, [
                ['Assessment session', 45, 350], ['Sports massage', 60, 450], ['Rehab session', 45, 400],
            ]],
            ['Paws Vet Clinic', 'Veterinary', 'Sheikh Zayed', 'Giza', 4.5, [
                ['General check-up', 30, 250], ['Vaccination', 15, 300], ['Grooming', 60, 400],
            ]],
        ];

        foreach ($providers as [$name, $category, $area, $city, $rating, $services]) {
            $provider = Provider::create([
                'owner_id' => $owner->id,
                'name' => $name,
                'category' => $category,
                'about' => "{$name} offers professional {$category} services in {$area}, {$city}, with a friendly team and modern equipment.",
                'address' => "{$area}, {$city}",
                'city' => $city,
                'phone' => '010'.random_int(10000000, 99999999),
                'image_url' => 'https://picsum.photos/seed/'.Str::slug($name).'/800/500',
                'rating' => $rating,
                'slot_minutes' => 15,
            ]);

            foreach ($services as [$service, $minutes, $price]) {
                $provider->services()->create(['name' => $service, 'duration_minutes' => $minutes, 'price' => $price]);
            }

            // Open Saturday to Thursday, closed on Friday (weekday 5).
            foreach ([0, 1, 2, 3, 4, 6] as $weekday) {
                $provider->workingHours()->create([
                    'weekday' => $weekday,
                    'opens_at' => $weekday === 4 ? '10:00' : '09:00',
                    'closes_at' => $weekday === 4 ? '16:00' : '21:00',
                ]);
            }
        }
    }
}

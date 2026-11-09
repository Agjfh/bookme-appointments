<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('providers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $table->string('name');
            $table->string('category');
            $table->text('about')->nullable();
            $table->string('address');
            $table->string('city');
            $table->string('phone')->nullable();
            $table->string('image_url')->nullable();
            $table->decimal('rating', 2, 1)->default(0);
            $table->unsignedSmallInteger('slot_minutes')->default(30);
            $table->timestamps();
        });

        Schema::create('services', function (Blueprint $table) {
            $table->id();
            $table->foreignId('provider_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->unsignedSmallInteger('duration_minutes');
            $table->decimal('price', 10, 2);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('working_hours', function (Blueprint $table) {
            $table->id();
            $table->foreignId('provider_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('weekday'); // 0 = Sunday ... 6 = Saturday
            $table->time('opens_at');
            $table->time('closes_at');
            $table->timestamps();

            $table->unique(['provider_id', 'weekday']);
        });

        Schema::create('appointments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('provider_id')->constrained()->cascadeOnDelete();
            $table->foreignId('service_id')->constrained()->cascadeOnDelete();
            $table->dateTime('starts_at');
            $table->dateTime('ends_at');
            $table->decimal('price', 10, 2);
            $table->string('status')->default('confirmed');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['provider_id', 'starts_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('appointments');
        Schema::dropIfExists('working_hours');
        Schema::dropIfExists('services');
        Schema::dropIfExists('providers');
    }
};

<?php

use App\Http\Controllers\Api\AppointmentController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProviderController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('register', [AuthController::class, 'register'])->middleware('throttle:10,1');
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:10,1');

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('me', [AuthController::class, 'me']);
        Route::post('logout', [AuthController::class, 'logout']);
    });
});

Route::get('categories', [ProviderController::class, 'categories']);
Route::get('providers', [ProviderController::class, 'index']);
Route::get('providers/{provider}', [ProviderController::class, 'show']);
Route::get('providers/{provider}/slots', [ProviderController::class, 'slots']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('appointments', [AppointmentController::class, 'index']);
    Route::post('appointments', [AppointmentController::class, 'store']);
    Route::post('appointments/{appointment}/cancel', [AppointmentController::class, 'cancel']);

    // Business owners
    Route::get('schedule', [AppointmentController::class, 'schedule']);
    Route::patch('appointments/{appointment}/status', [AppointmentController::class, 'updateStatus']);
});

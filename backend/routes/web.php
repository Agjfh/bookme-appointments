<?php

use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json([
    'name' => 'BookMe API',
    'status' => 'ok',
]));

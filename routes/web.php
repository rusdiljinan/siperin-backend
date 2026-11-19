<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'success' => true,
        'application' => 'SIPERIN',
        'description' => 'Sistem Pengelolaan Inventaris',
        'version' => '1.0.0',
        'status' => 'online',
        'message' => 'SIPERIN Backend is running successfully.',
    ]);
});

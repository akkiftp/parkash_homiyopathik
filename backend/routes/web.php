<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'success' => true,
        'message' => 'Prakash Homeo Hall Clinic Server is running.',
        'api_url' => url('/api'),
        'clinic' => 'Prakash Homeo Hall',
        'doctor' => 'Dr. Navneet Srivastava (B.H.M.S.)',
        'status' => 'online',
    ]);
});

<?php

use App\Http\Controllers\AppointmentController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ClinicController;
use App\Http\Controllers\DoctorController;
use App\Http\Controllers\ReceptionController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Root API Health & Clinic Info
|--------------------------------------------------------------------------
*/
Route::get('/', function () {
    return response()->json([
        'success' => true,
        'message' => 'Prakash Homeo Hall Clinic API is live and operational.',
        'clinic' => 'Prakash Homeo Hall',
        'doctor' => 'Dr. Om Prakash (B.H.M.S.)',
        'status' => 'online',
        'timezone' => 'Asia/Kolkata',
        'endpoints' => [
            'clinic' => '/api/clinic',
            'slots' => '/api/slots?date=' . now()->format('Y-m-d'),
            'live_queue' => '/api/queue/live',
            'login' => '/api/login',
        ],
    ]);
});

/*
|--------------------------------------------------------------------------
| Public Clinic & Patient APIs
|--------------------------------------------------------------------------
*/
Route::get('/clinic', [ClinicController::class, 'clinicInfo']);
Route::get('/slots', [ClinicController::class, 'getSlots']);
Route::post('/appointments', [AppointmentController::class, 'store'])->middleware('throttle:30,1');
Route::get('/appointments/{booking_code}', [AppointmentController::class, 'show']);
Route::get('/queue/live', [ClinicController::class, 'liveQueue']);
Route::post('/appointments/{booking_code}/cancel', [AppointmentController::class, 'cancel']);

/*
|--------------------------------------------------------------------------
| Authentication APIs
|--------------------------------------------------------------------------
*/
Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:10,1');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    /*
    |--------------------------------------------------------------------------
    | Doctor APIs
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:doctor')->prefix('doctor')->group(function () {
        Route::get('/dashboard', [DoctorController::class, 'dashboard']);
        Route::get('/appointments', [DoctorController::class, 'appointments']);
        Route::post('/appointments/{id}/call', [DoctorController::class, 'callPatient']);
        Route::post('/appointments/{id}/start', [DoctorController::class, 'startConsultation']);
        Route::post('/appointments/{id}/complete', [DoctorController::class, 'completeConsultation']);
        Route::post('/appointments/{id}/skip', [DoctorController::class, 'skipPatient']);
        Route::post('/appointments/{id}/no-show', [DoctorController::class, 'markNoShow']);
        Route::post('/queue/pause', [DoctorController::class, 'pauseQueue']);
        Route::post('/queue/resume', [DoctorController::class, 'resumeQueue']);
    });

    /*
    |--------------------------------------------------------------------------
    | Reception APIs
    |--------------------------------------------------------------------------
    */
    Route::middleware('role:reception')->prefix('reception')->group(function () {
        Route::get('/appointments', [ReceptionController::class, 'appointments']);
        Route::post('/walk-in', [ReceptionController::class, 'walkIn']);
        Route::post('/appointments/{id}/check-in', [ReceptionController::class, 'checkIn']);
        Route::post('/appointments/{id}/reschedule', [ReceptionController::class, 'reschedule']);
        Route::post('/appointments/{id}/cancel', [ReceptionController::class, 'cancel']);
        Route::post('/appointments/{id}/no-show', [ReceptionController::class, 'markNoShow']);
    });
});

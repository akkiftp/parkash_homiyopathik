<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use App\Models\ClinicSetting;
use App\Models\DoctorSchedule;
use App\Models\QueueSetting;
use App\Services\SlotService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClinicController extends Controller
{
    protected SlotService $slotService;

    public function __construct(SlotService $slotService)
    {
        $this->slotService = $slotService;
    }

    /**
     * Public Clinic Information & OPD Timings
     */
    public function clinicInfo(): JsonResponse
    {
        $setting = ClinicSetting::first();
        if (!$setting) {
            $setting = ClinicSetting::create([
                'clinic_name' => 'Prakash Homeo Hall',
                'doctor_name' => 'Dr. Om Prakash',
                'qualification' => 'B.H.M.S. (Senior Homeopathic Consultant)',
                'specialization' => 'Classical Homeopathy & Chronic Care',
                'address' => 'Chowk, Chandiyana, Fatehpur, Uttar Pradesh - 212601',
                'phone' => '+91 94150 12345',
                'slot_duration' => 15,
                'timezone' => 'Asia/Kolkata',
            ]);
        }

        $schedules = DoctorSchedule::where('is_active', true)->get()->map(function ($s) {
            return [
                'id' => $s->id,
                'weekday' => $s->weekday,
                'session_name' => $s->session_name,
                'start_time' => Carbon::parse($s->start_time)->format('g:i A'),
                'end_time' => Carbon::parse($s->end_time)->format('g:i A'),
            ];
        });

        $queueSetting = QueueSetting::first();

        return response()->json([
            'success' => true,
            'message' => 'Clinic details fetched successfully.',
            'data' => [
                'clinic_name' => $setting->clinic_name,
                'doctor_name' => $setting->doctor_name,
                'qualification' => $setting->qualification,
                'specialization' => $setting->specialization,
                'address' => $setting->address,
                'phone' => $setting->phone,
                'slot_duration' => $setting->slot_duration,
                'timezone' => $setting->timezone,
                'opd_timings' => $schedules,
                'queue_paused' => $queueSetting ? (bool)$queueSetting->queue_paused : false,
            ],
        ]);
    }

    /**
     * Get available appointment slots for a selected date
     */
    public function getSlots(Request $request): JsonResponse
    {
        $request->validate([
            'date' => 'required|date_format:Y-m-d',
        ]);

        $dateString = $request->input('date');
        $todayStr = Carbon::today('Asia/Kolkata')->format('Y-m-d');

        // Past dates are not allowed
        if ($dateString < $todayStr) {
            return response()->json([
                'success' => false,
                'message' => 'Past dates are not available for booking.',
                'errors' => [
                    'date' => ['Please select today or a future date.'],
                ],
            ], 422);
        }

        $slots = $this->slotService->getAvailableSlots($dateString);

        return response()->json([
            'success' => true,
            'message' => 'Available slots retrieved successfully.',
            'data' => [
                'date' => $dateString,
                'total_available' => count($slots),
                'slots' => $slots,
            ],
        ]);
    }

    /**
     * Live Public Queue Status (for Clinic TV Display and Patient App)
     * No sensitive patient information returned.
     */
    public function liveQueue(): JsonResponse
    {
        $setting = ClinicSetting::first();
        $queueSetting = QueueSetting::first();
        $isPaused = $queueSetting ? (bool)$queueSetting->queue_paused : false;

        $todayStr = Carbon::today('Asia/Kolkata')->format('Y-m-d');

        // Active appointment in consultation
        $inConsultation = Appointment::whereHas('slot', function ($q) use ($todayStr) {
                $q->where('slot_date', $todayStr);
            })
            ->where('status', 'in_consultation')
            ->first();

        // Active appointment called
        $called = Appointment::whereHas('slot', function ($q) use ($todayStr) {
                $q->where('slot_date', $todayStr);
            })
            ->where('status', 'called')
            ->first();

        $currentToken = null;
        $currentPatientStatus = null;
        if ($inConsultation) {
            $currentToken = $inConsultation->token_number;
            $currentPatientStatus = 'in_consultation';
        } elseif ($called) {
            $currentToken = $called->token_number;
            $currentPatientStatus = 'called';
        }

        // Waiting appointments (checked_in or waiting)
        $waitingQuery = Appointment::whereHas('slot', function ($q) use ($todayStr) {
                $q->where('slot_date', $todayStr);
            })
            ->whereIn('status', ['checked_in', 'waiting'])
            ->orderBy('token_number', 'asc');

        $waitingCount = (clone $waitingQuery)->count();
        $waitingTokens = (clone $waitingQuery)->pluck('token_number')->filter()->values();
        $nextToken = $waitingTokens->first();

        $completedCount = Appointment::whereHas('slot', function ($q) use ($todayStr) {
                $q->where('slot_date', $todayStr);
            })
            ->where('status', 'completed')
            ->count();

        $totalToday = Appointment::whereHas('slot', function ($q) use ($todayStr) {
                $q->where('slot_date', $todayStr);
            })
            ->whereNotIn('status', ['cancelled'])
            ->count();

        return response()->json([
            'success' => true,
            'message' => 'Live queue status fetched.',
            'data' => [
                'clinic_name' => $setting ? $setting->clinic_name : 'Prakash Homeo Hall',
                'doctor_name' => $setting ? $setting->doctor_name : 'Dr. Om Prakash',
                'specialization' => $setting ? $setting->specialization : 'Classical Homeopathy',
                'queue_paused' => $isPaused,
                'current_token' => $currentToken,
                'current_patient_status' => $currentPatientStatus,
                'next_token' => $nextToken,
                'waiting_count' => $waitingCount,
                'waiting_tokens' => $waitingTokens,
                'completed_count' => $completedCount,
                'total_today' => $totalToday,
                'timestamp' => Carbon::now('Asia/Kolkata')->toIso8601String(),
            ],
        ]);
    }
}

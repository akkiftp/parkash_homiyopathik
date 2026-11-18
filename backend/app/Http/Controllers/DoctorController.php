<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use App\Models\QueueSetting;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DoctorController extends Controller
{
    /**
     * Doctor Dashboard Summary & Current Queue State
     */
    public function dashboard(Request $request): JsonResponse
    {
        $selectedDate = $request->input('date', Carbon::today('Asia/Kolkata')->format('Y-m-d'));
        $todayStr = Carbon::today('Asia/Kolkata')->format('Y-m-d');

        $queueSetting = QueueSetting::first();
        $isPaused = $queueSetting ? (bool)$queueSetting->queue_paused : false;

        $todayAppointments = Appointment::with('slot')
            ->whereHas('slot', function ($q) use ($selectedDate) {
                $q->where('slot_date', $selectedDate);
            })
            ->orderBy('token_number', 'asc')
            ->get();

        $totalToday = $todayAppointments->count();
        $completedToday = $todayAppointments->where('status', 'completed')->count();
        $waitingPatients = $todayAppointments->whereIn('status', ['checked_in', 'waiting'])->values();
        $upcomingCount = $todayAppointments->where('status', 'booked')->count();
        $cancelledToday = $todayAppointments->where('status', 'cancelled')->count();

        // Currently in consultation
        $currentPatient = $todayAppointments->where('status', 'in_consultation')->first();

        // Currently called
        $calledPatient = $todayAppointments->where('status', 'called')->first();

        $user = auth()->user();
        $setting = \App\Models\ClinicSetting::first();

        return response()->json([
            'success' => true,
            'message' => 'Doctor dashboard data loaded successfully.',
            'data' => [
                'doctor_name' => $user?->name ?? ($setting?->doctor_name ?? 'Dr. Navneet Srivastava'),
                'doctor_email' => $user?->email ?? 'doctor@prakashhomeo.com',
                'clinic_name' => $setting?->clinic_name ?? 'Prakash Homeo Hall',
                'qualification' => $setting?->qualification ?? 'B.H.M.S.',
                'specialization' => $setting?->specialization ?? 'Classical Homeopathy & Chronic Care',
                'selected_date' => $selectedDate,
                'is_today' => ($selectedDate === $todayStr),
                'summary' => [
                    'total_today' => $totalToday,
                    'completed_today' => $completedToday,
                    'waiting_count' => $waitingPatients->count(),
                    'upcoming_count' => $upcomingCount,
                    'cancelled_count' => $cancelledToday,
                    'queue_paused' => $isPaused,
                ],
                'queue_paused' => $isPaused,
                'current_patient' => $currentPatient ? $this->formatAppointment($currentPatient) : null,
                'called_patient' => $calledPatient ? $this->formatAppointment($calledPatient) : null,
                'waiting_list' => $waitingPatients->map(fn($a) => $this->formatAppointment($a)),
                'all_today' => $todayAppointments->map(fn($a) => $this->formatAppointment($a)),
            ],
        ]);
    }

    /**
     * Today's Appointments with optional filters
     */
    public function appointments(Request $request): JsonResponse
    {
        $date = $request->input('date', Carbon::today('Asia/Kolkata')->format('Y-m-d'));
        $status = $request->input('status');

        $query = Appointment::with('slot')
            ->whereHas('slot', function ($q) use ($date) {
                $q->where('slot_date', $date);
            });

        if ($status) {
            $query->where('status', $status);
        }

        $appointments = $query->orderBy('token_number', 'asc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Appointments fetched successfully.',
            'data' => [
                'date' => $date,
                'total' => $appointments->count(),
                'appointments' => $appointments->map(fn($a) => $this->formatAppointment($a)),
            ],
        ]);
    }

    /**
     * Call Patient
     * Only checked-in, waiting, or skipped patients can be called.
     * Blocked if queue is paused.
     */
    public function callPatient(int $id): JsonResponse
    {
        $queueSetting = QueueSetting::first();
        if ($queueSetting && $queueSetting->queue_paused) {
            return response()->json([
                'success' => false,
                'message' => 'Queue is currently paused. Please resume the queue before calling patients.',
            ], 422);
        }

        $appointment = Appointment::with('slot')->find($id);
        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        // Doctor can only call checked-in or waiting or skipped patients
        if (!in_array($appointment->status, ['checked_in', 'waiting', 'skipped'])) {
            return response()->json([
                'success' => false,
                'message' => 'Only checked-in or waiting patients can be called. Current status: ' . $appointment->status,
            ], 422);
        }

        DB::transaction(function () use ($appointment) {
            $oldStatus = $appointment->status;
            $appointment->status = 'called';
            $appointment->called_at = Carbon::now('Asia/Kolkata');
            $appointment->save();

            $appointment->logStatusChange($oldStatus, 'called', auth()->user()?->name ?? 'Doctor');
        });

        return response()->json([
            'success' => true,
            'message' => 'Patient ' . $appointment->patient_name . ' (Token #' . $appointment->token_number . ') has been called.',
            'data' => $this->formatAppointment($appointment),
        ]);
    }

    /**
     * Check-in Patient (Doctor Desk direct action)
     */
    public function checkIn(int $id): JsonResponse
    {
        $appointment = Appointment::with('slot')->find($id);
        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        DB::transaction(function () use ($appointment) {
            $oldStatus = $appointment->status;
            $appointment->status = 'checked_in';
            $appointment->checked_in_at = Carbon::now('Asia/Kolkata');
            $appointment->save();

            $appointment->logStatusChange($oldStatus, 'checked_in', auth()->user()?->name ?? 'Doctor');
        });

        return response()->json([
            'success' => true,
            'message' => 'Patient ' . $appointment->patient_name . ' has been checked in and added to waiting queue.',
            'data' => $this->formatAppointment($appointment),
        ]);
    }

    /**
     * Start Consultation
     * Only 1 appointment can be in consultation at a time.
     */
    public function startConsultation(int $id): JsonResponse
    {
        $appointment = Appointment::with('slot')->find($id);
        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        // Check if another appointment is already in consultation today
        $todayStr = Carbon::today('Asia/Kolkata')->format('Y-m-d');
        $existingActive = Appointment::whereHas('slot', function ($q) use ($todayStr) {
                $q->where('slot_date', $todayStr);
            })
            ->where('status', 'in_consultation')
            ->where('id', '!=', $id)
            ->first();

        if ($existingActive) {
            return response()->json([
                'success' => false,
                'message' => 'Another patient (Token #' . $existingActive->token_number . ' - ' . $existingActive->patient_name . ') is currently in consultation. Please complete or skip that consultation first.',
            ], 422);
        }

        DB::transaction(function () use ($appointment) {
            $oldStatus = $appointment->status;
            $appointment->status = 'in_consultation';
            $appointment->started_at = Carbon::now('Asia/Kolkata');
            $appointment->save();

            $appointment->logStatusChange($oldStatus, 'in_consultation', auth()->user()?->name ?? 'Doctor');
        });

        return response()->json([
            'success' => true,
            'message' => 'Consultation started for ' . $appointment->patient_name . '.',
            'data' => $this->formatAppointment($appointment),
        ]);
    }

    /**
     * Complete Consultation
     * Does not automatically start next patient.
     */
    public function completeConsultation(int $id): JsonResponse
    {
        $appointment = Appointment::with('slot')->find($id);
        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        DB::transaction(function () use ($appointment) {
            $oldStatus = $appointment->status;
            $appointment->status = 'completed';
            $appointment->completed_at = Carbon::now('Asia/Kolkata');
            $appointment->save();

            $appointment->logStatusChange($oldStatus, 'completed', auth()->user()?->name ?? 'Doctor');
        });

        return response()->json([
            'success' => true,
            'message' => 'Consultation completed for ' . $appointment->patient_name . '. Please call the next patient.',
            'data' => $this->formatAppointment($appointment),
        ]);
    }

    /**
     * Skip Patient
     */
    public function skipPatient(int $id): JsonResponse
    {
        $appointment = Appointment::with('slot')->find($id);
        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        DB::transaction(function () use ($appointment) {
            $oldStatus = $appointment->status;
            $appointment->status = 'skipped';
            $appointment->save();

            $appointment->logStatusChange($oldStatus, 'skipped', auth()->user()?->name ?? 'Doctor');
        });

        return response()->json([
            'success' => true,
            'message' => 'Patient ' . $appointment->patient_name . ' has been skipped.',
            'data' => $this->formatAppointment($appointment),
        ]);
    }

    /**
     * Mark No Show
     */
    public function markNoShow(int $id): JsonResponse
    {
        $appointment = Appointment::with('slot')->find($id);
        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        DB::transaction(function () use ($appointment) {
            $oldStatus = $appointment->status;
            $appointment->status = 'no_show';
            $appointment->save();

            $appointment->logStatusChange($oldStatus, 'no_show', auth()->user()?->name ?? 'Doctor');
        });

        return response()->json([
            'success' => true,
            'message' => 'Patient ' . $appointment->patient_name . ' marked as No-Show.',
            'data' => $this->formatAppointment($appointment),
        ]);
    }

    /**
     * Pause Queue
     */
    public function pauseQueue(): JsonResponse
    {
        $queueSetting = QueueSetting::firstOrCreate(['id' => 1]);
        $queueSetting->update([
            'queue_paused' => true,
            'paused_at' => Carbon::now('Asia/Kolkata'),
            'updated_by' => auth()->id(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Queue has been paused. Call actions are now blocked.',
            'data' => [
                'queue_paused' => true,
                'paused_at' => $queueSetting->paused_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * Resume Queue
     */
    public function resumeQueue(): JsonResponse
    {
        $queueSetting = QueueSetting::firstOrCreate(['id' => 1]);
        $queueSetting->update([
            'queue_paused' => false,
            'paused_at' => null,
            'updated_by' => auth()->id(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Queue has been resumed.',
            'data' => [
                'queue_paused' => false,
            ],
        ]);
    }

    private function formatAppointment(Appointment $a): array
    {
        return [
            'id' => $a->id,
            'booking_id' => $a->booking_code,
            'patient_name' => $a->patient_name,
            'mobile' => $a->mobile,
            'token_number' => $a->token_number,
            'status' => $a->status,
            'booking_source' => $a->booking_source,
            'slot_date' => $a->slot ? Carbon::parse($a->slot->slot_date)->format('Y-m-d') : null,
            'appointment_time' => $a->slot ? Carbon::parse($a->slot->start_time)->format('g:i A') : null,
            'checked_in_at' => $a->checked_in_at?->format('g:i A'),
            'called_at' => $a->called_at?->format('g:i A'),
            'started_at' => $a->started_at?->format('g:i A'),
            'completed_at' => $a->completed_at?->format('g:i A'),
            'notes' => $a->notes,
        ];
    }
}

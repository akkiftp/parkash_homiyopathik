<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use App\Models\ClinicSetting;
use App\Models\ClinicSlot;
use App\Models\QueueSetting;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AppointmentController extends Controller
{
    /**
     * Book an Appointment (Public)
     * Utilizes DB Transaction & Row Locking to prevent double bookings.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'patient_name' => 'required|string|min:2|max:100',
            'mobile' => ['required', 'string', 'regex:/^[6-9]\d{9}$/'],
            'clinic_slot_id' => 'required|integer|exists:clinic_slots,id',
            'notes' => 'nullable|string|max:500',
        ], [
            'mobile.regex' => 'Please enter a valid 10-digit Indian mobile number.',
            'clinic_slot_id.exists' => 'Selected slot is invalid or no longer exists.',
        ]);

        $setting = ClinicSetting::first();
        $slotDuration = $setting ? $setting->slot_duration : 15;
        $now = Carbon::now('Asia/Kolkata');

        try {
            $appointment = DB::transaction(function () use ($validated, $now) {
                // Lock slot row for update
                $slot = ClinicSlot::where('id', $validated['clinic_slot_id'])
                    ->lockForUpdate()
                    ->first();

                if (!$slot || !$slot->is_available) {
                    abort(response()->json([
                        'success' => false,
                        'message' => 'Selected slot is already booked. Please choose another slot.',
                        'errors' => [
                            'slot_id' => ['This slot is no longer available.'],
                        ],
                    ], 422));
                }

                $slotDate = Carbon::parse($slot->slot_date);
                $isToday = $slotDate->isSameDay($now);

                // Prevent booking past time slots today
                if ($isToday) {
                    $slotTime = Carbon::parse($slot->slot_date . ' ' . $slot->start_time, 'Asia/Kolkata');
                    if ($slotTime->lt($now)) {
                        abort(response()->json([
                            'success' => false,
                            'message' => 'Cannot book a past time slot. Please select an upcoming slot.',
                            'errors' => [
                                'slot_id' => ['This slot time has already passed.'],
                            ],
                        ], 422));
                    }
                }

                // Generate Sequential Daily Token for the date
                $maxToken = Appointment::whereHas('slot', function ($q) use ($slot) {
                    $q->where('slot_date', $slot->slot_date);
                })->max('token_number') ?? 0;
                $tokenNumber = $maxToken + 1;

                // Generate Unique Booking Code e.g. PHH-261118-005
                $dateCode = Carbon::parse($slot->slot_date)->format('ymd');
                $randomSuffix = strtoupper(Str::random(3));
                $bookingCode = sprintf('PHH-%s-%03d%s', $dateCode, $tokenNumber, $randomSuffix);

                // Create appointment record
                $appointment = Appointment::create([
                    'booking_code' => $bookingCode,
                    'patient_name' => trim($validated['patient_name']),
                    'mobile' => trim($validated['mobile']),
                    'clinic_slot_id' => $slot->id,
                    'booking_source' => 'online',
                    'status' => 'booked',
                    'token_number' => $tokenNumber,
                    'notes' => $validated['notes'] ?? null,
                ]);

                // Mark slot as unavailable
                $slot->update(['is_available' => false]);

                // Log audit trail
                $appointment->logStatusChange(null, 'booked', 'Patient');

                return $appointment;
            });

            $appointment->load('slot');
            $slot = $appointment->slot;

            return response()->json([
                'success' => true,
                'message' => 'Appointment booked successfully.',
                'data' => [
                    'booking_id' => $appointment->booking_code,
                    'patient_name' => $appointment->patient_name,
                    'mobile' => $appointment->mobile,
                    'appointment_date' => Carbon::parse($slot->slot_date)->format('Y-m-d'),
                    'appointment_time' => Carbon::parse($slot->start_time)->format('g:i A'),
                    'slot_start' => substr($slot->start_time, 0, 5),
                    'token_number' => $appointment->token_number,
                    'status' => $appointment->status,
                    'clinic_name' => $setting ? $setting->clinic_name : 'Prakash Homeo Hall',
                    'doctor_name' => $setting ? $setting->doctor_name : 'Dr. Om Prakash',
                    'address' => $setting ? $setting->address : 'Chowk, Chandiyana, Fatehpur, Uttar Pradesh',
                ],
            ], 201);

        } catch (\Illuminate\Http\Exceptions\HttpResponseException $e) {
            return $e->getResponse();
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
                'errors' => $e->errors(),
            ], 422);
        } catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) {
            return $e->getResponse();
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to book appointment: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get Appointment Details & Live Tracking Status
     */
    public function show(string $bookingCode): JsonResponse
    {
        $appointment = Appointment::with('slot')->where('booking_code', $bookingCode)->first();

        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment with booking ID "' . $bookingCode . '" not found.',
            ], 404);
        }

        $setting = ClinicSetting::first();
        $slotDuration = $setting ? $setting->slot_duration : 15;
        $slotDate = Carbon::parse($appointment->slot->slot_date)->format('Y-m-d');
        $todayStr = Carbon::today('Asia/Kolkata')->format('Y-m-d');
        $isToday = ($slotDate === $todayStr);

        $queueSetting = QueueSetting::first();
        $queuePaused = $queueSetting ? (bool)$queueSetting->queue_paused : false;

        // Current running token today
        $activeAppointment = Appointment::whereHas('slot', function ($q) use ($todayStr) {
                $q->where('slot_date', $todayStr);
            })
            ->whereIn('status', ['in_consultation', 'called'])
            ->first();

        $currentRunningToken = $activeAppointment ? $activeAppointment->token_number : null;

        // Calculate queue position if checked_in or waiting
        $patientsAhead = 0;
        $queuePosition = null;
        $estimatedWaitMinutes = null;

        if ($isToday && in_array($appointment->status, ['checked_in', 'waiting'])) {
            $patientsAhead = Appointment::whereHas('slot', function ($q) use ($todayStr) {
                    $q->where('slot_date', $todayStr);
                })
                ->whereIn('status', ['in_consultation', 'called', 'checked_in', 'waiting'])
                ->where('token_number', '<', $appointment->token_number)
                ->count();

            $queuePosition = $patientsAhead + 1;
            $estimatedWaitMinutes = $patientsAhead * $slotDuration;
        }

        return response()->json([
            'success' => true,
            'message' => 'Appointment details fetched successfully.',
            'data' => [
                'booking_id' => $appointment->booking_code,
                'patient_name' => $appointment->patient_name,
                'mobile' => $appointment->mobile,
                'token_number' => $appointment->token_number,
                'appointment_date' => $slotDate,
                'appointment_time' => Carbon::parse($appointment->slot->start_time)->format('g:i A'),
                'slot_start' => substr($appointment->slot->start_time, 0, 5),
                'slot_end' => substr($appointment->slot->end_time, 0, 5),
                'status' => $appointment->status,
                'is_today' => $isToday,
                'queue_paused' => $queuePaused,
                'current_running_token' => $currentRunningToken,
                'queue_position' => $queuePosition,
                'patients_ahead' => $patientsAhead,
                'estimated_wait_minutes' => $estimatedWaitMinutes,
                'clinic_name' => $setting ? $setting->clinic_name : 'Prakash Homeo Hall',
                'doctor_name' => $setting ? $setting->doctor_name : 'Dr. Om Prakash',
                'address' => $setting ? $setting->address : 'Chowk, Chandiyana, Fatehpur, Uttar Pradesh',
                'checked_in_at' => $appointment->checked_in_at?->format('g:i A'),
                'called_at' => $appointment->called_at?->format('g:i A'),
                'started_at' => $appointment->started_at?->format('g:i A'),
                'completed_at' => $appointment->completed_at?->format('g:i A'),
            ],
        ]);
    }

    /**
     * Cancel Appointment with Mobile Verification
     */
    public function cancel(Request $request, string $bookingCode): JsonResponse
    {
        $request->validate([
            'mobile' => 'required|string',
            'reason' => 'nullable|string|max:255',
        ]);

        $appointment = Appointment::with('slot')->where('booking_code', $bookingCode)->first();

        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        // Security verification: verify provided mobile number matches the booking mobile
        $cleanMobile = preg_replace('/[^0-9]/', '', $request->input('mobile'));
        $storedMobile = preg_replace('/[^0-9]/', '', $appointment->mobile);

        if (!str_ends_with($storedMobile, $cleanMobile) && !str_ends_with($cleanMobile, $storedMobile)) {
            return response()->json([
                'success' => false,
                'message' => 'Verification failed. Mobile number does not match this booking.',
                'errors' => [
                    'mobile' => ['The provided mobile number does not match this booking.'],
                ],
            ], 403);
        }

        // Cannot cancel if already completed, in_consultation, or cancelled
        if (in_array($appointment->status, ['completed', 'in_consultation'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot cancel an appointment that is already ' . str_replace('_', ' ', $appointment->status) . '.',
            ], 422);
        }

        if ($appointment->status === 'cancelled') {
            return response()->json([
                'success' => false,
                'message' => 'This appointment is already cancelled.',
            ], 422);
        }

        DB::transaction(function () use ($appointment, $request) {
            $oldStatus = $appointment->status;
            $appointment->status = 'cancelled';
            $appointment->cancellation_reason = $request->input('reason', 'Cancelled by patient');
            $appointment->save();

            // Release slot for others to book
            if ($appointment->slot) {
                $appointment->slot->update(['is_available' => true]);
            }

            $appointment->logStatusChange($oldStatus, 'cancelled', 'Patient');
        });

        return response()->json([
            'success' => true,
            'message' => 'Appointment cancelled successfully. The time slot is now released.',
            'data' => [
                'booking_id' => $appointment->booking_code,
                'status' => 'cancelled',
            ],
        ]);
    }
}

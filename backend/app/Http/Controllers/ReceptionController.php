<?php

namespace App\Http\Controllers;

use App\Models\Appointment;
use App\Models\ClinicSlot;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ReceptionController extends Controller
{
    /**
     * Search and list appointments for Reception desk
     */
    public function appointments(Request $request): JsonResponse
    {
        $date = $request->input('date', Carbon::today('Asia/Kolkata')->format('Y-m-d'));
        $search = $request->input('search');
        $status = $request->input('status');

        $query = Appointment::with('slot');

        if ($date) {
            $query->whereHas('slot', function ($q) use ($date) {
                $q->where('slot_date', $date);
            });
        }

        if ($status) {
            $query->where('status', $status);
        }

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('patient_name', 'like', "%{$search}%")
                  ->orWhere('mobile', 'like', "%{$search}%")
                  ->orWhere('booking_code', 'like', "%{$search}%");
            });
        }

        $appointments = $query->orderBy('token_number', 'asc')->get();

        return response()->json([
            'success' => true,
            'message' => 'Reception appointments loaded.',
            'data' => [
                'date' => $date,
                'total' => $appointments->count(),
                'appointments' => $appointments->map(fn($a) => $this->formatAppointment($a)),
            ],
        ]);
    }

    /**
     * Walk-in Patient Booking
     * Uses the exact same slot availability system and row locking as online booking.
     * Status is set to 'checked_in' immediately so patient appears on Doctor's waiting list.
     */
    public function walkIn(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'patient_name' => 'required|string|min:2|max:100',
            'mobile' => ['required', 'string', 'regex:/^[6-9]\d{9}$/'],
            'clinic_slot_id' => 'required|integer|exists:clinic_slots,id',
            'notes' => 'nullable|string|max:500',
        ]);

        $now = Carbon::now('Asia/Kolkata');

        try {
            $appointment = DB::transaction(function () use ($validated, $now) {
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

                // Generate Sequential Daily Token
                $maxToken = Appointment::whereHas('slot', function ($q) use ($slot) {
                    $q->where('slot_date', $slot->slot_date);
                })->max('token_number') ?? 0;
                $tokenNumber = $maxToken + 1;

                $dateCode = Carbon::parse($slot->slot_date)->format('ymd');
                $randomSuffix = strtoupper(Str::random(3));
                $bookingCode = sprintf('PHH-%s-%03d%s', $dateCode, $tokenNumber, $randomSuffix);

                $appointment = Appointment::create([
                    'booking_code' => $bookingCode,
                    'patient_name' => trim($validated['patient_name']),
                    'mobile' => trim($validated['mobile']),
                    'clinic_slot_id' => $slot->id,
                    'booking_source' => 'walk_in',
                    'status' => 'checked_in',
                    'token_number' => $tokenNumber,
                    'checked_in_at' => $now,
                    'notes' => $validated['notes'] ?? null,
                ]);

                $slot->update(['is_available' => false]);

                $appointment->logStatusChange(null, 'booked', auth()->user()?->name ?? 'Reception Desk');
                $appointment->logStatusChange('booked', 'checked_in', auth()->user()?->name ?? 'Reception Desk');

                return $appointment;
            });

            $appointment->load('slot');

            return response()->json([
                'success' => true,
                'message' => 'Walk-in patient registered and checked in successfully.',
                'data' => $this->formatAppointment($appointment),
            ], 201);

        } catch (\Illuminate\Http\Exceptions\HttpResponseException $e) {
            return $e->getResponse();
        } catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) {
            return $e->getResponse();
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to register walk-in patient: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Check-in Patient
     * Changes status from 'booked' to 'checked_in' so patient moves to Doctor's queue.
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

        if ($appointment->status === 'checked_in') {
            return response()->json([
                'success' => false,
                'message' => 'Patient is already checked in.',
            ], 422);
        }

        if (in_array($appointment->status, ['completed', 'cancelled', 'in_consultation'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot check in an appointment that is ' . str_replace('_', ' ', $appointment->status) . '.',
            ], 422);
        }

        DB::transaction(function () use ($appointment) {
            $oldStatus = $appointment->status;
            $appointment->status = 'checked_in';
            $appointment->checked_in_at = Carbon::now('Asia/Kolkata');
            $appointment->save();

            $appointment->logStatusChange($oldStatus, 'checked_in', auth()->user()?->name ?? 'Reception Desk');
        });

        return response()->json([
            'success' => true,
            'message' => 'Patient ' . $appointment->patient_name . ' checked in successfully.',
            'data' => $this->formatAppointment($appointment),
        ]);
    }

    /**
     * Reschedule Appointment
     */
    public function reschedule(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'new_clinic_slot_id' => 'required|integer|exists:clinic_slots,id',
        ]);

        $appointment = Appointment::with('slot')->find($id);
        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        if (in_array($appointment->status, ['completed', 'in_consultation', 'cancelled'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot reschedule an appointment that is already ' . str_replace('_', ' ', $appointment->status) . '.',
            ], 422);
        }

        try {
            DB::transaction(function () use ($appointment, $request) {
                // Free old slot
                if ($appointment->slot) {
                    $appointment->slot->update(['is_available' => true]);
                }

                // Lock new slot
                $newSlot = ClinicSlot::where('id', $request->input('new_clinic_slot_id'))
                    ->lockForUpdate()
                    ->first();

                if (!$newSlot || !$newSlot->is_available) {
                    abort(response()->json([
                        'success' => false,
                        'message' => 'The selected new slot is no longer available.',
                    ], 422));
                }

                $newSlot->update(['is_available' => false]);

                $oldStatus = $appointment->status;
                $appointment->clinic_slot_id = $newSlot->id;
                $appointment->status = 'booked';
                $appointment->save();

                $appointment->logStatusChange($oldStatus, 'rescheduled', auth()->user()?->name ?? 'Reception Desk');
            });

            $appointment->load('slot');

            return response()->json([
                'success' => true,
                'message' => 'Appointment rescheduled successfully.',
                'data' => $this->formatAppointment($appointment),
            ]);

        } catch (\Illuminate\Http\Exceptions\HttpResponseException $e) {
            return $e->getResponse();
        } catch (\Symfony\Component\HttpKernel\Exception\HttpException $e) {
            return $e->getResponse();
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Reschedule failed: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Cancel Appointment from Reception
     */
    public function cancel(Request $request, int $id): JsonResponse
    {
        $appointment = Appointment::with('slot')->find($id);
        if (!$appointment) {
            return response()->json([
                'success' => false,
                'message' => 'Appointment not found.',
            ], 404);
        }

        if (in_array($appointment->status, ['completed', 'cancelled'])) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot cancel an appointment that is ' . $appointment->status . '.',
            ], 422);
        }

        DB::transaction(function () use ($appointment, $request) {
            $oldStatus = $appointment->status;
            $appointment->status = 'cancelled';
            $appointment->cancellation_reason = $request->input('reason', 'Cancelled at reception');
            $appointment->save();

            if ($appointment->slot) {
                $appointment->slot->update(['is_available' => true]);
            }

            $appointment->logStatusChange($oldStatus, 'cancelled', auth()->user()?->name ?? 'Reception Desk');
        });

        return response()->json([
            'success' => true,
            'message' => 'Appointment cancelled successfully.',
            'data' => $this->formatAppointment($appointment),
        ]);
    }

    /**
     * Mark No Show from Reception
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

            $appointment->logStatusChange($oldStatus, 'no_show', auth()->user()?->name ?? 'Reception Desk');
        });

        return response()->json([
            'success' => true,
            'message' => 'Patient ' . $appointment->patient_name . ' marked as No Show.',
            'data' => $this->formatAppointment($appointment),
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
            'clinic_slot_id' => $a->clinic_slot_id,
            'checked_in_at' => $a->checked_in_at?->format('g:i A'),
            'called_at' => $a->called_at?->format('g:i A'),
            'started_at' => $a->started_at?->format('g:i A'),
            'completed_at' => $a->completed_at?->format('g:i A'),
            'notes' => $a->notes,
        ];
    }
}

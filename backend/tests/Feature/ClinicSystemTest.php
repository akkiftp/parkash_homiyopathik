<?php

namespace Tests\Feature;

use App\Models\Appointment;
use App\Models\ClinicSlot;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ClinicSystemTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed();
    }

    /**
     * Test 1: Public Clinic info API returns correct clinic details
     */
    public function test_clinic_info_returns_correct_details(): void
    {
        $response = $this->getJson('/api/clinic');
        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'data' => [
                    'clinic_name' => 'Prakash Homeo Hall',
                    'doctor_name' => 'Dr. Navneet Srivastava',
                ],
            ]);
    }

    /**
     * Test 2: Available slots can be retrieved for today and tomorrow
     */
    public function test_available_slots_retrieval(): void
    {
        $tomorrow = Carbon::tomorrow('Asia/Kolkata')->format('Y-m-d');
        $response = $this->getJson('/api/slots?date=' . $tomorrow);
        $response->assertStatus(200)
            ->assertJson(['success' => true]);

        $slots = $response->json('data.slots');
        $this->assertNotEmpty($slots);
    }

    /**
     * Test 3: Patient successfully books an appointment
     */
    public function test_patient_can_book_appointment(): void
    {
        $tomorrow = Carbon::tomorrow('Asia/Kolkata')->format('Y-m-d');
        $slot = ClinicSlot::where('slot_date', $tomorrow)->where('is_available', true)->first();

        $response = $this->postJson('/api/appointments', [
            'patient_name' => 'Ankit Kumar',
            'mobile' => '9876543210',
            'clinic_slot_id' => $slot->id,
            'notes' => 'Headache and fatigue',
        ]);

        $response->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'patient_name' => 'Ankit Kumar',
                    'status' => 'booked',
                ],
            ]);

        // Verify slot is now unavailable
        $this->assertFalse((bool)$slot->fresh()->is_available);
    }

    /**
     * Test 4: Same slot cannot be double booked
     */
    public function test_same_slot_cannot_be_double_booked(): void
    {
        $tomorrow = Carbon::tomorrow('Asia/Kolkata')->format('Y-m-d');
        $slot = ClinicSlot::where('slot_date', $tomorrow)->where('is_available', true)->first();

        // First booking succeeds
        $res1 = $this->postJson('/api/appointments', [
            'patient_name' => 'Patient One',
            'mobile' => '9876543210',
            'clinic_slot_id' => $slot->id,
        ]);
        $res1->assertStatus(201);

        // Second booking on same slot fails
        $res2 = $this->postJson('/api/appointments', [
            'patient_name' => 'Patient Two',
            'mobile' => '9876543211',
            'clinic_slot_id' => $slot->id,
        ]);
        $res2->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    /**
     * Test 5: Unauthorized user cannot access doctor APIs
     */
    public function test_unauthorized_user_blocked_from_doctor_api(): void
    {
        $response = $this->getJson('/api/doctor/dashboard');
        $response->assertStatus(401);

        // Reception user trying to access doctor dashboard gets 403 Forbidden
        $reception = User::where('role', 'reception')->first();
        $response2 = $this->actingAs($reception, 'sanctum')->getJson('/api/doctor/dashboard');
        $response2->assertStatus(403);
    }

    /**
     * Test 6: Doctor can access dashboard, call, start and complete consultation
     */
    public function test_doctor_workflow(): void
    {
        $doctor = User::where('role', 'doctor')->first();

        // 1. Doctor dashboard
        $res = $this->actingAs($doctor, 'sanctum')->getJson('/api/doctor/dashboard');
        $res->assertStatus(200)->assertJson(['success' => true]);

        // 2. Find a checked-in patient
        $todayStr = Carbon::today('Asia/Kolkata')->format('Y-m-d');
        $patient = Appointment::whereHas('slot', fn($q) => $q->where('slot_date', $todayStr))
            ->where('status', 'checked_in')
            ->first();

        $this->assertNotNull($patient);

        // 3. Call patient
        $callRes = $this->actingAs($doctor, 'sanctum')->postJson("/api/doctor/appointments/{$patient->id}/call");
        $callRes->assertStatus(200);
        $this->assertEquals('called', $patient->fresh()->status);

        // 4. Start consultation
        $startRes = $this->actingAs($doctor, 'sanctum')->postJson("/api/doctor/appointments/{$patient->id}/start");
        $startRes->assertStatus(200);
        $this->assertEquals('in_consultation', $patient->fresh()->status);

        // 5. Complete consultation
        $compRes = $this->actingAs($doctor, 'sanctum')->postJson("/api/doctor/appointments/{$patient->id}/complete");
        $compRes->assertStatus(200);
        $this->assertEquals('completed', $patient->fresh()->status);
    }

    /**
     * Test 7: Doctor pause and resume queue
     */
    public function test_doctor_queue_pause_and_resume(): void
    {
        $doctor = User::where('role', 'doctor')->first();

        // Pause
        $pauseRes = $this->actingAs($doctor, 'sanctum')->postJson('/api/doctor/queue/pause');
        $pauseRes->assertStatus(200);

        // Calling patient when paused should fail
        $todayStr = Carbon::today('Asia/Kolkata')->format('Y-m-d');
        $patient = Appointment::whereHas('slot', fn($q) => $q->where('slot_date', $todayStr))
            ->where('status', 'checked_in')
            ->first();

        if ($patient) {
            $callRes = $this->actingAs($doctor, 'sanctum')->postJson("/api/doctor/appointments/{$patient->id}/call");
            $callRes->assertStatus(422)
                ->assertJson(['success' => false]);
        }

        // Resume
        $resumeRes = $this->actingAs($doctor, 'sanctum')->postJson('/api/doctor/queue/resume');
        $resumeRes->assertStatus(200);
    }

    /**
     * Test 8: Reception walk-in booking and check-in
     */
    public function test_reception_walk_in_and_check_in(): void
    {
        $reception = User::where('role', 'reception')->first();
        $todayStr = Carbon::today('Asia/Kolkata')->format('Y-m-d');
        $slot = ClinicSlot::where('slot_date', $todayStr)->where('is_available', true)->first();

        $res = $this->actingAs($reception, 'sanctum')->postJson('/api/reception/walk-in', [
            'patient_name' => 'Walk-in Patient',
            'mobile' => '9123456789',
            'clinic_slot_id' => $slot->id,
        ]);

        $res->assertStatus(201)
            ->assertJson([
                'success' => true,
                'data' => [
                    'booking_source' => 'walk_in',
                    'status' => 'checked_in',
                ],
            ]);
    }

    /**
     * Test 9: Appointment cancellation requires valid mobile verification
     */
    public function test_appointment_cancellation_verification(): void
    {
        $apt = Appointment::where('status', 'booked')->first();
        $this->assertNotNull($apt);

        // Wrong mobile fails
        $wrongRes = $this->postJson("/api/appointments/{$apt->booking_code}/cancel", [
            'mobile' => '9999999999',
        ]);
        $wrongRes->assertStatus(403);

        // Correct mobile succeeds
        $correctRes = $this->postJson("/api/appointments/{$apt->booking_code}/cancel", [
            'mobile' => $apt->mobile,
            'reason' => 'Change of plans',
        ]);
        $correctRes->assertStatus(200)
            ->assertJson(['success' => true]);

        // Slot is released
        $this->assertTrue((bool)$apt->slot->fresh()->is_available);

        // Appointment status is cancelled but history retained
        $this->assertEquals('cancelled', $apt->fresh()->status);
    }
}

<?php

namespace Database\Seeders;

use App\Models\Appointment;
use App\Models\ClinicSetting;
use App\Models\ClinicSlot;
use App\Models\DoctorSchedule;
use App\Models\QueueSetting;
use App\Models\User;
use App\Services\SlotService;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Seed Users
        $doctor = User::updateOrCreate(
            ['email' => 'doctor@prakashhomeo.com'],
            [
                'name' => 'Dr. Navneet Srivastava',
                'password' => Hash::make('password123'),
                'role' => 'doctor',
            ]
        );

        $reception = User::updateOrCreate(
            ['email' => 'reception@prakashhomeo.com'],
            [
                'name' => 'Reception Desk',
                'password' => Hash::make('password123'),
                'role' => 'reception',
            ]
        );

        $admin = User::updateOrCreate(
            ['email' => 'admin@prakashhomeo.com'],
            [
                'name' => 'Admin Manager',
                'password' => Hash::make('password123'),
                'role' => 'admin',
            ]
        );

        // 2. Seed Clinic Settings
        $setting = ClinicSetting::updateOrCreate(
            ['id' => 1],
            [
                'clinic_name' => 'Prakash Homeo Hall',
                'doctor_name' => 'Dr. Navneet Srivastava',
                'qualification' => 'B.H.M.S. (Senior Homeopathic Consultant)',
                'specialization' => 'Classical Homeopathy & Chronic Care',
                'address' => 'Chowk, Chandiyana, Fatehpur, Uttar Pradesh - 212601',
                'phone' => '+91 94150 12345',
                'slot_duration' => 15,
                'timezone' => 'Asia/Kolkata',
            ]
        );

        // 3. Seed Doctor Schedules
        DoctorSchedule::updateOrCreate(
            ['session_name' => 'Morning OPD'],
            [
                'weekday' => 'all',
                'start_time' => '10:00:00',
                'end_time' => '13:00:00',
                'is_active' => true,
            ]
        );

        DoctorSchedule::updateOrCreate(
            ['session_name' => 'Evening OPD'],
            [
                'weekday' => 'all',
                'start_time' => '17:00:00',
                'end_time' => '20:00:00',
                'is_active' => true,
            ]
        );

        // 4. Seed Queue Settings
        QueueSetting::firstOrCreate(
            ['id' => 1],
            [
                'queue_paused' => false,
                'paused_at' => null,
                'updated_by' => $doctor->id,
            ]
        );

        // 5. Generate Slots for Today + 7 days
        $slotService = new SlotService();
        $today = Carbon::today('Asia/Kolkata');

        for ($i = 0; $i <= 7; $i++) {
            $date = $today->copy()->addDays($i)->format('Y-m-d');
            $slotService->generateSlotsForDate($date);
        }

        // 6. Seed Sample Appointments for Today
        $todayStr = $today->format('Y-m-d');
        $availableSlots = ClinicSlot::where('slot_date', $todayStr)
            ->where('is_available', true)
            ->orderBy('start_time', 'asc')
            ->take(5)
            ->get();

        if ($availableSlots->count() >= 3) {
            // Patient 1: Checked-in & Waiting
            $slot1 = $availableSlots[0];
            $apt1 = Appointment::updateOrCreate(
                ['booking_code' => 'PHH-' . $today->format('ymd') . '-001'],
                [
                    'patient_name' => 'Ramesh Kumar',
                    'mobile' => '9876543210',
                    'clinic_slot_id' => $slot1->id,
                    'booking_source' => 'online',
                    'status' => 'checked_in',
                    'token_number' => 1,
                    'checked_in_at' => Carbon::now('Asia/Kolkata')->subMinutes(20),
                ]
            );
            $slot1->update(['is_available' => false]);
            $apt1->logStatusChange(null, 'booked', 'Patient');
            $apt1->logStatusChange('booked', 'checked_in', 'Reception Desk');

            // Patient 2: Booked (not checked-in yet)
            $slot2 = $availableSlots[1];
            $apt2 = Appointment::updateOrCreate(
                ['booking_code' => 'PHH-' . $today->format('ymd') . '-002'],
                [
                    'patient_name' => 'Sita Verma',
                    'mobile' => '9876543211',
                    'clinic_slot_id' => $slot2->id,
                    'booking_source' => 'online',
                    'status' => 'booked',
                    'token_number' => 2,
                ]
            );
            $slot2->update(['is_available' => false]);
            $apt2->logStatusChange(null, 'booked', 'Patient');

            // Patient 3: Walk-in (Checked in)
            $slot3 = $availableSlots[2];
            $apt3 = Appointment::updateOrCreate(
                ['booking_code' => 'PHH-' . $today->format('ymd') . '-003'],
                [
                    'patient_name' => 'Mohd. Salim',
                    'mobile' => '9876543212',
                    'clinic_slot_id' => $slot3->id,
                    'booking_source' => 'walk_in',
                    'status' => 'checked_in',
                    'token_number' => 3,
                    'checked_in_at' => Carbon::now('Asia/Kolkata')->subMinutes(10),
                ]
            );
            $slot3->update(['is_available' => false]);
            $apt3->logStatusChange(null, 'booked', 'Reception Desk');
            $apt3->logStatusChange('booked', 'checked_in', 'Reception Desk');
        }
    }
}

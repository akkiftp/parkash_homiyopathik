<?php

namespace App\Services;

use App\Models\ClinicSetting;
use App\Models\ClinicSlot;
use App\Models\DoctorSchedule;
use Carbon\Carbon;

class SlotService
{
    /**
     * Ensure slots are generated for a given date according to doctor schedules.
     */
    public function generateSlotsForDate(string $dateString): void
    {
        $setting = ClinicSetting::first();
        $slotDuration = $setting ? $setting->slot_duration : 15;
        $date = Carbon::parse($dateString);
        $dayName = $date->format('l'); // Monday, Tuesday, etc.

        // Find matching schedules
        $schedules = DoctorSchedule::where('is_active', true)
            ->where(function ($q) use ($dayName) {
                $q->where('weekday', 'all')
                  ->orWhere('weekday', $dayName);
            })
            ->get();

        foreach ($schedules as $schedule) {
            $current = Carbon::parse($dateString . ' ' . $schedule->start_time);
            $end = Carbon::parse($dateString . ' ' . $schedule->end_time);

            while ($current->copy()->addMinutes($slotDuration)->lte($end)) {
                $slotStart = $current->format('H:i');
                $slotEnd = $current->copy()->addMinutes($slotDuration)->format('H:i');

                ClinicSlot::firstOrCreate(
                    [
                        'slot_date' => $date->format('Y-m-d'),
                        'start_time' => $slotStart,
                    ],
                    [
                        'end_time' => $slotEnd,
                        'is_available' => true,
                    ]
                );

                $current->addMinutes($slotDuration);
            }
        }
    }

    /**
     * Get available slots for a given date.
     */
    public function getAvailableSlots(string $dateString): array
    {
        $this->generateSlotsForDate($dateString);

        $now = Carbon::now('Asia/Kolkata');
        $isToday = $dateString === $now->format('Y-m-d');

        $slots = ClinicSlot::where('slot_date', $dateString)
            ->where('is_available', true)
            ->orderBy('start_time', 'asc')
            ->get();

        $result = [];
        foreach ($slots as $slot) {
            // If date is today, check if time has already passed
            if ($isToday) {
                $slotDateTime = Carbon::parse($dateString . ' ' . $slot->start_time, 'Asia/Kolkata');
                if ($slotDateTime->lt($now)) {
                    continue; // Skip past slots
                }
            }

            $result[] = [
                'id' => $slot->id,
                'slot_date' => $slot->slot_date->format('Y-m-d'),
                'start_time' => substr($slot->start_time, 0, 5),
                'end_time' => substr($slot->end_time, 0, 5),
                'formatted_time' => Carbon::parse($slot->start_time)->format('g:i A'),
                'is_available' => (bool)$slot->is_available,
            ];
        }

        return $result;
    }
}

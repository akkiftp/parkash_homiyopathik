<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Appointment extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_code',
        'patient_name',
        'mobile',
        'clinic_slot_id',
        'booking_source',
        'status',
        'token_number',
        'checked_in_at',
        'called_at',
        'started_at',
        'completed_at',
        'cancellation_reason',
        'notes',
    ];

    protected $casts = [
        'token_number' => 'integer',
        'checked_in_at' => 'datetime',
        'called_at' => 'datetime',
        'started_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function slot(): BelongsTo
    {
        return $this->belongsTo(ClinicSlot::class, 'clinic_slot_id');
    }

    public function statusLogs(): HasMany
    {
        return $this->hasMany(AppointmentStatusLog::class);
    }

    public function logStatusChange(?string $oldStatus, string $newStatus, ?string $changedBy = null): void
    {
        $this->statusLogs()->create([
            'old_status' => $oldStatus,
            'new_status' => $newStatus,
            'changed_by' => $changedBy ?? auth()->user()?->name ?? 'System',
        ]);
    }
}

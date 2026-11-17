<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ClinicSlot extends Model
{
    use HasFactory;

    protected $fillable = [
        'slot_date',
        'start_time',
        'end_time',
        'is_available',
    ];

    protected $casts = [
        'slot_date' => 'date:Y-m-d',
        'is_available' => 'boolean',
    ];

    public function appointments(): HasMany
    {
        return $this->hasMany(Appointment::class);
    }

    public function activeAppointment(): HasOne
    {
        return $this->hasOne(Appointment::class)
            ->whereNotIn('status', ['cancelled', 'no_show']);
    }
}

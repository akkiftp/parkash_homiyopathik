<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ClinicSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'clinic_name',
        'doctor_name',
        'qualification',
        'specialization',
        'address',
        'phone',
        'slot_duration',
        'timezone',
    ];

    protected $casts = [
        'slot_duration' => 'integer',
    ];
}

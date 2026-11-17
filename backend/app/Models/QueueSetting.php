<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class QueueSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'queue_paused',
        'paused_at',
        'updated_by',
    ];

    protected $casts = [
        'queue_paused' => 'boolean',
        'paused_at' => 'datetime',
    ];

    public function updatedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}

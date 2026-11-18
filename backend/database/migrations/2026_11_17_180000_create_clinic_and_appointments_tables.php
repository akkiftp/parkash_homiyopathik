<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. clinic_settings
        Schema::create('clinic_settings', function (Blueprint $table) {
            $table->id();
            $table->string('clinic_name')->default('Prakash Homeo Hall');
            $table->string('doctor_name')->default('Dr. Navneet Srivastava');
            $table->string('qualification')->default('B.H.M.S. (Senior Homeopathic Consultant)');
            $table->string('specialization')->default('Classical Homeopathy & Chronic Care');
            $table->string('address')->default('Chowk, Chandiyana, Fatehpur, Uttar Pradesh - 212601');
            $table->string('phone')->default('+91 94150 12345');
            $table->unsignedInteger('slot_duration')->default(15); // in minutes
            $table->string('timezone')->default('Asia/Kolkata');
            $table->timestamps();
        });

        // 2. doctor_schedules
        Schema::create('doctor_schedules', function (Blueprint $table) {
            $table->id();
            $table->string('weekday')->default('all'); // all or Monday, Tuesday, etc.
            $table->string('session_name'); // Morning OPD, Evening OPD
            $table->time('start_time');
            $table->time('end_time');
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 3. clinic_slots
        Schema::create('clinic_slots', function (Blueprint $table) {
            $table->id();
            $table->date('slot_date')->index();
            $table->time('start_time');
            $table->time('end_time');
            $table->boolean('is_available')->default(true)->index();
            $table->timestamps();

            $table->unique(['slot_date', 'start_time'], 'unique_slot_per_date_time');
        });

        // 4. appointments
        Schema::create('appointments', function (Blueprint $table) {
            $table->id();
            $table->string('booking_code')->unique();
            $table->string('patient_name');
            $table->string('mobile', 20)->index();
            $table->foreignId('clinic_slot_id')->constrained('clinic_slots')->cascadeOnDelete();
            $table->enum('booking_source', ['online', 'walk_in'])->default('online');
            $table->enum('status', [
                'booked',
                'checked_in',
                'waiting',
                'called',
                'in_consultation',
                'completed',
                'skipped',
                'cancelled',
                'no_show'
            ])->default('booked')->index();
            $table->unsignedInteger('token_number')->nullable()->index();
            $table->timestamp('checked_in_at')->nullable();
            $table->timestamp('called_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->text('cancellation_reason')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at']);
        });

        // 5. queue_settings
        Schema::create('queue_settings', function (Blueprint $table) {
            $table->id();
            $table->boolean('queue_paused')->default(false);
            $table->timestamp('paused_at')->nullable();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        // 6. appointment_status_logs
        Schema::create('appointment_status_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('appointment_id')->constrained('appointments')->cascadeOnDelete();
            $table->string('old_status')->nullable();
            $table->string('new_status');
            $table->string('changed_by')->nullable(); // user name, role, or 'patient'
            $table->timestamp('created_at')->useCurrent();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('appointment_status_logs');
        Schema::dropIfExists('queue_settings');
        Schema::dropIfExists('appointments');
        Schema::dropIfExists('clinic_slots');
        Schema::dropIfExists('doctor_schedules');
        Schema::dropIfExists('clinic_settings');
    }
};

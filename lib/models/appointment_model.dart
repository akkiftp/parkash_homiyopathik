import 'package:flutter/material.dart';

class AppointmentModel {
  final int? id;
  final String bookingId;
  final String patientName;
  final String mobile;
  final int? tokenNumber;
  final String appointmentDate;
  final String appointmentTime;
  final String? slotStart;
  final String? slotEnd;
  final String status;
  final String? bookingSource;
  final int? clinicSlotId;

  // Live tracking specific fields
  final int? queuePosition;
  final int? patientsAhead;
  final int? estimatedWaitMinutes;
  final bool isToday;
  final bool queuePaused;
  final int? currentRunningToken;
  final String? clinicName;
  final String? doctorName;
  final String? address;

  final String? checkedInAt;
  final String? calledAt;
  final String? startedAt;
  final String? completedAt;
  final String? notes;

  AppointmentModel({
    this.id,
    required this.bookingId,
    required this.patientName,
    required this.mobile,
    this.tokenNumber,
    required this.appointmentDate,
    required this.appointmentTime,
    this.slotStart,
    this.slotEnd,
    required this.status,
    this.bookingSource,
    this.clinicSlotId,
    this.queuePosition,
    this.patientsAhead,
    this.estimatedWaitMinutes,
    this.isToday = false,
    this.queuePaused = false,
    this.currentRunningToken,
    this.clinicName,
    this.doctorName,
    this.address,
    this.checkedInAt,
    this.calledAt,
    this.startedAt,
    this.completedAt,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      bookingId: json['booking_id'] ?? json['booking_code'] ?? '',
      patientName: json['patient_name'] ?? '',
      mobile: json['mobile'] ?? '',
      tokenNumber: json['token_number'],
      appointmentDate: json['appointment_date'] ?? json['slot_date'] ?? '',
      appointmentTime: json['appointment_time'] ?? '',
      slotStart: json['slot_start'],
      slotEnd: json['slot_end'],
      status: json['status'] ?? 'booked',
      bookingSource: json['booking_source'],
      clinicSlotId: json['clinic_slot_id'],
      queuePosition: json['queue_position'],
      patientsAhead: json['patients_ahead'],
      estimatedWaitMinutes: json['estimated_wait_minutes'],
      isToday: json['is_today'] ?? false,
      queuePaused: json['queue_paused'] ?? false,
      currentRunningToken: json['current_running_token'],
      clinicName: json['clinic_name'],
      doctorName: json['doctor_name'],
      address: json['address'],
      checkedInAt: json['checked_in_at'],
      calledAt: json['called_at'],
      startedAt: json['started_at'],
      completedAt: json['completed_at'],
      notes: json['notes'],
    );
  }

  // Helpers
  bool get isBooked => status == 'booked';
  bool get isCheckedIn => status == 'checked_in';
  bool get isWaiting => status == 'waiting';
  bool get isCalled => status == 'called';
  bool get isInConsultation => status == 'in_consultation';
  bool get isCompleted => status == 'completed';
  bool get isSkipped => status == 'skipped';
  bool get isCancelled => status == 'cancelled';
  bool get isNoShow => status == 'no_show';

  String get statusDisplay {
    switch (status) {
      case 'booked':
        return 'Booked (Not Checked-In)';
      case 'checked_in':
        return 'Checked-In (Waiting)';
      case 'waiting':
        return 'Waiting in Queue';
      case 'called':
        return 'Called to Doctor';
      case 'in_consultation':
        return 'In Consultation';
      case 'completed':
        return 'Completed';
      case 'skipped':
        return 'Skipped';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No Show';
      default:
        return status.toUpperCase();
    }
  }

  Color get statusColor {
    switch (status) {
      case 'in_consultation':
        return const Color(0xFF0284C7); // Sky blue
      case 'called':
        return const Color(0xFF8B5CF6); // Purple
      case 'checked_in':
      case 'waiting':
        return const Color(0xFFF59E0B); // Amber
      case 'completed':
        return const Color(0xFF10B981); // Emerald
      case 'booked':
        return const Color(0xFF64748B); // Slate
      case 'skipped':
        return const Color(0xFFEC4899); // Pink
      case 'cancelled':
      case 'no_show':
        return const Color(0xFFEF4444); // Red
      default:
        return Colors.grey;
    }
  }
}

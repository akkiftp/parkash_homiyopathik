import 'package:flutter_test/flutter_test.dart';
import 'package:parkash_homiyopathik/models/appointment_model.dart';
import 'package:parkash_homiyopathik/models/clinic_model.dart';
import 'package:parkash_homiyopathik/models/slot_model.dart';

void main() {
  group('Clinic Models Unit Tests', () {
    test('ClinicInfo parses correctly from JSON', () {
      final json = {
        'clinic_name': 'Prakash Homeo Hall',
        'doctor_name': 'Dr. Om Prakash',
        'qualification': 'B.H.M.S.',
        'specialization': 'Classical Homeopathy',
        'address': 'Chowk, Chandiyana, Fatehpur',
        'phone': '+91 94150 12345',
        'slot_duration': 15,
        'timezone': 'Asia/Kolkata',
        'opd_timings': [
          {
            'id': 1,
            'session_name': 'Morning OPD',
            'start_time': '10:00 AM',
            'end_time': '1:00 PM',
            'weekday': 'all'
          }
        ],
        'queue_paused': false,
      };

      final clinic = ClinicInfo.fromJson(json);
      expect(clinic.clinicName, 'Prakash Homeo Hall');
      expect(clinic.doctorName, 'Dr. Om Prakash');
      expect(clinic.slotDuration, 15);
      expect(clinic.opdTimings.length, 1);
      expect(clinic.queuePaused, false);
    });

    test('SlotModel parses and formats correctly', () {
      final json = {
        'id': 1,
        'slot_date': '2026-11-18',
        'start_time': '10:00',
        'end_time': '10:15',
        'formatted_time': '10:00 AM',
        'is_available': true,
      };

      final slot = SlotModel.fromJson(json);
      expect(slot.id, 1);
      expect(slot.formattedTime, '10:00 AM');
      expect(slot.isAvailable, true);
    });

    test('AppointmentModel status helpers work accurately', () {
      final bookedApt = AppointmentModel.fromJson({
        'id': 10,
        'booking_code': 'PHH-261118-001',
        'patient_name': 'Ramesh Kumar',
        'mobile': '9876543210',
        'status': 'booked',
        'appointment_date': '2026-11-18',
        'appointment_time': '10:00 AM',
      });

      expect(bookedApt.isBooked, true);
      expect(bookedApt.isCheckedIn, false);
      expect(bookedApt.statusDisplay, 'Booked (Not Checked-In)');

      final inConsultApt = AppointmentModel.fromJson({
        'id': 11,
        'booking_code': 'PHH-261118-002',
        'patient_name': 'Sita Verma',
        'mobile': '9876543211',
        'status': 'in_consultation',
        'token_number': 2,
        'appointment_date': '2026-11-18',
        'appointment_time': '10:15 AM',
      });

      expect(inConsultApt.isInConsultation, true);
      expect(inConsultApt.tokenNumber, 2);
      expect(inConsultApt.statusDisplay, 'In Consultation');
    });
  });
}

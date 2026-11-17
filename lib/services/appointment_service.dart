import '../core/storage/local_storage.dart';
import '../models/appointment_model.dart';
import 'api_service.dart';

class AppointmentService {
  final ApiService _api = ApiService();

  Future<ApiResponse<AppointmentModel>> bookAppointment({
    required String patientName,
    required String mobile,
    required int clinicSlotId,
    String? notes,
  }) async {
    final response = await _api.post<AppointmentModel>(
      '/appointments',
      data: {
        'patient_name': patientName,
        'mobile': mobile,
        'clinic_slot_id': clinicSlotId,
        'notes': notes,
      },
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );

    if (response.success && response.data != null) {
      await LocalStorage.saveLastBookingId(response.data!.bookingId);
    }

    return response;
  }

  Future<ApiResponse<AppointmentModel>> getAppointment(String bookingCode) async {
    return _api.get<AppointmentModel>(
      '/appointments/$bookingCode',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> cancelAppointment({
    required String bookingCode,
    required String mobile,
    String? reason,
  }) async {
    return _api.post<dynamic>(
      '/appointments/$bookingCode/cancel',
      data: {
        'mobile': mobile,
        'reason': reason ?? 'Cancelled by patient',
      },
    );
  }
}

import '../models/appointment_model.dart';
import 'api_service.dart';

class ReceptionService {
  final ApiService _api = ApiService();

  Future<ApiResponse<List<AppointmentModel>>> getAppointments({
    String? date,
    String? search,
    String? status,
  }) async {
    final query = <String, dynamic>{};
    if (date != null) query['date'] = date;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;

    return _api.get<List<AppointmentModel>>(
      '/reception/appointments',
      queryParameters: query,
      fromData: (data) {
        final list = (data['appointments'] as List<dynamic>?) ?? [];
        return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<AppointmentModel>> walkInBooking({
    required String patientName,
    required String mobile,
    required int clinicSlotId,
    String? notes,
  }) async {
    return _api.post<AppointmentModel>(
      '/reception/walk-in',
      data: {
        'patient_name': patientName,
        'mobile': mobile,
        'clinic_slot_id': clinicSlotId,
        'notes': notes,
      },
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> checkIn(int id) async {
    return _api.post<AppointmentModel>(
      '/reception/appointments/$id/check-in',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> reschedule({
    required int id,
    required int newSlotId,
  }) async {
    return _api.post<AppointmentModel>(
      '/reception/appointments/$id/reschedule',
      data: {
        'new_clinic_slot_id': newSlotId,
      },
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> cancel({
    required int id,
    String? reason,
  }) async {
    return _api.post<AppointmentModel>(
      '/reception/appointments/$id/cancel',
      data: {
        'reason': reason ?? 'Cancelled by reception',
      },
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> markNoShow(int id) async {
    return _api.post<AppointmentModel>(
      '/reception/appointments/$id/no-show',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }
}

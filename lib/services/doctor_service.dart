import '../models/appointment_model.dart';
import 'api_service.dart';

class DoctorDashboardData {
  final Map<String, dynamic> summary;
  final bool queuePaused;
  final AppointmentModel? currentPatient;
  final AppointmentModel? calledPatient;
  final List<AppointmentModel> waitingList;
  final List<AppointmentModel> allToday;
  final String doctorName;
  final String doctorEmail;
  final String clinicName;
  final String qualification;
  final String specialization;
  final String selectedDate;
  final bool isToday;

  DoctorDashboardData({
    required this.summary,
    required this.queuePaused,
    this.currentPatient,
    this.calledPatient,
    required this.waitingList,
    required this.allToday,
    this.doctorName = 'Dr. Navneet Srivastava',
    this.doctorEmail = 'doctor@prakashhomeo.com',
    this.clinicName = 'Prakash Homeo Hall',
    this.qualification = 'B.H.M.S.',
    this.specialization = 'Classical Homeopathy & Chronic Care',
    this.selectedDate = '',
    this.isToday = true,
  });

  factory DoctorDashboardData.fromJson(Map<String, dynamic> json) {
    var rawWaiting = (json['waiting_list'] as List<dynamic>?) ?? [];
    var rawAll = (json['all_today'] as List<dynamic>?) ?? [];

    return DoctorDashboardData(
      summary: json['summary'] is Map ? Map<String, dynamic>.from(json['summary']) : {},
      queuePaused: json['queue_paused'] ?? false,
      currentPatient: json['current_patient'] != null
          ? AppointmentModel.fromJson(json['current_patient'] as Map<String, dynamic>)
          : null,
      calledPatient: json['called_patient'] != null
          ? AppointmentModel.fromJson(json['called_patient'] as Map<String, dynamic>)
          : null,
      waitingList: rawWaiting.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList(),
      allToday: rawAll.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList(),
      doctorName: json['doctor_name'] ?? 'Dr. Navneet Srivastava',
      doctorEmail: json['doctor_email'] ?? 'doctor@prakashhomeo.com',
      clinicName: json['clinic_name'] ?? 'Prakash Homeo Hall',
      qualification: json['qualification'] ?? 'B.H.M.S.',
      specialization: json['specialization'] ?? 'Classical Homeopathy & Chronic Care',
      selectedDate: json['selected_date'] ?? '',
      isToday: json['is_today'] ?? true,
    );
  }
}

class DoctorService {
  final ApiService _api = ApiService();

  Future<ApiResponse<DoctorDashboardData>> getDashboard({String? date}) async {
    return _api.get<DoctorDashboardData>(
      '/doctor/dashboard',
      queryParameters: (date != null && date.isNotEmpty) ? {'date': date} : null,
      fromData: (data) => DoctorDashboardData.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> checkInPatient(int id) async {
    return _api.post<AppointmentModel>(
      '/doctor/appointments/$id/check-in',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> callPatient(int id) async {
    return _api.post<AppointmentModel>(
      '/doctor/appointments/$id/call',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> startConsultation(int id) async {
    return _api.post<AppointmentModel>(
      '/doctor/appointments/$id/start',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> completeConsultation(int id) async {
    return _api.post<AppointmentModel>(
      '/doctor/appointments/$id/complete',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> skipPatient(int id) async {
    return _api.post<AppointmentModel>(
      '/doctor/appointments/$id/skip',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AppointmentModel>> markNoShow(int id) async {
    return _api.post<AppointmentModel>(
      '/doctor/appointments/$id/no-show',
      fromData: (data) => AppointmentModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> pauseQueue() async {
    return _api.post<dynamic>('/doctor/queue/pause');
  }

  Future<ApiResponse<dynamic>> resumeQueue() async {
    return _api.post<dynamic>('/doctor/queue/resume');
  }
}

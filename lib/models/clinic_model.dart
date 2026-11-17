class OpdTiming {
  final int id;
  final String sessionName;
  final String startTime;
  final String endTime;
  final String weekday;

  OpdTiming({
    required this.id,
    required this.sessionName,
    required this.startTime,
    required this.endTime,
    required this.weekday,
  });

  factory OpdTiming.fromJson(Map<String, dynamic> json) {
    return OpdTiming(
      id: json['id'] ?? 0,
      sessionName: json['session_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      weekday: json['weekday'] ?? 'all',
    );
  }
}

class ClinicInfo {
  final String clinicName;
  final String doctorName;
  final String qualification;
  final String specialization;
  final String address;
  final String phone;
  final int slotDuration;
  final String timezone;
  final List<OpdTiming> opdTimings;
  final bool queuePaused;

  ClinicInfo({
    required this.clinicName,
    required this.doctorName,
    required this.qualification,
    required this.specialization,
    required this.address,
    required this.phone,
    required this.slotDuration,
    required this.timezone,
    required this.opdTimings,
    required this.queuePaused,
  });

  factory ClinicInfo.fromJson(Map<String, dynamic> json) {
    var list = (json['opd_timings'] as List<dynamic>?) ?? [];
    return ClinicInfo(
      clinicName: json['clinic_name'] ?? 'Prakash Homeo Hall',
      doctorName: json['doctor_name'] ?? 'Dr. Om Prakash',
      qualification: json['qualification'] ?? 'B.H.M.S.',
      specialization: json['specialization'] ?? 'Classical Homeopathy',
      address: json['address'] ?? 'Chandiyana, Fatehpur, Uttar Pradesh',
      phone: json['phone'] ?? '',
      slotDuration: json['slot_duration'] ?? 15,
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      opdTimings: list.map((e) => OpdTiming.fromJson(e)).toList(),
      queuePaused: json['queue_paused'] ?? false,
    );
  }
}

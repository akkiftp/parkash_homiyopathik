class LiveQueueModel {
  final String clinicName;
  final String doctorName;
  final String specialization;
  final bool queuePaused;
  final int? currentToken;
  final String? currentPatientStatus;
  final int? nextToken;
  final int waitingCount;
  final List<int> waitingTokens;
  final int completedCount;
  final int totalToday;
  final String timestamp;

  LiveQueueModel({
    required this.clinicName,
    required this.doctorName,
    required this.specialization,
    required this.queuePaused,
    this.currentToken,
    this.currentPatientStatus,
    this.nextToken,
    required this.waitingCount,
    required this.waitingTokens,
    required this.completedCount,
    required this.totalToday,
    required this.timestamp,
  });

  factory LiveQueueModel.fromJson(Map<String, dynamic> json) {
    var rawTokens = json['waiting_tokens'] as List<dynamic>? ?? [];
    List<int> tokens = rawTokens.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();

    return LiveQueueModel(
      clinicName: json['clinic_name'] ?? 'Prakash Homeo Hall',
      doctorName: json['doctor_name'] ?? 'Dr. Om Prakash',
      specialization: json['specialization'] ?? 'Classical Homeopathy',
      queuePaused: json['queue_paused'] ?? false,
      currentToken: json['current_token'],
      currentPatientStatus: json['current_patient_status'],
      nextToken: json['next_token'],
      waitingCount: json['waiting_count'] ?? 0,
      waitingTokens: tokens,
      completedCount: json['completed_count'] ?? 0,
      totalToday: json['total_today'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

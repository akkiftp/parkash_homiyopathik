class SlotModel {
  final int id;
  final String slotDate;
  final String startTime;
  final String endTime;
  final String formattedTime;
  final bool isAvailable;

  SlotModel({
    required this.id,
    required this.slotDate,
    required this.startTime,
    required this.endTime,
    required this.formattedTime,
    required this.isAvailable,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] ?? 0,
      slotDate: json['slot_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      formattedTime: json['formatted_time'] ?? json['start_time'] ?? '',
      isAvailable: json['is_available'] ?? true,
    );
  }
}

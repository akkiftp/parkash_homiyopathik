import '../models/clinic_model.dart';
import '../models/live_queue_model.dart';
import '../models/slot_model.dart';
import 'api_service.dart';

class ClinicService {
  final ApiService _api = ApiService();

  Future<ApiResponse<ClinicInfo>> getClinicInfo() async {
    return _api.get<ClinicInfo>(
      '/clinic',
      fromData: (data) => ClinicInfo.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<SlotModel>>> getSlots(String date) async {
    return _api.get<List<SlotModel>>(
      '/slots',
      queryParameters: {'date': date},
      fromData: (data) {
        final list = (data['slots'] as List<dynamic>?) ?? [];
        return list.map((e) => SlotModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<LiveQueueModel>> getLiveQueue() async {
    return _api.get<LiveQueueModel>(
      '/queue/live',
      fromData: (data) => LiveQueueModel.fromJson(data as Map<String, dynamic>),
    );
  }
}

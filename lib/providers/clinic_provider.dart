import 'package:flutter/material.dart';
import '../models/clinic_model.dart';
import '../services/clinic_service.dart';

class ClinicProvider extends ChangeNotifier {
  final ClinicService _service = ClinicService();

  ClinicInfo? _clinicInfo;
  bool _isLoading = false;
  String? _errorMessage;

  ClinicInfo? get clinicInfo => _clinicInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchClinicInfo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _service.getClinicInfo();
    _isLoading = false;

    if (res.success && res.data != null) {
      _clinicInfo = res.data;
    } else {
      _errorMessage = res.message;
    }
    notifyListeners();
  }
}

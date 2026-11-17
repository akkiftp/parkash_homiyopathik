import 'dart:async';
import 'package:flutter/material.dart';
import '../models/appointment_model.dart';
import '../services/appointment_service.dart';

class TrackingProvider extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();

  String? _bookingCode;
  AppointmentModel? _appointment;
  bool _isLoading = false;
  bool _isFetching = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  AppointmentModel? get appointment => _appointment;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get bookingCode => _bookingCode;

  void startTracking(String code) {
    _bookingCode = code.trim();
    _errorMessage = null;
    _stopTimer();

    fetchStatus(showLoadingIndicator: true);

    // Start 5-second polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchStatus(showLoadingIndicator: false);
    });
  }

  Future<void> fetchStatus({bool showLoadingIndicator = false}) async {
    if (_bookingCode == null || _bookingCode!.isEmpty) return;
    if (_isFetching) return; // Prevent overlapping API calls

    _isFetching = true;
    if (showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final res = await _service.getAppointment(_bookingCode!);
    _isFetching = false;
    _isLoading = false;

    if (res.success && res.data != null) {
      _appointment = res.data;
      _errorMessage = null;
    } else {
      // Don't wipe current appointment data on a temporary network blip
      if (_appointment == null) {
        _errorMessage = res.message;
      }
    }
    notifyListeners();
  }

  Future<bool> cancelAppointment(String mobile, String reason) async {
    if (_bookingCode == null) return false;

    final res = await _service.cancelAppointment(
      bookingCode: _bookingCode!,
      mobile: mobile,
      reason: reason,
    );

    if (res.success) {
      await fetchStatus(showLoadingIndicator: true);
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  void _stopTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void stopTracking() {
    _stopTimer();
    _bookingCode = null;
    _appointment = null;
    _errorMessage = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

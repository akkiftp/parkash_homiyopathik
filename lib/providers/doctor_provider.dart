import 'dart:async';
import 'package:flutter/material.dart';
import '../services/doctor_service.dart';

class DoctorProvider extends ChangeNotifier {
  final DoctorService _service = DoctorService();

  DoctorDashboardData? _dashboardData;
  String _selectedDate = '';
  bool _isLoading = false;
  bool _isFetching = false;
  String? _errorMessage;
  String? _actionSuccessMessage;
  Timer? _pollingTimer;

  DoctorDashboardData? get dashboardData => _dashboardData;
  String get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionSuccessMessage => _actionSuccessMessage;

  void setSelectedDate(String date) {
    if (_selectedDate == date) return;
    _selectedDate = date;
    fetchDashboard(showLoadingIndicator: true);
  }

  void startPolling() {
    _stopTimer();
    fetchDashboard(showLoadingIndicator: true);

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchDashboard(showLoadingIndicator: false);
    });
  }

  Future<void> fetchDashboard({bool showLoadingIndicator = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final res = await _service.getDashboard(date: _selectedDate);
    _isFetching = false;
    _isLoading = false;

    if (res.success && res.data != null) {
      _dashboardData = res.data;
      _errorMessage = null;
    } else {
      if (_dashboardData == null) {
        _errorMessage = res.message;
      }
    }
    notifyListeners();
  }

  Future<bool> checkInPatient(int id) async {
    _actionSuccessMessage = null;
    _errorMessage = null;
    final res = await _service.checkInPatient(id);
    if (res.success) {
      _actionSuccessMessage = res.message;
      await fetchDashboard();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> callPatient(int id) async {
    _actionSuccessMessage = null;
    _errorMessage = null;
    final res = await _service.callPatient(id);
    if (res.success) {
      _actionSuccessMessage = res.message;
      await fetchDashboard();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> startConsultation(int id) async {
    _actionSuccessMessage = null;
    _errorMessage = null;
    final res = await _service.startConsultation(id);
    if (res.success) {
      _actionSuccessMessage = res.message;
      await fetchDashboard();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeConsultation(int id) async {
    _actionSuccessMessage = null;
    _errorMessage = null;
    final res = await _service.completeConsultation(id);
    if (res.success) {
      _actionSuccessMessage = res.message;
      await fetchDashboard();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> skipPatient(int id) async {
    _actionSuccessMessage = null;
    _errorMessage = null;
    final res = await _service.skipPatient(id);
    if (res.success) {
      _actionSuccessMessage = res.message;
      await fetchDashboard();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markNoShow(int id) async {
    _actionSuccessMessage = null;
    _errorMessage = null;
    final res = await _service.markNoShow(id);
    if (res.success) {
      _actionSuccessMessage = res.message;
      await fetchDashboard();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> pauseQueue() async {
    _actionSuccessMessage = null;
    _errorMessage = null;
    final res = await _service.pauseQueue();
    if (res.success) {
      _actionSuccessMessage = 'Queue paused successfully.';
      await fetchDashboard();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resumeQueue() async {
    _actionSuccessMessage = null;
    _errorMessage = null;
    final res = await _service.resumeQueue();
    if (res.success) {
      _actionSuccessMessage = 'Queue resumed successfully.';
      await fetchDashboard();
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

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../services/reception_service.dart';

class ReceptionProvider extends ChangeNotifier {
  final ReceptionService _service = ReceptionService();

  List<AppointmentModel> _appointments = [];
  bool _isLoading = false;
  bool _isFetching = false;
  String? _errorMessage;
  String? _successMessage;

  String _searchQuery = '';
  String? _statusFilter;
  DateTime _selectedDate = DateTime.now();

  Timer? _pollingTimer;

  List<AppointmentModel> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  DateTime get selectedDate => _selectedDate;

  String get formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void setSearch(String query) {
    _searchQuery = query;
    fetchAppointments();
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    fetchAppointments();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    fetchAppointments();
  }

  void startPolling() {
    _stopTimer();
    fetchAppointments(showLoadingIndicator: true);

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchAppointments(showLoadingIndicator: false);
    });
  }

  Future<void> fetchAppointments({bool showLoadingIndicator = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final res = await _service.getAppointments(
      date: formattedDate,
      search: _searchQuery,
      status: _statusFilter,
    );

    _isFetching = false;
    _isLoading = false;

    if (res.success && res.data != null) {
      _appointments = res.data!;
      _errorMessage = null;
    } else {
      if (_appointments.isEmpty) {
        _errorMessage = res.message;
      }
    }
    notifyListeners();
  }

  Future<bool> checkIn(int id) async {
    _successMessage = null;
    _errorMessage = null;
    final res = await _service.checkIn(id);
    if (res.success) {
      _successMessage = res.message;
      await fetchAppointments();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> walkInBooking({
    required String patientName,
    required String mobile,
    required int clinicSlotId,
    String? notes,
  }) async {
    _successMessage = null;
    _errorMessage = null;
    final res = await _service.walkInBooking(
      patientName: patientName,
      mobile: mobile,
      clinicSlotId: clinicSlotId,
      notes: notes,
    );

    if (res.success) {
      _successMessage = res.message;
      await fetchAppointments();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reschedule(int id, int newSlotId) async {
    _successMessage = null;
    _errorMessage = null;
    final res = await _service.reschedule(id: id, newSlotId: newSlotId);
    if (res.success) {
      _successMessage = res.message;
      await fetchAppointments();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancel(int id, String? reason) async {
    _successMessage = null;
    _errorMessage = null;
    final res = await _service.cancel(id: id, reason: reason);
    if (res.success) {
      _successMessage = res.message;
      await fetchAppointments();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> markNoShow(int id) async {
    _successMessage = null;
    _errorMessage = null;
    final res = await _service.markNoShow(id);
    if (res.success) {
      _successMessage = res.message;
      await fetchAppointments();
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

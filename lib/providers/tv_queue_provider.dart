import 'dart:async';
import 'package:flutter/material.dart';
import '../models/live_queue_model.dart';
import '../services/clinic_service.dart';

class TvQueueProvider extends ChangeNotifier {
  final ClinicService _service = ClinicService();

  LiveQueueModel? _liveQueue;
  bool _isLoading = false;
  bool _isFetching = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  LiveQueueModel? get liveQueue => _liveQueue;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startPolling() {
    _stopTimer();
    fetchLiveQueue(showLoadingIndicator: true);

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchLiveQueue(showLoadingIndicator: false);
    });
  }

  Future<void> fetchLiveQueue({bool showLoadingIndicator = false}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (showLoadingIndicator) {
      _isLoading = true;
      notifyListeners();
    }

    final res = await _service.getLiveQueue();
    _isFetching = false;
    _isLoading = false;

    if (res.success && res.data != null) {
      _liveQueue = res.data;
      _errorMessage = null;
    } else {
      if (_liveQueue == null) {
        _errorMessage = res.message;
      }
    }
    notifyListeners();
  }

  void stopPolling() {
    _stopTimer();
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

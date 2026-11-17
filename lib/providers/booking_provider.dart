import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/slot_model.dart';
import '../services/appointment_service.dart';
import '../services/clinic_service.dart';

class BookingProvider extends ChangeNotifier {
  final ClinicService _clinicService = ClinicService();
  final AppointmentService _appointmentService = AppointmentService();

  DateTime _selectedDate = DateTime.now();
  List<SlotModel> _slots = [];
  int? _selectedSlotId;
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  AppointmentModel? _bookedAppointment;

  DateTime get selectedDate => _selectedDate;
  List<SlotModel> get slots => _slots;
  int? get selectedSlotId => _selectedSlotId;
  bool get isLoadingSlots => _isLoadingSlots;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  AppointmentModel? get bookedAppointment => _bookedAppointment;

  String get formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void setDate(DateTime date) {
    _selectedDate = date;
    _selectedSlotId = null;
    notifyListeners();
    fetchSlots();
  }

  void selectSlot(int slotId) {
    _selectedSlotId = slotId;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchSlots() async {
    _isLoadingSlots = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _clinicService.getSlots(formattedDate);
    _isLoadingSlots = false;

    if (res.success && res.data != null) {
      _slots = res.data!;
      // Deselect slot if no longer in list
      if (_selectedSlotId != null && !_slots.any((s) => s.id == _selectedSlotId)) {
        _selectedSlotId = null;
      }
    } else {
      _errorMessage = res.message;
      _slots = [];
    }
    notifyListeners();
  }

  Future<bool> book({
    required String patientName,
    required String mobile,
    String? notes,
  }) async {
    if (_selectedSlotId == null) {
      _errorMessage = 'Please select an appointment time slot.';
      notifyListeners();
      return false;
    }

    if (_isSubmitting) return false; // Prevent double submit

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final res = await _appointmentService.bookAppointment(
      patientName: patientName,
      mobile: mobile,
      clinicSlotId: _selectedSlotId!,
      notes: notes,
    );

    _isSubmitting = false;

    if (res.success && res.data != null) {
      _bookedAppointment = res.data;
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      // Refresh slots in case slot was taken
      fetchSlots();
      return false;
    }
  }

  void reset() {
    _selectedSlotId = null;
    _errorMessage = null;
    _bookedAppointment = null;
    _isSubmitting = false;
    notifyListeners();
  }
}

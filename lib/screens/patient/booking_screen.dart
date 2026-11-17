import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/slot_model.dart';
import '../../providers/booking_provider.dart';
import 'confirmation_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().reset();
      context.read<BookingProvider>().fetchSlots();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final prov = context.read<BookingProvider>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: prov.selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      prov.setDate(picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<BookingProvider>();
    final success = await prov.book(
      patientName: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (success && mounted && prov.bookedAppointment != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmationScreen(appointment: prov.bookedAppointment!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookingProvider>();

    // Separate slots into Morning (before 14:00) and Evening (after 14:00)
    final morningSlots = prov.slots.where((s) {
      final hour = int.tryParse(s.startTime.split(':').first) ?? 0;
      return hour < 14;
    }).toList();

    final eveningSlots = prov.slots.where((s) {
      final hour = int.tryParse(s.startTime.split(':').first) ?? 0;
      return hour >= 14;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error Banner
                  if (prov.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.dangerRed),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              prov.errorMessage!,
                              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 1. Patient Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '1. Patient Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Patient Full Name *',
                              hintText: 'e.g. Ramesh Kumar',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter patient full name';
                              }
                              if (val.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number *',
                              hintText: '10-digit mobile number',
                              prefixIcon: Icon(Icons.phone_outlined),
                              prefixText: '+91 ',
                              counterText: '',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter mobile number';
                              }
                              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) {
                                return 'Please enter a valid 10-digit Indian mobile number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Symptoms / Reason for Consultation (Optional)',
                              hintText: 'e.g. Skin allergy, chronic headache, joint pain...',
                              prefixIcon: Icon(Icons.note_alt_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Select Date
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '2. Appointment Date',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              TextButton.icon(
                                onPressed: () => _pickDate(context),
                                icon: const Icon(Icons.calendar_today, size: 16),
                                label: const Text('Change Date'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () => _pickDate(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event, color: AppTheme.primaryBlue),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat('EEEE, d MMMM yyyy').format(prov.selectedDate),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(prov.selectedDate) ==
                                                DateFormat('yyyy-MM-dd').format(DateTime.now())
                                            ? 'Today'
                                            : 'Upcoming',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_drop_down, color: AppTheme.textMuted),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Time Slots
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '3. Select Available Slot',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              if (prov.isLoadingSlots)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (!prov.isLoadingSlots && prov.slots.isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  const Icon(Icons.event_busy, size: 40, color: AppTheme.textMuted),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No available slots remaining for this date.',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      prov.setDate(DateTime.now().add(const Duration(days: 1)));
                                    },
                                    child: const Text('Check Tomorrow'),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Morning OPD Slots
                            if (morningSlots.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8, top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFD97706)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Morning Session (10:00 AM - 01:00 PM)',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark),
                                    ),
                                  ],
                                ),
                              ),
                              _buildSlotGrid(morningSlots, prov),
                              const SizedBox(height: 16),
                            ],

                            // Evening OPD Slots
                            if (eveningSlots.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8, top: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.nights_stay_outlined, size: 16, color: Color(0xFF4F46E5)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Evening Session (05:00 PM - 08:00 PM)',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark),
                                    ),
                                  ],
                                ),
                              ),
                              _buildSlotGrid(eveningSlots, prov),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton(
                    onPressed: prov.isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: prov.isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Securing Appointment Slot...'),
                            ],
                          )
                        : const Text(
                            'Confirm & Book Appointment',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotGrid(List<SlotModel> slots, BookingProvider prov) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = prov.selectedSlotId == slot.id;
        return ChoiceChip(
          label: Text(slot.formattedTime),
          selected: isSelected,
          selectedColor: AppTheme.primaryBlue,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? AppTheme.primaryBlue : const Color(0xFFCBD5E1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          onSelected: (selected) {
            if (selected) {
              prov.selectSlot(slot.id);
            }
          },
        );
      }).toList(),
    );
  }
}

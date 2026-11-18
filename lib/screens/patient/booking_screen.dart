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

  final List<String> _commonSymptoms = [
    'General Consultation',
    'Chronic Cough & Cold',
    'Skin Allergy / Eczema',
    'Joint Pain / Arthritis',
    'Digestive / Acidity',
    'Migraine / Headache',
    'Child Health',
  ];

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

  Future<void> _pickCustomDate(BuildContext context) async {
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

    // Separate slots into Morning and Evening sessions
    final morningSlots = prov.slots.where((s) {
      final hour = int.tryParse(s.startTime.split(':').first) ?? 0;
      return hour < 14;
    }).toList();

    final eveningSlots = prov.slots.where((s) {
      final hour = int.tryParse(s.startTime.split(':').first) ?? 0;
      return hour >= 14;
    }).toList();

    SlotModel? selectedSlot;
    if (prov.selectedSlotId != null) {
      for (final s in prov.slots) {
        if (s.id == prov.selectedSlotId) {
          selectedSlot = s;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedSlot != null
                          ? '${selectedSlot.formattedTime} • ${DateFormat("d MMM").format(prov.selectedDate)}'
                          : 'Select a time slot',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: selectedSlot != null ? AppTheme.primaryDarkBlue : AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      selectedSlot != null ? 'Slot Duration: 15 mins' : 'Please choose date & slot',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              ElevatedButton(
                onPressed: (prov.isSubmitting || prov.selectedSlotId == null) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: prov.isSubmitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Booking...'),
                        ],
                      )
                    : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.dangerRed, size: 20),
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

                  // 1. Interactive Horizontal Date Strip
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.primaryLightBlue,
                                    child: Text('1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Select Date / दिनांक चुनें',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () => _pickCustomDate(context),
                                icon: const Icon(Icons.edit_calendar, size: 16),
                                label: const Text('More Dates'),
                                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: 7,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final date = DateTime.now().add(Duration(days: index));
                                final isSelected = DateFormat('yyyy-MM-dd').format(prov.selectedDate) ==
                                    DateFormat('yyyy-MM-dd').format(date);
                                final isToday = index == 0;
                                final isTomorrow = index == 1;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => prov.setDate(date),
                                  child: Container(
                                    width: 72,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primaryBlue : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primaryBlue : const Color(0xFFCBD5E1),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isToday ? 'Today' : (isTomorrow ? 'Tmrw' : DateFormat('E').format(date)),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                            color: isSelected ? Colors.white70 : AppTheme.textMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('d').format(date),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : AppTheme.textDark,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('MMM').format(date),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isSelected ? Colors.white70 : AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Select Time Slot
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppTheme.primaryLightBlue,
                                    child: Text('2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Choose Time Slot / समय चुनें',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                  ),
                                ],
                              ),
                              if (prov.isLoadingSlots)
                                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (!prov.isLoadingSlots && prov.slots.isEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.event_busy, size: 40, color: AppTheme.textMuted),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No open slots remaining for this date.',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Please tap another date above to view available slots.',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 12),
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
                            // Morning Session
                            if (morningSlots.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFD97706)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Morning Session (10:00 AM - 01:00 PM)  •  ${morningSlots.length} Slots',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFB45309)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildSlotWrap(morningSlots, prov),
                              const SizedBox(height: 18),
                            ],

                            // Evening Session
                            if (eveningSlots.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E7FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.nights_stay_rounded, size: 16, color: Color(0xFF4338CA)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Evening Session (05:00 PM - 08:00 PM)  •  ${eveningSlots.length} Slots',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3730A3)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildSlotWrap(eveningSlots, prov),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Patient Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppTheme.primaryLightBlue,
                                child: Text('3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Patient Details / मरीज की जानकारी',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
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
                          const SizedBox(height: 16),
                          const Text(
                            'Quick Symptoms / मुख्य लक्षण (Optional):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _commonSymptoms.map((sym) {
                              final isSelected = _notesController.text.contains(sym);
                              return FilterChip(
                                label: Text(sym, style: const TextStyle(fontSize: 11)),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryLightBlue,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      if (_notesController.text.isEmpty) {
                                        _notesController.text = sym;
                                      } else {
                                        _notesController.text = '${_notesController.text}, $sym';
                                      }
                                    } else {
                                      _notesController.text = _notesController.text
                                          .replaceFirst(', $sym', '')
                                          .replaceFirst(sym, '');
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Other Problem / अन्य विवरण (Optional)',
                              hintText: 'Write symptoms here...',
                              prefixIcon: Icon(Icons.notes_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotWrap(List<SlotModel> slots, BookingProvider prov) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: slots.map((slot) {
        final isSelected = prov.selectedSlotId == slot.id;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => prov.selectSlot(slot.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primaryBlue : const Color(0xFFCBD5E1),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: isSelected ? Colors.white : AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  slot.formattedTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import '../../models/slot_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reception_provider.dart';
import '../../services/clinic_service.dart';
import '../home_screen.dart';

class ReceptionDashboardScreen extends StatefulWidget {
  const ReceptionDashboardScreen({super.key});

  @override
  State<ReceptionDashboardScreen> createState() => _ReceptionDashboardScreenState();
}

class _ReceptionDashboardScreenState extends State<ReceptionDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceptionProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _showWalkInDialog() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final notesController = TextEditingController();
    int? selectedSlotId;
    List<SlotModel> availableSlots = [];
    bool isLoadingSlots = true;
    bool isSubmitting = false;
    String? localError;

    final clinicService = ClinicService();
    final receptionProv = context.read<ReceptionProvider>();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isLoadingSlots) {
            clinicService.getSlots(todayStr).then((res) {
              setModalState(() {
                isLoadingSlots = false;
                availableSlots = res.data ?? [];
              });
            });
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.person_add_alt_1, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Text('Walk-in Patient Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Book walk-in appointment and immediately check-in to doctor waiting queue:',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    if (localError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(localError!, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
                      ),
                    ],
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Patient Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Chief Complaint (Optional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Available Time Slots Today:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (isLoadingSlots)
                      const Center(child: CircularProgressIndicator())
                    else if (availableSlots.isEmpty)
                      const Text('No slots available for walk-in today.', style: TextStyle(color: AppTheme.dangerRed, fontSize: 12))
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableSlots.map((slot) {
                          final isSelected = selectedSlotId == slot.id;
                          return ChoiceChip(
                            label: Text(slot.formattedTime, style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryBlue,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark),
                            onSelected: (val) {
                              setModalState(() {
                                selectedSlotId = val ? slot.id : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final mobile = mobileController.text.trim();
                        if (name.isEmpty || mobile.isEmpty || selectedSlotId == null) {
                          setModalState(() {
                            localError = 'Please fill all required fields and choose a slot.';
                          });
                          return;
                        }

                        setModalState(() {
                          isSubmitting = true;
                          localError = null;
                        });

                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);

                        final success = await receptionProv.walkInBooking(
                          patientName: name,
                          mobile: mobile,
                          clinicSlotId: selectedSlotId!,
                          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                        );

                        if (success) {
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Walk-in patient registered and checked-in to doctor waiting queue!'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                        } else {
                          setModalState(() {
                            isSubmitting = false;
                            localError = receptionProv.errorMessage ?? 'Booking failed.';
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Book & Check-In'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRescheduleDialog(AppointmentModel apt) {
    int? selectedSlotId;
    List<SlotModel> slots = [];
    bool isLoading = true;
    bool isSaving = false;
    String? localError;

    final clinicService = ClinicService();
    final receptionProv = context.read<ReceptionProvider>();
    final dateStr = apt.appointmentDate.isNotEmpty ? apt.appointmentDate : DateFormat('yyyy-MM-dd').format(DateTime.now());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isLoading) {
            clinicService.getSlots(dateStr).then((res) {
              setModalState(() {
                isLoading = false;
                slots = res.data ?? [];
              });
            });
          }

          return AlertDialog(
            title: Text('Reschedule: ${apt.patientName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Slot: ${apt.appointmentTime} (${apt.appointmentDate})', style: const TextStyle(color: AppTheme.textMuted)),
                  const SizedBox(height: 14),
                  if (localError != null)
                    Text(localError!, style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
                  const Text('Select New Slot:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (slots.isEmpty)
                    const Text('No alternate slots available for this date.', style: TextStyle(color: AppTheme.dangerRed))
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: slots.map((s) {
                        final isSel = selectedSlotId == s.id;
                        return ChoiceChip(
                          label: Text(s.formattedTime),
                          selected: isSel,
                          selectedColor: AppTheme.primaryBlue,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppTheme.textDark),
                          onSelected: (val) {
                            setModalState(() {
                              selectedSlotId = val ? s.id : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (selectedSlotId == null || isSaving)
                    ? null
                    : () async {
                        setModalState(() => isSaving = true);
                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);

                        final success = await receptionProv.reschedule(apt.id!, selectedSlotId!);
                        if (success) {
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Appointment rescheduled successfully!'), backgroundColor: AppTheme.accentGreen),
                          );
                        } else {
                          setModalState(() {
                            isSaving = false;
                            localError = receptionProv.errorMessage;
                          });
                        }
                      },
                child: const Text('Confirm Reschedule'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ReceptionProvider>();
    final appointments = prov.appointments;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reception Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Prakash Homeo Hall - OPD Management', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.fetchAppointments(showLoadingIndicator: true),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showWalkInDialog,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Walk-in Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search and Filters Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: 'Search by patient name, mobile, or booking ID...',
                                  prefixIcon: Icon(Icons.search),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onChanged: (val) => prov.setSearch(val),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.outlined(
                              icon: const Icon(Icons.calendar_today, size: 20),
                              tooltip: 'Filter Date',
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: prov.selectedDate,
                                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                );
                                if (picked != null) prov.setDate(picked);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All Status', null, prov),
                              _buildFilterChip('Booked', 'booked', prov),
                              _buildFilterChip('Checked-In', 'checked_in', prov),
                              _buildFilterChip('Completed', 'completed', prov),
                              _buildFilterChip('Cancelled', 'cancelled', prov),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Appointments Table / List
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Appointments (${appointments.length}) - ${DateFormat("d MMMM yyyy").format(prov.selectedDate)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.sync, size: 12, color: AppTheme.accentGreen),
                                  SizedBox(width: 4),
                                  Text('Live 5s', style: TextStyle(fontSize: 11, color: AppTheme.accentGreen)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        if (appointments.isEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.event_note, size: 48, color: AppTheme.textMuted),
                                  SizedBox(height: 8),
                                  Text('No appointments found matching current filters.', style: TextStyle(color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: appointments.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final apt = appointments[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: apt.statusColor.withValues(alpha: 0.12),
                                      child: Text(
                                        apt.tokenNumber != null ? '#${apt.tokenNumber}' : '-',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: apt.statusColor),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                apt.patientName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: apt.statusColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  apt.statusDisplay,
                                                  style: TextStyle(color: apt.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text('Mobile: +91 ${apt.mobile} • Code: ${apt.bookingId}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                          Text('Slot: ${apt.appointmentTime} • Source: ${apt.bookingSource?.toUpperCase() ?? "ONLINE"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                        ],
                                      ),
                                    ),
                                    // Action Buttons
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        if (apt.isBooked)
                                          ElevatedButton.icon(
                                            onPressed: () => prov.checkIn(apt.id!),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('Check-In', style: TextStyle(fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.accentGreen,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            ),
                                          ),
                                        if (!apt.isCompleted && !apt.isCancelled) ...[
                                          IconButton(
                                            tooltip: 'Reschedule',
                                            icon: const Icon(Icons.edit_calendar, size: 20, color: AppTheme.primaryBlue),
                                            onPressed: () => _showRescheduleDialog(apt),
                                          ),
                                          IconButton(
                                            tooltip: 'Cancel Booking',
                                            icon: const Icon(Icons.cancel_outlined, size: 20, color: AppTheme.dangerRed),
                                            onPressed: () => prov.cancel(apt.id!, 'Cancelled at reception desk'),
                                          ),
                                          IconButton(
                                            tooltip: 'Mark No Show',
                                            icon: const Icon(Icons.person_off_outlined, size: 20, color: Colors.grey),
                                            onPressed: () => prov.markNoShow(apt.id!),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 70), // Padding for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status, ReceptionProvider prov) {
    final isSelected = prov.statusFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => prov.setStatusFilter(status),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/tracking_provider.dart';

class TrackingScreen extends StatefulWidget {
  final String? initialBookingCode;

  const TrackingScreen({super.key, this.initialBookingCode});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialBookingCode != null && widget.initialBookingCode!.isNotEmpty) {
      _codeController.text = widget.initialBookingCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TrackingProvider>().startTracking(widget.initialBookingCode!);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _search() {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      context.read<TrackingProvider>().startTracking(code);
    }
  }

  void _showCancelDialog() {
    final prov = context.read<TrackingProvider>();
    final apt = prov.appointment;
    if (apt == null) return;

    final mobileController = TextEditingController();
    final reasonController = TextEditingController();
    bool isCancelling = false;
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed),
                SizedBox(width: 8),
                Text('Cancel Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For security verification, please enter the mobile number used during booking:',
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
                      child: Text(
                        localError!,
                        style: const TextStyle(color: AppTheme.dangerRed, fontSize: 12),
                      ),
                    ),
                  ],
                  TextField(
                    controller: mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Verification Mobile Number *',
                      hintText: '10-digit mobile',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Cancellation (Optional)',
                      hintText: 'e.g. Schedule clash, feeling better...',
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isCancelling ? null : () => Navigator.pop(ctx),
                child: const Text('Keep Appointment'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                onPressed: isCancelling
                    ? null
                    : () async {
                        final mobile = mobileController.text.trim();
                        if (mobile.isEmpty) {
                          setModalState(() {
                            localError = 'Please enter your mobile number.';
                          });
                          return;
                        }

                        setModalState(() {
                          isCancelling = true;
                          localError = null;
                        });

                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);

                        final success = await prov.cancelAppointment(
                          mobile,
                          reasonController.text.trim(),
                        );

                        if (success) {
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Appointment has been cancelled successfully.'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                        } else {
                          setModalState(() {
                            isCancelling = false;
                            localError = prov.errorMessage ?? 'Verification failed.';
                          });
                        }
                      },
                child: isCancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TrackingProvider>();
    final apt = prov.appointment;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Queue Tracking'),
        actions: [
          if (apt != null)
            IconButton(
              tooltip: 'Refresh Status',
              icon: const Icon(Icons.refresh),
              onPressed: () => prov.fetchStatus(showLoadingIndicator: true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Code Input Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Booking ID',
                              hintText: 'PHH-261117-001',
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: prov.isLoading ? null : _search,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          child: prov.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Track'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Error Banner
                if (prov.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
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

                // Live Tracking Content
                if (apt != null) ...[
                  // Live Auto-Refresh indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentGreen),
                            ),
                            SizedBox(width: 6),
                            Text('Auto-updating every 5s', style: TextStyle(fontSize: 11, color: Color(0xFF166534))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Main Status Card
                  Card(
                    color: apt.statusColor.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: apt.statusColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('YOUR APPOINTMENT TOKEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Text(
                                    apt.tokenNumber != null ? '#${apt.tokenNumber}' : 'Unassigned',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: apt.statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: apt.statusColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  apt.statusDisplay,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Patient Name', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    const SizedBox(height: 2),
                                    Text(apt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Scheduled Slot', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    const SizedBox(height: 2),
                                    Text('${apt.appointmentTime} (${apt.appointmentDate})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Queue Position & Waiting Time Grid
                  if (apt.isToday && (apt.isCheckedIn || apt.isWaiting || apt.isCalled || apt.isInConsultation)) ...[
                    Row(
                      children: [
                        // Current Running Token
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Current With Doctor', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Text(
                                    apt.currentRunningToken != null ? '#${apt.currentRunningToken}' : 'None',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                  Text(
                                    apt.queuePaused ? 'Queue is paused' : 'In Consultation Room',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Queue Position
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Your Position', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Text(
                                    apt.isInConsultation
                                        ? 'Now'
                                        : (apt.isCalled ? 'Called!' : (apt.queuePosition != null ? '#${apt.queuePosition}' : '-')),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: apt.isCalled ? AppTheme.warningOrange : AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    apt.patientsAhead != null ? '${apt.patientsAhead} ahead of you' : 'In waiting list',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Estimated Waiting Time
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Estimated Wait', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Text(
                                    apt.isInConsultation
                                        ? '0 min'
                                        : (apt.estimatedWaitMinutes != null ? '~${apt.estimatedWaitMinutes}m' : '-'),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentGreen,
                                    ),
                                  ),
                                  const Text('Estimated approx.', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else if (apt.isBooked) ...[
                    // Notice when booked but not checked-in yet
                    Card(
                      color: const Color(0xFFEFF6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: AppTheme.primaryBlue, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Check-in Required at Reception',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryDarkBlue),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'When you reach Prakash Homeo Hall, please check-in with the receptionist to activate your queue position.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Non-guaranteed disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: AppTheme.textMuted),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated waiting time is calculated based on current active patients. Consultation times may vary based on clinical requirements.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cancellation Button (only if not completed/cancelled)
                  if (!apt.isCompleted && !apt.isCancelled && !apt.isInConsultation) ...[
                    OutlinedButton.icon(
                      onPressed: _showCancelDialog,
                      icon: const Icon(Icons.cancel_outlined, color: AppTheme.dangerRed),
                      label: const Text('Cancel My Appointment', style: TextStyle(color: AppTheme.dangerRed)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.dangerRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/storage/local_storage.dart';
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
  String? _recentBooking;

  @override
  void initState() {
    super.initState();
    _initBookingCode();
  }

  void _initBookingCode() async {
    final recent = await LocalStorage.getLastBookingId();
    if (mounted) {
      setState(() {
        _recentBooking = recent;
      });
    }

    final codeToTrack = (widget.initialBookingCode != null && widget.initialBookingCode!.isNotEmpty)
        ? widget.initialBookingCode!
        : recent;

    if (codeToTrack != null && codeToTrack.isNotEmpty) {
      _codeController.text = codeToTrack;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<TrackingProvider>().startTracking(codeToTrack);
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
      LocalStorage.saveLastBookingId(code);
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    'सुरक्षा सत्यापन: बुकिंग करते समय दिया गया 10-अंकों का मोबाइल नंबर दर्ज करें:',
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
                      prefixText: '+91 ',
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
                              content: Text('Appointment has been cancelled successfully. Time slot released.'),
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _codeController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: 'Enter Booking ID',
                                  hintText: 'PHH-261118-001',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.content_paste, size: 20),
                                    tooltip: 'Paste Copied Booking ID',
                                    onPressed: () async {
                                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                                      if (data?.text != null && data!.text!.trim().isNotEmpty) {
                                        setState(() {
                                          _codeController.text = data.text!.trim().toUpperCase();
                                        });
                                        _search();
                                      }
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                onSubmitted: (_) => _search(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: prov.isLoading ? null : _search,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
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
                        if (_recentBooking != null && _recentBooking!.isNotEmpty && _recentBooking != _codeController.text) ...[
                          const SizedBox(height: 10),
                          ActionChip(
                            avatar: const Icon(Icons.history, size: 16, color: AppTheme.primaryBlue),
                            label: Text('Recent: $_recentBooking (1-Tap Track)', style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppTheme.primaryLightBlue,
                            onPressed: () {
                              setState(() {
                                _codeController.text = _recentBooking!;
                              });
                              _search();
                            },
                          ),
                        ],
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
                      borderRadius: BorderRadius.circular(14),
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

                // Live Content
                if (apt != null) ...[
                  // Live Sync Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Status • ${apt.appointmentDate}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                      ),
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
                            Text('Syncing every 5s', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Call Alert Banner (If patient called to room)
                  if (apt.isCalled) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.door_front_door_rounded, color: Colors.white, size: 36),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'YOUR TOKEN HAS BEEN CALLED!',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'डॉक्टर ने आपको बुलाया है। कृपया तुरंत कंसल्टेशन रूम में प्रवेश करें।',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else if (apt.isInConsultation) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryBlue),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.medical_information, color: AppTheme.primaryBlue, size: 32),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'आप वर्तमान में डॉ. ओम प्रकाश के साथ परामर्श (Consultation) में हैं।',
                              style: TextStyle(color: AppTheme.primaryDarkBlue, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Visual Flow Step Progress Bar
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Consultation Progress / परामर्श स्थिति', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _buildStepIndicator('Booked', apt.isBooked || apt.isCheckedIn || apt.isCalled || apt.isInConsultation || apt.isCompleted, Icons.check),
                              _buildStepConnector(apt.isCheckedIn || apt.isCalled || apt.isInConsultation || apt.isCompleted),
                              _buildStepIndicator('Checked In', apt.isCheckedIn || apt.isCalled || apt.isInConsultation || apt.isCompleted, Icons.how_to_reg),
                              _buildStepConnector(apt.isCalled || apt.isInConsultation || apt.isCompleted),
                              _buildStepIndicator('Called', apt.isCalled || apt.isInConsultation || apt.isCompleted, Icons.volume_up),
                              _buildStepConnector(apt.isInConsultation || apt.isCompleted),
                              _buildStepIndicator('In Room', apt.isInConsultation || apt.isCompleted, Icons.meeting_room),
                              _buildStepConnector(apt.isCompleted),
                              _buildStepIndicator('Done', apt.isCompleted, Icons.done_all),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Big Token Badge Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () {
                              final token = apt.tokenNumber ?? 1;
                              Clipboard.setData(ClipboardData(text: 'Token #$token - Booking: ${apt.bookingId}'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('टोकन नंबर #$token कॉपी हो गया! 📋'),
                                  backgroundColor: AppTheme.primaryBlue,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 105,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('YOUR TOKEN', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                      SizedBox(width: 4),
                                      Icon(Icons.copy, size: 10, color: Colors.white70),
                                    ],
                                  ),
                                  Text(
                                    apt.tokenNumber != null ? '#${apt.tokenNumber}' : '--',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    apt.status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  apt.patientName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: apt.bookingId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('बुकिंग कोड (${apt.bookingId}) कॉपी हो गया! 📋'),
                                        backgroundColor: AppTheme.accentGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('ID: ${apt.bookingId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryDarkBlue)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.copy, size: 13, color: AppTheme.primaryBlue),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Slot Time: ${apt.appointmentTime} (15m)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: apt.statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    apt.statusDisplay,
                                    style: TextStyle(color: apt.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Queue Position & Waiting Time Grid (for Today's active appointments)
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
                                  const Text('With Doctor', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
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
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
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
                                  const Text('Queue Position', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
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
                                    apt.patientsAhead != null ? '${apt.patientsAhead} ahead of you' : 'In queue',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Estimated Wait Time
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Estimated Wait', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
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
                                  const Text('Approximate', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ] else if (apt.isBooked) ...[
                    // Not Checked-In Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.how_to_reg, color: AppTheme.primaryBlue, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'रिसेप्शन पर चेक-इन अनिवार्य है',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryDarkBlue),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'क्लिनिक पहुँचकर कृपया रिसेप्शन पर अपना टोकन नंबर बताएं ताकि डॉक्टर के डैशबोर्ड में आपकी कतार स्थिति सक्रिय हो सके।',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Cancellation Option (Verified)
                  if (!apt.isCompleted && !apt.isCancelled && !apt.isInConsultation) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _showCancelDialog,
                      icon: const Icon(Icons.cancel_outlined, color: AppTheme.dangerRed, size: 18),
                      label: const Text('Cancel My Appointment / अपॉइंटमेंट रद्द करें', style: TextStyle(color: AppTheme.dangerRed)),
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

  Widget _buildStepIndicator(String label, bool isDone, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone ? AppTheme.accentGreen : const Color(0xFFE2E8F0),
          child: Icon(icon, size: 14, color: isDone ? Colors.white : AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? AppTheme.textDark : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? AppTheme.accentGreen : const Color(0xFFE2E8F0),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      ),
    );
  }
}

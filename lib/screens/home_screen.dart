import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/storage/local_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/server_settings_dialog.dart';
import '../providers/clinic_provider.dart';
import '../providers/tv_queue_provider.dart';
import 'auth/login_screen.dart';
import 'patient/booking_screen.dart';
import 'patient/tracking_screen.dart';
import 'tv/tv_display_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _trackInputController = TextEditingController();
  String? _lastBookingId;

  @override
  void initState() {
    super.initState();
    _checkLastBooking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicProvider>().fetchClinicInfo();
      context.read<TvQueueProvider>().startPolling();
    });
  }

  Future<void> _checkLastBooking() async {
    final id = await LocalStorage.getLastBookingId();
    if (mounted && id != null && id.isNotEmpty) {
      setState(() {
        _lastBookingId = id;
      });
    }
  }

  @override
  void dispose() {
    _trackInputController.dispose();
    try {
      context.read<TvQueueProvider>().stopPolling();
    } catch (_) {}
    super.dispose();
  }

  void _showTrackDialog({String? presetCode}) async {
    final recentBooking = await LocalStorage.getLastBookingId();
    if (presetCode != null && presetCode.isNotEmpty) {
      _trackInputController.text = presetCode;
    } else if (recentBooking != null && recentBooking.isNotEmpty && _trackInputController.text.isEmpty) {
      _trackInputController.text = recentBooking;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryLightBlue,
                child: Icon(Icons.search, color: AppTheme.primaryBlue, size: 20),
              ),
              SizedBox(width: 12),
              Text('Track Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your Booking ID (जैसे: PHH-261118-001) to view live token & queue position:',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _trackInputController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'PHH-XXXXXX-XXX',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste, size: 20),
                    tooltip: 'Paste from Clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null && data!.text!.trim().isNotEmpty) {
                        setDialogState(() {
                          _trackInputController.text = data.text!.trim().toUpperCase();
                        });
                      }
                    },
                  ),
                ),
              ),
              if (recentBooking != null && recentBooking.isNotEmpty) ...[
                const SizedBox(height: 12),
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16, color: AppTheme.primaryBlue),
                  label: Text('Use Recent: $recentBooking', style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppTheme.primaryLightBlue,
                  onPressed: () {
                    setDialogState(() {
                      _trackInputController.text = recentBooking;
                    });
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final code = _trackInputController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackingScreen(initialBookingCode: code),
                    ),
                  );
                }
              },
              child: const Text('Track Live Status'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicProv = context.watch<ClinicProvider>();
    final tvProv = context.watch<TvQueueProvider>();
    final info = clinicProv.clinicInfo;
    final queue = tvProv.liveQueue;
    final isPaused = queue?.queuePaused ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info?.clinicName ?? 'Prakash Homeo Hall',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  'Online Booking & Live Queue',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server API Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ServerSettingsDialog(),
              );
            },
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            icon: const Icon(Icons.shield_outlined, size: 16),
            label: const Text('Staff Login'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await clinicProv.fetchClinicInfo();
          await tvProv.fetchLiveQueue();
          await _checkLastBooking();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Doctor & Clinic Modern Profile Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.tvAccentCyan, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 34,
                                backgroundColor: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                child: const Icon(Icons.person_rounded, size: 40, color: AppTheme.tvAccentCyan),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        info?.doctorName ?? 'Dr. Navneet Srivastava',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified, color: AppTheme.tvAccentCyan, size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    info?.qualification ?? 'B.H.M.S. (Senior Homeopathic Consultant)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.tvAccentCyan,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildTag('Classical Homeopathy'),
                                      _buildTag('Chronic Illness Care'),
                                      _buildTag('Fatehpur, U.P.'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 28),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppTheme.tvAccentCyan, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                info?.address ?? 'Chowk, Chandiyana, Fatehpur, Uttar Pradesh - 212601',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.schedule, color: AppTheme.tvAccentGreen, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'OPD: Morning 10:00 AM - 01:00 PM  |  Evening 05:00 PM - 08:00 PM',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Active Saved Booking Shortcut (If available)
                  if (_lastBookingId != null && _lastBookingId!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined, color: AppTheme.primaryBlue, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Active Appointment',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDarkBlue),
                                ),
                                Text(
                                  'Booking ID: $_lastBookingId',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _showTrackDialog(presetCode: _lastBookingId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Track Token', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 3. Live Queue Radar Card (Auto updates every 5s)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isPaused ? AppTheme.warningOrange : const Color(0xFFBBF7D0),
                        width: 1.5,
                      ),
                    ),
                    color: isPaused ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPaused ? AppTheme.warningOrange : AppTheme.accentGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isPaused ? 'OPD Queue Status: PAUSED' : 'Live Clinic OPD Queue',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isPaused ? const Color(0xFFB45309) : const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFDCFCE7)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync, size: 12, color: AppTheme.accentGreen),
                                    SizedBox(width: 4),
                                    Text('Live 5s', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              // Current Token
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Current Token', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        queue?.currentToken != null ? '#${queue!.currentToken}' : '--',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      Text(
                                        queue?.currentPatientStatus == 'in_consultation'
                                            ? 'With Doctor'
                                            : (queue?.currentPatientStatus == 'called' ? 'Called to Room' : 'Doctor Ready'),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Next Token
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Next Token', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        queue?.nextToken != null ? '#${queue!.nextToken}' : '--',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.accentDarkGreen,
                                        ),
                                      ),
                                      const Text('Be Ready', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // In Waiting
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('In Waiting', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${queue?.waitingCount ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.warningOrange,
                                        ),
                                      ),
                                      const Text('In Clinic', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Quick Action Hub (Easy 1-tap Big Cards)
                  const Text(
                    'Quick Actions / त्वरित सेवाएं',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Action 1: Book Appointment
                      Expanded(
                        child: _buildActionTile(
                          context,
                          title: 'Book Appointment',
                          subtitle: 'ऑनलाइन अपॉइंटमेंट लें',
                          badge: '3 Steps',
                          icon: Icons.calendar_month_rounded,
                          gradient: AppTheme.primaryGradient,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookingScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Action 2: Track Appointment
                      Expanded(
                        child: _buildActionTile(
                          context,
                          title: 'Track My Token',
                          subtitle: 'लाइव टोकन स्थिति देखें',
                          badge: 'Live 5s',
                          icon: Icons.my_location_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () => _showTrackDialog(presetCode: _lastBookingId),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Action 3: TV Display Screen
                      Expanded(
                        child: _buildActionTile(
                          context,
                          title: 'Clinic TV Display',
                          subtitle: 'वेटिंग हॉल टीवी स्क्रीन',
                          badge: 'HD Mode',
                          icon: Icons.tv_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TvDisplayScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Action 4: Staff Portal (Doctor & Reception)
                      Expanded(
                        child: _buildActionTile(
                          context,
                          title: 'Staff Portal',
                          subtitle: 'डॉक्टर एवं रिसेप्शन लॉगिन',
                          badge: 'Secure',
                          icon: Icons.lock_person_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 5. How It Works (Simple 4-Step Patient Guide)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.help_outline_rounded, color: AppTheme.primaryBlue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'How Online Booking Works / अपॉइंटमेंट कैसे लें?',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildStepRow('1', 'स्लॉट चुनें', 'अपनी सुविधानुसार तारीख और 15-मिनट का टाइम स्लॉट चुनें।'),
                          _buildStepRow('2', 'टोकन प्राप्त करें', 'बुकिंग होते ही आपको बुकिंग कोड एवं दैनिक टोकन नंबर मिलेगा।'),
                          _buildStepRow('3', 'क्लिनिक में चेक-इन', 'क्लिनिक पहुँचकर रिसेप्शन पर अपना टोकन नंबर बताएं।'),
                          _buildStepRow('4', 'कंसल्टेशन', 'लाइव स्क्रीन या फोन पर अपना नंबर आने पर डॉक्टर रूम में प्रवेश करें।', isLast: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String title, String desc, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primaryLightBlue,
            child: Text(
              number,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDarkBlue),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                const SizedBox(height: 1),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

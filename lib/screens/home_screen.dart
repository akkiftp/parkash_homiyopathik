import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicProvider>().fetchClinicInfo();
      context.read<TvQueueProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    _trackInputController.dispose();
    try {
      context.read<TvQueueProvider>().stopPolling();
    } catch (_) {}
    super.dispose();
  }

  void _showTrackDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.search, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text('Track Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Booking ID (e.g. PHH-261117-001) to view real-time queue position:',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _trackInputController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'PHH-XXXXXX-XXX',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
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
            child: const Text('Track Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicProv = context.watch<ClinicProvider>();
    final tvProv = context.watch<TvQueueProvider>();
    final info = clinicProv.clinicInfo;
    final queue = tvProv.liveQueue;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_hospital, color: AppTheme.primaryBlue, size: 22),
            ),
            const SizedBox(width: 10),
            Text(info?.clinicName ?? 'Prakash Homeo Hall'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Server Settings',
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
            icon: const Icon(Icons.lock_person_outlined, size: 18),
            label: const Text('Staff Login'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await clinicProv.fetchClinicInfo();
          await tvProv.fetchLiveQueue();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Doctor & Clinic Hero Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                                child: const Icon(Icons.medical_services_rounded, size: 36, color: AppTheme.primaryBlue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      info?.doctorName ?? 'Dr. Om Prakash',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      info?.qualification ?? 'B.H.M.S. (Senior Homeopathic Consultant)',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryDarkBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      info?.specialization ?? 'Classical Homeopathy & Chronic Care',
                                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  info?.address ?? 'Chowk, Chandiyana, Fatehpur, Uttar Pradesh - 212601',
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.access_time_outlined, size: 18, color: AppTheme.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'OPD: Morning 10:00 AM - 01:00 PM | Evening 05:00 PM - 08:00 PM',
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Live Queue Status Banner (Auto-updates every 5s)
                  Card(
                    color: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFBBF7D0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
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
                                      color: (queue?.queuePaused ?? false)
                                          ? AppTheme.warningOrange
                                          : AppTheme.accentGreen,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    (queue?.queuePaused ?? false) ? 'OPD Queue: PAUSED' : 'Live OPD Queue Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: (queue?.queuePaused ?? false)
                                          ? AppTheme.warningOrange
                                          : const Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                    Text('Live 5s', style: TextStyle(fontSize: 11, color: AppTheme.accentGreen)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Current Token', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        queue?.currentToken != null ? '#${queue!.currentToken}' : 'None',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                      Text(
                                        queue?.currentPatientStatus == 'in_consultation'
                                            ? 'In Consultation'
                                            : (queue?.currentPatientStatus == 'called' ? 'Called' : 'Idle'),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Next Token', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        queue?.nextToken != null ? '#${queue!.nextToken}' : 'None',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const Text('Ready to enter', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('In Waiting', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${queue?.waitingCount ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.warningOrange,
                                        ),
                                      ),
                                      const Text('Patients in clinic', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
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

                  // 3. Primary Action Buttons Grid
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookingScreen()),
                            );
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Book Appointment'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showTrackDialog,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Track Appointment'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 4. Clinic TV Queue Display Link Button
                  Card(
                    color: AppTheme.tvBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TvDisplayScreen()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Icon(Icons.tv, color: AppTheme.tvAccentCyan, size: 28),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Launch Clinic TV Waiting Queue Display',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Full screen high contrast display designed for waiting room TV',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Why Homeopathy & Clinic Info Notes
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About Prakash Homeo Hall',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Prakash Homeo Hall provides holistic and individualized homeopathic healthcare for acute and chronic conditions in Fatehpur, Uttar Pradesh. Using classical Hahnemannian principles, our clinic ensures gentle, safe, and effective treatment for all age groups.',
                            style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: AppTheme.primaryBlue),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Please arrive 10 minutes prior to your time slot and complete check-in at the reception desk to join the active doctor queue.',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
}

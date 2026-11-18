import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../home_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().startPolling();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DoctorProvider>();
    final data = prov.dashboardData;
    final summary = data?.summary ?? {};
    final isPaused = data?.queuePaused ?? false;
    final currentPatient = data?.currentPatient;
    final calledPatient = data?.calledPatient;
    final waitingList = data?.waitingList ?? [];
    final allToday = data?.allToday ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Dr. Om Prakash (B.H.M.S.)', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
        actions: [
          // Live Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.symmetric(vertical: 12),
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
                Text('5s Sync', style: TextStyle(fontSize: 11, color: Color(0xFF166534))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.fetchDashboard(showLoadingIndicator: true),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryBlue,
          tabs: [
            Tab(
              icon: const Icon(Icons.room_preferences_outlined, size: 20),
              text: 'Active OPD & Queue (${waitingList.length})',
            ),
            Tab(
              icon: const Icon(Icons.list_alt, size: 20),
              text: "All Today (${allToday.length})",
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Action Feedback Banners
                if (prov.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
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
                          child: Text(prov.errorMessage!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],

                if (prov.actionSuccessMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.accentGreen),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(prov.actionSuccessMessage!, style: const TextStyle(color: Color(0xFF166534), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Queue Control Header (Pause / Resume)
                Card(
                  color: isPaused ? const Color(0xFFFFFBEB) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: isPaused ? const Color(0xFFFCD34D) : const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPaused ? const Color(0xFFF59E0B).withValues(alpha: 0.2) : const Color(0xFF10B981).withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            isPaused ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: isPaused ? AppTheme.warningOrange : AppTheme.accentGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPaused ? 'Queue is Currently PAUSED' : 'Queue is ACTIVE & RUNNING',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isPaused ? const Color(0xFFB45309) : const Color(0xFF15803D),
                                ),
                              ),
                              Text(
                                isPaused ? 'Calling new patients is blocked until resumed' : 'Patients can be called normally',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (isPaused) {
                              prov.resumeQueue();
                            } else {
                              prov.pauseQueue();
                            }
                          },
                          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 18),
                          label: Text(isPaused ? 'Resume Queue' : 'Pause Queue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPaused ? AppTheme.accentGreen : AppTheme.warningOrange,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Summary Cards Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 700 ? 6 : (width > 400 ? 3 : 2);
                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.5,
                      children: [
                        _buildSummaryCard('Today Total', '${summary['total_today'] ?? 0}', Icons.calendar_month, AppTheme.textDark),
                        _buildSummaryCard('In Waiting', '${summary['waiting_count'] ?? 0}', Icons.people, AppTheme.warningOrange),
                        _buildSummaryCard('Completed', '${summary['completed_today'] ?? 0}', Icons.check_circle, AppTheme.accentGreen),
                        _buildSummaryCard('Current', currentPatient != null ? '#${currentPatient.tokenNumber}' : 'None', Icons.person_pin, AppTheme.primaryBlue),
                        _buildSummaryCard('Upcoming', '${summary['upcoming_count'] ?? 0}', Icons.schedule, AppTheme.textMuted),
                        _buildSummaryCard('Cancelled', '${summary['cancelled_count'] ?? 0}', Icons.cancel, AppTheme.dangerRed),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 3. Tab Views: Active OPD vs All Today
                SizedBox(
                  height: 650,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB 1: Active Consultation Room & Waiting List
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // SECTION A: Current In-Consultation Patient Card
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                              ),
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
                                            Icon(Icons.meeting_room, color: AppTheme.primaryBlue),
                                            SizedBox(width: 8),
                                            Text(
                                              'Current In Consultation Room',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDarkBlue),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: currentPatient != null ? AppTheme.primaryBlue : Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            currentPatient != null ? 'IN CONSULTATION' : 'ROOM EMPTY',
                                            style: TextStyle(
                                              color: currentPatient != null ? Colors.white : Colors.grey.shade700,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    if (currentPatient != null) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '#${currentPatient.tokenNumber}',
                                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  currentPatient.patientName,
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 2),
                                                Text('Mobile: +91 ${currentPatient.mobile}', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                                                Text('Booking: ${currentPatient.bookingId} (${currentPatient.appointmentTime})', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                                if (currentPatient.notes != null && currentPatient.notes!.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text('Symptoms: "${currentPatient.notes}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: 8,
                                        children: [
                                          ElevatedButton.icon(
                                            onPressed: () => prov.completeConsultation(currentPatient.id!),
                                            icon: const Icon(Icons.done_all, size: 18),
                                            label: const Text('Complete Consultation'),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => prov.skipPatient(currentPatient.id!),
                                            icon: const Icon(Icons.skip_next, size: 18),
                                            label: const Text('Skip Patient'),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => prov.markNoShow(currentPatient.id!),
                                            icon: const Icon(Icons.person_off, size: 18, color: AppTheme.dangerRed),
                                            label: const Text('Mark No-Show', style: TextStyle(color: AppTheme.dangerRed)),
                                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.dangerRed)),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        child: Center(
                                          child: Text(
                                            'No patient in consultation right now. Call the next waiting patient below.',
                                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // SECTION B: Called Patient (If any is standing by outside door)
                            if (calledPatient != null) ...[
                              Card(
                                color: const Color(0xFFFAF5FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: Color(0xFFD8B4FE)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '#${calledPatient.tokenNumber}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Called to Room: ${calledPatient.patientName}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF6B21A8)),
                                            ),
                                            Text('Waiting to enter room | Called at: ${calledPatient.calledAt ?? "Just now"}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => prov.startConsultation(calledPatient.id!),
                                        icon: const Icon(Icons.play_arrow, size: 18),
                                        label: const Text('Start Consultation'),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // SECTION C: Waiting Queue List
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Waiting Patients Queue (${waitingList.length})',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                        ),
                                        const Text(
                                          'Checked-in at Reception',
                                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    if (waitingList.isEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 30),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              Icon(Icons.people_outline, size: 40, color: AppTheme.textMuted),
                                              SizedBox(height: 8),
                                              Text('No patients waiting in queue.', style: TextStyle(color: AppTheme.textMuted)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: waitingList.length,
                                        separatorBuilder: (_, _) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final p = waitingList[index];
                                          return ListTile(
                                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                            leading: CircleAvatar(
                                              backgroundColor: AppTheme.warningOrange.withValues(alpha: 0.15),
                                              child: Text(
                                                '#${p.tokenNumber}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                                              ),
                                            ),
                                            title: Text(p.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            subtitle: Text('${p.bookingId} • Slot: ${p.appointmentTime} • Checked-in: ${p.checkedInAt ?? "Recent"}', style: const TextStyle(fontSize: 12)),
                                            trailing: ElevatedButton.icon(
                                              onPressed: isPaused ? null : () => prov.callPatient(p.id!),
                                              icon: const Icon(Icons.volume_up, size: 16),
                                              label: const Text('Call Patient'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                backgroundColor: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TAB 2: All Today's Appointments History
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: allToday.isEmpty
                              ? const Center(child: Text('No appointments recorded today.'))
                              : ListView.separated(
                                  itemCount: allToday.length,
                                  separatorBuilder: (_, _) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final item = allToday[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: item.statusColor.withValues(alpha: 0.12),
                                        child: Text(
                                          item.tokenNumber != null ? '#${item.tokenNumber}' : '-',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: item.statusColor),
                                        ),
                                      ),
                                      title: Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${item.bookingId} • ${item.appointmentTime} • Mobile: ${item.mobile}'),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: item.statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          item.statusDisplay,
                                          style: TextStyle(color: item.statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                Icon(icon, size: 14, color: color),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

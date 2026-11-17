import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/tv_queue_provider.dart';

class TvDisplayScreen extends StatefulWidget {
  const TvDisplayScreen({super.key});

  @override
  State<TvDisplayScreen> createState() => _TvDisplayScreenState();
}

class _TvDisplayScreenState extends State<TvDisplayScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TvQueueProvider>().startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TvQueueProvider>();
    final queue = prov.liveQueue;
    final isPaused = queue?.queuePaused ?? false;

    final currentTimeStr = DateFormat('hh:mm:ss a').format(DateTime.now());
    final currentDateStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.tvBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Clinic Waiting Room Queue Display', style: TextStyle(color: Colors.white70, fontSize: 16)),
        actions: [
          IconButton(
            tooltip: 'Close TV Display',
            icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top TV Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.tvCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.tvAccentCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_hospital, color: AppTheme.tvAccentCyan, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            queue?.clinicName ?? 'Prakash Homeo Hall',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${queue?.doctorName ?? "Dr. Om Prakash"} • ${queue?.specialization ?? "Classical Homeopathy"}',
                            style: const TextStyle(
                              color: AppTheme.tvAccentCyan,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currentTimeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentDateStr,
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Queue Paused Alert Banner
            if (isPaused) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF78350F),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.warningOrange, width: 2),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pause_circle_filled, color: AppTheme.warningOrange, size: 32),
                    SizedBox(width: 14),
                    Text(
                      'DOCTOR CONSULTATION QUEUE IS TEMPORARILY PAUSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Main Tokens Hero Section
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  // Box 1: NOW IN CONSULTATION ROOM (Primary Focus)
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0C4A6E),
                            AppTheme.tvCardBackground,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.tvAccentCyan, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tvAccentCyan.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.tvAccentCyan,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room, color: Color(0xFF0F172A), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  queue?.currentPatientStatus == 'called' ? 'PATIENT CALLED TO ROOM' : 'CURRENT CONSULTATION',
                                  style: const TextStyle(
                                    color: Color(0xFF0F172A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'TOKEN NUMBER',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            child: Text(
                              queue?.currentToken != null ? '#${queue!.currentToken}' : '--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 100,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            queue?.currentPatientStatus == 'called'
                                ? 'PLEASE ENTER CONSULTATION ROOM'
                                : (queue?.currentToken != null ? 'CONSULTATION IN PROGRESS' : 'WAITING FOR DOCTOR'),
                            style: TextStyle(
                              color: queue?.currentPatientStatus == 'called' ? AppTheme.tvAccentGreen : AppTheme.tvAccentCyan,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Box 2: NEXT TOKEN READY
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.tvCardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.tvAccentGreen.withOpacity(0.6), width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.tvAccentGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: AppTheme.tvAccentGreen),
                            ),
                            child: const Text(
                              'NEXT IN LINE',
                              style: TextStyle(
                                color: AppTheme.tvAccentGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'TOKEN NUMBER',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            child: Text(
                              queue?.nextToken != null ? '#${queue!.nextToken}' : '--',
                              style: const TextStyle(
                                color: AppTheme.tvAccentGreen,
                                fontSize: 72,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'PLEASE BE READY NEAR ROOM',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Waiting Queue Strip
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.tvCardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt, color: Colors.white70, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'WAITING QUEUE TOKENS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${queue?.waitingCount ?? 0} Patients',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Icon(Icons.sync, size: 14, color: AppTheme.tvAccentGreen),
                            SizedBox(width: 4),
                            Text('Live Refresh 5s', style: TextStyle(color: AppTheme.tvAccentGreen, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),
                    Expanded(
                      child: (queue?.waitingTokens == null || queue!.waitingTokens.isEmpty)
                          ? const Center(
                              child: Text(
                                'No other patients currently waiting in queue.',
                                style: TextStyle(color: Colors.white38, fontSize: 14),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: queue.waitingTokens.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final tok = queue.waitingTokens[index];
                                final isNext = tok == queue.nextToken;
                                return Container(
                                  width: 90,
                                  decoration: BoxDecoration(
                                    color: isNext ? AppTheme.tvAccentGreen.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isNext ? AppTheme.tvAccentGreen : Colors.white24,
                                      width: isNext ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'TOKEN',
                                        style: TextStyle(
                                          color: isNext ? AppTheme.tvAccentGreen : Colors.white60,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '#$tok',
                                        style: TextStyle(
                                          color: isNext ? AppTheme.tvAccentGreen : Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

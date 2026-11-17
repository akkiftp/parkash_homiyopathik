import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import 'tracking_screen.dart';

class ConfirmationScreen extends StatelessWidget {
  final AppointmentModel appointment;

  const ConfirmationScreen({super.key, required this.appointment});

  void _shareSlip(BuildContext context) {
    final text = '''
=================================
PRAKASH HOMEO HALL - APPOINTMENT SLIP
=================================
Booking ID: ${appointment.bookingId}
Token Number: #${appointment.tokenNumber ?? 'N/A'}
Patient Name: ${appointment.patientName}
Doctor: ${appointment.doctorName ?? 'Dr. Om Prakash'} (B.H.M.S.)
Specialization: Classical Homeopathy
Date: ${appointment.appointmentDate}
Time: ${appointment.appointmentTime}
Clinic: ${appointment.clinicName ?? 'Prakash Homeo Hall'}
Address: ${appointment.address ?? 'Chowk, Chandiyana, Fatehpur, Uttar Pradesh - 212601'}
=================================
Please show this slip at the reception upon arrival.
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment slip details copied to clipboard! You can paste or save it.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.popUntil(context, (route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Booking Confirmed'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentGreen,
                          ),
                          child: const Icon(Icons.check, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Appointment Booked Successfully!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your time slot has been secured in the doctor schedule.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF15803D)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Slip Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Booking Code Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Booking ID', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                    const SizedBox(height: 2),
                                    Text(
                                      appointment.bookingId,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                if (appointment.tokenNumber != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text('TOKEN', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                                        Text(
                                          '#${appointment.tokenNumber}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildDetailRow('Patient Name', appointment.patientName, icon: Icons.person_outline),
                          _buildDetailRow('Mobile Number', '+91 ${appointment.mobile}', icon: Icons.phone_outlined),
                          _buildDetailRow('Doctor', appointment.doctorName ?? 'Dr. Om Prakash (B.H.M.S.)', icon: Icons.medical_services_outlined),
                          _buildDetailRow('Appointment Date', appointment.appointmentDate, icon: Icons.calendar_today_outlined),
                          _buildDetailRow('Scheduled Time', appointment.appointmentTime, icon: Icons.access_time_outlined),
                          _buildDetailRow('Clinic', appointment.clinicName ?? 'Prakash Homeo Hall', icon: Icons.local_hospital_outlined),
                          _buildDetailRow('Address', appointment.address ?? 'Chowk, Chandiyana, Fatehpur, Uttar Pradesh', icon: Icons.location_on_outlined),

                          const Divider(height: 24),

                          // Notice
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Color(0xFFD97706)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Important: When you arrive at the clinic, please show this booking ID at the reception to check-in and join the live doctor consultation queue.',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrackingScreen(initialBookingCode: appointment.bookingId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Track Live Queue Status Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  ),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () => _shareSlip(context),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Download / Share Appointment Slip'),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

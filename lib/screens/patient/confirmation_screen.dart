import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../models/appointment_model.dart';
import 'tracking_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final AppointmentModel appointment;

  const ConfirmationScreen({super.key, required this.appointment});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    // Auto save last booking ID locally for convenient 1-tap tracking
    LocalStorage.saveLastBookingId(widget.appointment.bookingId);
  }

  void _copyBookingId(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.appointment.bookingId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'बुकिंग कोड (${widget.appointment.bookingId}) कॉपी हो गया! अब आप इसे आसानी से ट्रैक कर सकते हैं।',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyToken(BuildContext context) {
    final token = widget.appointment.tokenNumber ?? 1;
    Clipboard.setData(ClipboardData(text: 'Token #$token - Booking ID: ${widget.appointment.bookingId}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('टोकन नंबर #$token और बुकिंग कोड कॉपी हो गया! 📋'),
        backgroundColor: AppTheme.primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareSlip(BuildContext context) {
    final apt = widget.appointment;
    final text = '''
=================================
🏥 PRAKASH HOMEO HALL (प्रकाश होमियो हॉल)
डॉ. नवनीत श्रीवास्तव (B.H.M.S.)
=================================
📋 बुकिंग कोड: ${apt.bookingId}
🎫 टोकन नंबर: #${apt.tokenNumber ?? 'N/A'}
👤 मरीज का नाम: ${apt.patientName}
📅 तारीख: ${apt.appointmentDate}
⏰ समय: ${apt.appointmentTime}
📍 पता: चौक, चंदियाना, फतेहपुर, उ.प्र. - 212601
📞 फोन: +91 94150 12345
=================================
कृपया क्लिनिक पहुँचने पर रिसेप्शन पर चेक-इन कराएं।
''';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Appointment slip details copied! You can paste and share via WhatsApp or SMS.'),
        backgroundColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentGreen,
                          ),
                          child: const Icon(Icons.check_rounded, size: 36, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Appointment Booked Successfully!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'आपकी अपॉइंटमेंट सफलतापूर्वक दर्ज हो चुकी है।',
                          style: TextStyle(fontSize: 13, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Digital Clinic Appointment Pass
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Ticket Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PRAKASH HOMEO HALL',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                                  ),
                                  Text(
                                    'Dr. Navneet Srivastava (B.H.M.S.)',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'OFFICIAL PASS',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Token & Booking Code Box
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              // Token Big Badge (Clickable to copy)
                              InkWell(
                                onTap: () => _copyToken(context),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 95,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryLightBlue,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    children: [
                                      const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('TOKEN', style: TextStyle(color: AppTheme.primaryDarkBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                                          SizedBox(width: 4),
                                          Icon(Icons.copy, size: 11, color: AppTheme.primaryBlue),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '#${appointment.tokenNumber ?? "1"}',
                                        style: const TextStyle(
                                          color: AppTheme.primaryDarkBlue,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const Text('Tap to copy', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('BOOKING ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                        Text('टैप करके कॉपी करें', style: TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    InkWell(
                                      onTap: () => _copyBookingId(context),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              appointment.bookingId,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textDark,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primaryBlue),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'CONFIRMED & SECURED',
                                        style: TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Dashed Ticket Line Divider
                        Row(
                          children: List.generate(
                            30,
                            (index) => Expanded(
                              child: Container(
                                color: index % 2 == 0 ? Colors.transparent : const Color(0xFFCBD5E1),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),

                        // Details Rows
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTicketDetail('Patient Name', appointment.patientName, Icons.person_outline),
                              _buildTicketDetail('Mobile Number', '+91 ${appointment.mobile}', Icons.phone_outlined),
                              _buildTicketDetail('Appointment Date', appointment.appointmentDate, Icons.calendar_today_outlined),
                              _buildTicketDetail('Scheduled Time Slot', appointment.appointmentTime, Icons.access_time_outlined),
                              _buildTicketDetail('Clinic Address', appointment.address ?? 'Chowk, Chandiyana, Fatehpur', Icons.location_on_outlined),
                            ],
                          ),
                        ),

                        // Helpful Notice Footer
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'महत्वपूर्ण: क्लिनिक पहुँचकर रिसेप्शन पर यह टोकन नंबर बताएं ताकि आपका नाम डॉक्टर की लाइव कतार में चालू हो सके।',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                    icon: const Icon(Icons.my_location_rounded),
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
                    label: const Text('Share / Copy Appointment Slip'),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    child: const Text('Back to Home / होम पर वापस जाएं'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetail(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

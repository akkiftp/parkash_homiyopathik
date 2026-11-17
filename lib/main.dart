import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/clinic_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/reception_provider.dart';
import 'providers/tracking_provider.dart';
import 'providers/tv_queue_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const PrakashHomeoApp());
}

class PrakashHomeoApp extends StatelessWidget {
  const PrakashHomeoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClinicProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => ReceptionProvider()),
        ChangeNotifierProvider(create: (_) => TvQueueProvider()),
      ],
      child: MaterialApp(
        title: 'Prakash Homeo Hall - Doctor Clinic & Queue',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

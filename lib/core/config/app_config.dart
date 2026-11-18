import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String defaultLocalhostUrl = 'http://127.0.0.1:8000/api';
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:8000/api';
  
  // Active Public HTTPS Live API URL
  static const String livePublicUrl = 'https://steep-yonder-blemish.ngrok-free.dev/api';
  
  static String _baseUrl = livePublicUrl;

  static String get baseUrl => _baseUrl;

  static const int pollingIntervalSeconds = 5;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('custom_base_url');

    if (kIsWeb) {
      // On Web (e.g. Firebase Hosting over HTTPS), localhost/127.0.0.1 causes Mixed-Content/CORS
      // browser blocks. Force live public HTTPS URL if saved URL is empty or localhost.
      if (savedUrl == null || savedUrl.contains('127.0.0.1') || savedUrl.contains('localhost')) {
        _baseUrl = livePublicUrl;
        await prefs.setString('custom_base_url', livePublicUrl);
        return;
      }
    }

    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _baseUrl = savedUrl.trim();
    } else {
      // Default to live public URL so phone, web and external visitors can access immediately
      _baseUrl = livePublicUrl;
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', _baseUrl);
  }
}

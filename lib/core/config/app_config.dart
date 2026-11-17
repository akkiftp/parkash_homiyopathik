import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String defaultLocalhostUrl = 'http://127.0.0.1:8000/api';
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:8000/api';
  
  static String _baseUrl = kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8000/api'
          : 'http://127.0.0.1:8000/api');

  static String get baseUrl => _baseUrl;

  static const int pollingIntervalSeconds = 5;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('custom_base_url');
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _baseUrl = savedUrl.trim();
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    _baseUrl = newUrl.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', _baseUrl);
  }
}

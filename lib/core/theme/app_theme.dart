import 'package:flutter/material.dart';

class AppTheme {
  // Primary Palette - Modern Clinical Blue & Emerald
  static const Color primaryBlue = Color(0xFF0284C7); // Sky 600
  static const Color primaryDarkBlue = Color(0xFF0369A1); // Sky 700
  static const Color primaryLightBlue = Color(0xFFE0F2FE); // Sky 100
  static const Color accentGreen = Color(0xFF10B981); // Emerald 500
  static const Color accentDarkGreen = Color(0xFF047857); // Emerald 700
  static const Color accentLightGreen = Color(0xFFD1FAE5); // Emerald 100
  
  static const Color warningOrange = Color(0xFFF59E0B); // Amber 500
  static const Color warningLightOrange = Color(0xFFFEF3C7);
  static const Color dangerRed = Color(0xFFEF4444); // Red 500
  static const Color dangerLightRed = Color(0xFFFEE2E2);
  
  static const Color surfaceLight = Color(0xFFF8FAFC); // Slate 50
  static const Color cardLight = Colors.white;
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200

  // TV Display Palette - Deep Navy Hospital Display
  static const Color tvBackground = Color(0xFF0B132B);
  static const Color tvCardBackground = Color(0xFF1C2541);
  static const Color tvCardBorder = Color(0xFF3A506B);
  static const Color tvAccentCyan = Color(0xFF38BDF8);
  static const Color tvAccentGreen = Color(0xFF4ADE80);
  static const Color tvAccentAmber = Color(0xFFFBBF24);

  // Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tvRoomGradient = LinearGradient(
    colors: [Color(0xFF075985), Color(0xFF0C4A6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: accentGreen,
      surface: surfaceLight,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: surfaceLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: textDark),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: dangerRed),
      ),
      labelStyle: const TextStyle(color: textMuted, fontSize: 14),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    ),
  );
}

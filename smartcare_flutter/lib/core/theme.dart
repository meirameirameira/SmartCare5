import 'package:flutter/material.dart';

class SmartCareTheme {
  static const primaryGreen = Color(0xFF2E7D5E);
  static const primaryGreenDark = Color(0xFF1B5C43);
  static const primaryGreenLight = Color(0xFFD4EDE4);
  static const accentBlue = Color(0xFF1976D2);
  static const dangerRed = Color(0xFFD32F2F);
  static const warnAmber = Color(0xFFF57C00);
  static const surface = Color(0xFFF7F9F8);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          surface: Colors.white,
          surfaceContainerHighest: surface,
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreenDark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: primaryGreenLight,
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        fontFamily: 'Roboto',
      );
}

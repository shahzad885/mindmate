import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF141829);
  static const Color card = Color(0xFF1E2340);

  // Accents
  static const Color primary = Color(0xFF7C6CF8);
  static const Color primaryLight = Color(0xFF9C8CF8);
  static const Color secondary = Color(0xFFF5A623);
  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFF25C5C);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B8FA8);

  // UI
  static const Color divider = Color(0xFF2A2F4A);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C6CF8), Color(0xFF9C8CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orbGradient = LinearGradient(
    colors: [Color(0xFF9C8CF8), Color(0xFF7C6CF8), Color(0xFF5A4ED1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow
  static Color primaryGlow = const Color(0xFF7C6CF8).withOpacity(0.3);
  static Color primaryGlowStrong = const Color(0xFF7C6CF8).withOpacity(0.5);
}

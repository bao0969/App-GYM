import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFE84E1B);
  static const Color primaryLight = Color(0xFFFF8C61);

  // Accent
  static const Color accent = Color(0xFF00D4FF);
  static const Color accentDark = Color(0xFF0099BB);

  // Background
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF141420);
  static const Color surfaceLight = Color(0xFF1E1E2E);
  static const Color card = Color(0xFF1A1A28);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textHint = Color(0xFF6B6B85);

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD740);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF40C4FF);

  // Role colors
  static const Color adminColor = Color(0xFFFF6B35);
  static const Color staffColor = Color(0xFFFFD740);
  static const Color trainerColor = Color(0xFF00D4FF);
  static const Color memberColor = Color(0xFF00E676);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E30), Color(0xFF141420)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Admin dashboard card gradients
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF0099BB), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF00897B), Color(0xFF00E676)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF7B1FA2), Color(0xFFBA68C8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

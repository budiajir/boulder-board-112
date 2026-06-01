import 'package:flutter/material.dart';

/// Boulder Board 112 design system color tokens.
/// Dark theme first — inspired by modern climbing apps.
class AppColors {
  AppColors._();

  // ─── Surface Colors ─────────────────────────────────────
  static const Color surface = Color(0xFF0D1117);
  static const Color surfaceVariant = Color(0xFF161B22);
  static const Color surfaceElevated = Color(0xFF1C2128);
  static const Color border = Color(0xFF30363D);

  // ─── Text Colors ────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textTertiary = Color(0xFF484F58);

  // ─── Accent Colors ──────────────────────────────────────
  static const Color accentPrimary = Color(0xFF58A6FF);
  static const Color accentGreen = Color(0xFF3FB950);
  static const Color accentBlue = Color(0xFF58A6FF);
  static const Color accentYellow = Color(0xFFD29922);
  static const Color accentRed = Color(0xFFF85149);
  static const Color accentLime = Color(0xFFA8FF3E);
  static const Color accentOrange = Color(0xFFF97316);

  // ─── Gradient ───────────────────────────────────────────
  static const Color gradientStart = Color(0xFF0D1117);
  static const Color gradientEnd = Color(0xFF111D2B);

  // ─── Hold Colors (semantic) ─────────────────────────────
  static const Color holdStart = accentGreen;
  static const Color holdHand = accentBlue;
  static const Color holdFoot = accentOrange;
  static const Color holdFinish = accentRed;
  static const Color holdInactive = Color(0xFF30363D);

  // ─── Misc ───────────────────────────────────────────────
  static const Color success = accentGreen;
  static const Color warning = accentYellow;
  static const Color error = accentRed;
  static const Color shimmer = Color(0xFF21262D);

  /// Background gradient used across many screens.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
}

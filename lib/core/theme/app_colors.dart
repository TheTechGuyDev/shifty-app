import 'package:flutter/material.dart';

/// Brand colours taken from the Figma style guide.
class AppColors {
  AppColors._();

  // Main colours
  static const Color primary = Color(0xFFFD6B22);
  static const Color dark = Color(0xFF1B1D21);
  static const Color disabled = Color(0xFFD9D9D9);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Accent / secondary
  static const Color blue = Color(0xFF3F8CFF);
  static const Color yellow = Color(0xFFFDB921);

  // Alerts
  static const Color warning = Color(0xFFFF6628);
  static const Color failed = Color(0xFFFF3D00);
  static const Color success = Color(0xFF4FBF67);

  // Text
  static const Color textBody = Color(0x80000000); // black 50%
  static const Color textMuted = Color(0x66000000);

  // Overlays
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
}

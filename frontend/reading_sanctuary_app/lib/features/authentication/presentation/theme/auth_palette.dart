import 'package:flutter/material.dart';

abstract final class AuthPalette {
  // Background pastel lavender
  static const Color backgroundLight = Color(0xFFDDD2F3);
  static const Color backgroundDark = Color(0xFFC5B4E4);

  // Card surfaces
  static const Color phoneBody = Color(0xFFFBF8F5);
  static const Color cardSurface = Color(0xFFFAF7F5);
  static const Color cardInner = Color(0xFFFFFFFF);

  // Input fields
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFEBE3D8);
  static const Color inputBorderFocused = Color(0xFFA291EA);

  // Accent & Buttons
  static const Color primaryPurple = Color(0xFF9E8DE5);
  static const Color primaryPurpleDark = Color(0xFF8873DA);
  static const Color iconBadge = Color(0xFFA594E8);
  static const Color iconColor = Colors.white;

  // Typography
  static const Color textDark = Color(0xFF383145);
  static const Color textMuted = Color(0xFF8C7F9B);
  static const Color textLink = Color(0xFF7360E2);
  static const Color eyeIcon = Color(0xFF9E95A8);

  // Divider
  static const Color dividerLine = Color(0xFFDFD6CD);

  // Shadows
  static const Color buttonShadow = Color(0xFF755ED6);
  static const Color cardShadow = Color(0x1F5C4BAF);
}

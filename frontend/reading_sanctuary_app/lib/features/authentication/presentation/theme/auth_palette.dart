import 'package:flutter/material.dart';

abstract final class AuthPalette {
  // Background porcelain lavender matching Home page
  static const Color backgroundLight = Color(0xFFF4F0FB);
  static const Color backgroundDark = Color(0xFFEDE5F8);

  // Card surfaces
  static const Color phoneBody = Color(0xFFF9F6FE);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardInner = Color(0xFFFFFFFF);

  // Input fields
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFEADBFA);
  static const Color inputBorderFocused = Color(0xFF9482E6);

  // Accent & Buttons matching Home page purple
  static const Color primaryPurple = Color(0xFF6B45B3);
  static const Color primaryPurpleDark = Color(0xFF523396);
  static const Color iconBadge = Color(0xFF9482E6);
  static const Color iconColor = Colors.white;

  // Typography matching Home page text tokens
  static const Color textDark = Color(0xFF2E1A48);
  static const Color textMuted = Color(0xFF7A6894);
  static const Color textLink = Color(0xFF6B45B3);
  static const Color eyeIcon = Color(0xFF7A6894);

  // Divider
  static const Color dividerLine = Color(0xFFEADBFA);

  // Shadows
  static const Color buttonShadow = Color(0x336B45B3);
  static const Color cardShadow = Color(0x1A4B3A75);
}

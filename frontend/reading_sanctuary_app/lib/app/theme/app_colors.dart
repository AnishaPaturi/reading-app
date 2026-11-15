import 'package:flutter/material.dart';

/// Unified AppColors styled to match the Home page aesthetic:
/// soft porcelain-lavender backgrounds, clean cards, primary purple accents, and plum typography.
abstract final class AppColors {
  static const spines = [
    Color(0xFFE05A7A), Color(0xFF7E57C2), Color(0xFF4FA3D9), Color(0xFFE6A23C),
    Color(0xFF5CB89A), Color(0xFFC77DDB), Color(0xFF6C7BDB), Color(0xFFE7826B),
  ];
  static const pot = Color(0xFFB5651D);

  // Surfaces aligned with Home Page (0xFFF4F0FB background, 0xFFF9F6FE card)
  static const espresso = Color(0xFFF4F0FB);
  static const walnut = Color(0xFFF4F0FB);
  static const secondary = Color(0xFFEDE5F8);
  static const card = Color(0xFFF9F6FE);

  static const ivory = Color(0xFFF4F0FB);
  static const parchment = Color(0xFFF9F6FE);
  static const cream = Color(0xFFEDE5F8);

  // Accents aligned with Home Page purple tokens
  static const gold = Color(0xFF6B45B3);
  static const bronze = Color(0xFF9482E6);
  static const brown = Color(0xFF6B45B3);

  // Typography aligned with Home Page (0xFF2E1A48 dark text, 0xFF7A6894 muted text)
  static const textLight = Color(0xFF2E1A48);
  static const textLightSecondary = Color(0xFF7A6894);
  static const textDark = Color(0xFF2E1A48);
  static const textDarkSecondary = Color(0xFF7A6894);

  // Highlight colours
  static const hlGold = Color(0xFFF2C265);
  static const hlSage = Color(0xFFA4DFD0);
  static const hlRose = Color(0xFFFF926B);
  static const hlLavender = Color(0xFFC4B1EB);
  static const hlBlue = Color(0xFFB4D8F8);
}

import 'package:flutter/material.dart';

/// Palette restyled to the reference app: charcoal-navy surfaces, orchid accent.
/// (Token names kept from Milestone 1; "gold" is now the orchid accent.)
abstract final class AppColors {
  static const spines = [
    Color(0xFFE05A7A), Color(0xFF7E57C2), Color(0xFF4FA3D9), Color(0xFFE6A23C),
    Color(0xFF5CB89A), Color(0xFFC77DDB), Color(0xFF6C7BDB), Color(0xFFE7826B),
  ];
  static const pot = Color(0xFFB5651D);

  static const espresso = Color(0xFF121219);
  static const walnut = Color(0xFF191923);
  static const secondary = Color(0xFF1F1F2B);
  static const card = Color(0xFF23232F);

  static const ivory = Color(0xFFFBF1F6);
  static const parchment = Color(0xFFF6DCE9);
  static const cream = Color(0xFFE6D3E0);

  static const gold = Color(0xFFC77DDB);
  static const bronze = Color(0xFF8E5AA8);
  static const brown = Color(0xFF8E3FA8);

  static const textLight = Color(0xFFF2EEF6);
  static const textLightSecondary = Color(0xFFA9A6B8);
  static const textDark = Color(0xFF2A2233);
  static const textDarkSecondary = Color(0xFF6E6479);

  // Highlight colours (used by the reader in a later milestone)
  static const hlGold = Color(0xFFC6A15B);
  static const hlSage = Color(0xFF8FA68A);
  static const hlRose = Color(0xFFC98B8B);
  static const hlLavender = Color(0xFFA99BC9);
  static const hlBlue = Color(0xFF7F9BB8);
}

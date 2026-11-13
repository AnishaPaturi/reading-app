import 'package:flutter/material.dart';

class BookshelfThemeOption {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final Color cardColor;
  final Color textColor;
  final Color shelfWoodColor;

  const BookshelfThemeOption({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.shelfWoodColor,
  });
}

class BookshelfThemes {
  static const darkAcademia = BookshelfThemeOption(
    id: 'dark_academia',
    name: 'Dark Academia',
    description: 'Espresso, walnut and antique gold',
    primaryColor: Color(0xFF2C221E),
    accentColor: Color(0xFFD4AF37),
    cardColor: Color(0xFF382C27),
    textColor: Color(0xFFF3EDE2),
    shelfWoodColor: Color(0xFF4A3728),
  );

  static const warmParchment = BookshelfThemeOption(
    id: 'warm_parchment',
    name: 'Warm Parchment',
    description: 'Ivory, beige and muted gold',
    primaryColor: Color(0xFFF5EFE6),
    accentColor: Color(0xFFB08968),
    cardColor: Color(0xFFEDE4D8),
    textColor: Color(0xFF2D234A),
    shelfWoodColor: Color(0xFFC7A78A),
  );

  static const enchantedForest = BookshelfThemeOption(
    id: 'enchanted_forest',
    name: 'Enchanted Forest',
    description: 'Sage, olive and forest green',
    primaryColor: Color(0xFF1B3227),
    accentColor: Color(0xFFA3B18A),
    cardColor: Color(0xFF274436),
    textColor: Color(0xFFEAF2ED),
    shelfWoodColor: Color(0xFF365343),
  );

  static const gothicRomance = BookshelfThemeOption(
    id: 'gothic_romance',
    name: 'Gothic Romance',
    description: 'Burgundy, wine and charcoal',
    primaryColor: Color(0xFF321319),
    accentColor: Color(0xFFD88373),
    cardColor: Color(0xFF461B23),
    textColor: Color(0xFFFBECEB),
    shelfWoodColor: Color(0xFF56212C),
  );

  static const midnightStars = BookshelfThemeOption(
    id: 'midnight_stars',
    name: 'Midnight Stars',
    description: 'Navy, indigo and celestial silver',
    primaryColor: Color(0xFF141A29),
    accentColor: Color(0xFF90B4CE),
    cardColor: Color(0xFF1E283E),
    textColor: Color(0xFFEDF2F7),
    shelfWoodColor: Color(0xFF2B3A59),
  );

  static const blushRose = BookshelfThemeOption(
    id: 'blush_rose',
    name: 'Blush Rose',
    description: 'Soft rose, mauve and cream',
    primaryColor: Color(0xFF3B252E),
    accentColor: Color(0xFFE8A5B8),
    cardColor: Color(0xFF50343F),
    textColor: Color(0xFFFCEFF3),
    shelfWoodColor: Color(0xFF674352),
  );

  static const List<BookshelfThemeOption> all = [
    darkAcademia,
    warmParchment,
    enchantedForest,
    gothicRomance,
    midnightStars,
    blushRose,
  ];

  static BookshelfThemeOption findById(String? id) {
    if (id == null) return darkAcademia;
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => darkAcademia,
    );
  }

  static Color parseHex(String? hexString, {Color fallback = const Color(0xFF2C221E)}) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceAll('#', '').replaceAll('0x', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  static String toHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}

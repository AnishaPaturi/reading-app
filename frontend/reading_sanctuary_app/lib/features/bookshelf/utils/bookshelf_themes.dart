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
  static const violetSanctuary = BookshelfThemeOption(
    id: 'violet_sanctuary',
    name: 'Violet Sanctuary',
    description: 'Porcelain, violet and deep plum clay',
    primaryColor: Color(0xFF6B45B3),
    accentColor: Color(0xFFC7B2F0),
    cardColor: Color(0xFFF9F6FE),
    textColor: Color(0xFF2E1A48),
    shelfWoodColor: Color(0xFF432C82),
  );

  static const lavenderLilac = BookshelfThemeOption(
    id: 'lavender_lilac',
    name: 'Lavender & Lilac',
    description: 'Porcelain, lavender and soft lilac clay',
    primaryColor: Color(0xFFEDE5F8),
    accentColor: Color(0xFF6B45B3),
    cardColor: Color(0xFFF9F6FE),
    textColor: Color(0xFF2E1A48),
    shelfWoodColor: Color(0xFF9482E6),
  );

  // Backward-compatible aliases mapped to the unified violet-purple clay system
  static const darkAcademia = violetSanctuary;
  static const warmParchment = lavenderLilac;

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
    violetSanctuary,
    lavenderLilac,
    enchantedForest,
    gothicRomance,
    midnightStars,
    blushRose,
  ];

  static BookshelfThemeOption findById(String? id) {
    if (id == null) return violetSanctuary;
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => violetSanctuary,
    );
  }

  static Color parseHex(String? hexString, {Color fallback = const Color(0xFF6B45B3)}) {
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

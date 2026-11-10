import 'package:flutter/material.dart';

class ClaySpinePalette {
  final Color base;
  final Color highlight;
  final Color shadow;
  final Color textColor;

  const ClaySpinePalette({
    required this.base,
    required this.highlight,
    required this.shadow,
    this.textColor = Colors.white,
  });
}

abstract final class BookshelfTheme {
  // Page background
  static const Color backgroundColor = Color(0xFFEDE5F8);
  static const Color backgroundEndColor = Color(0xFFE4DCF6);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFECE5F8), Color(0xFFE4DCF6)],
  );

  // Outer frame border
  static const Color frameBorder = Color(0xFF907ECF);

  // Header & Search
  static const Color searchPill = Color(0xFFDFD4F5);
  static const Color searchHint = Color(0xFF8F7FA9);
  static const Color purpleAccent = Color(0xFF7550B6);
  static const Color filterButtonBg = Color(0xFFDFD4F5);

  // Wooden Shelf Plank
  static const Color shelfHighlight = Color(0xFFDCB197);
  static const Color shelfBase = Color(0xFFCF9E81);
  static const Color shelfShadow = Color(0xFFB0795D);
  static const Color shelfDropShadow = Color(0x38553F64);

  // Terracotta plant pots
  static const Color potBase = Color(0xFFE88161);
  static const Color potHighlight = Color(0xFFF59577);
  static const Color potShadow = Color(0xFFC76343);
  static const Color plantGreen = Color(0xFF78BA99);
  static const Color plantGreenLight = Color(0xFF93D1B1);
  static const Color flowerBlue = Color(0xFF82B0E8);
  static const Color flowerYellow = Color(0xFFF5C55A);

  // Clay Spine Color Palettes matching the reference image
  static const List<ClaySpinePalette> spinePalettes = [
    // 0: Lilac (e.g. Mapping the Interior)
    ClaySpinePalette(
      base: Color(0xFFCEB6EE),
      highlight: Color(0xFFE2CFF7),
      shadow: Color(0xFFB99DE0),
      textColor: Colors.white,
    ),
    // 1: Medium Purple (e.g. Death Valley)
    ClaySpinePalette(
      base: Color(0xFF8D64CD),
      highlight: Color(0xFFA67EE0),
      shadow: Color(0xFF764CB5),
      textColor: Colors.white,
    ),
    // 2: Deep Violet / Indigo (e.g. The World's End)
    ClaySpinePalette(
      base: Color(0xFF382761),
      highlight: Color(0xFF4C3782),
      shadow: Color(0xFF261945),
      textColor: Colors.white,
    ),
    // 3: Warm Peach / Coral (e.g. Court of Wanderem)
    ClaySpinePalette(
      base: Color(0xFFF6A184),
      highlight: Color(0xFFFFBBA2),
      shadow: Color(0xFFDE8466),
      textColor: Colors.white,
    ),
    // 4: Soft Cream / Blush (e.g. Nightbitch / Study for Obedience)
    ClaySpinePalette(
      base: Color(0xFFF8CEBD),
      highlight: Color(0xFFFFDFD2),
      shadow: Color(0xFFE5B5A3),
      textColor: Color(0xFF4C3356),
    ),
    // 5: Amber / Yellow Clay (e.g. The Book Thief / All Fours)
    ClaySpinePalette(
      base: Color(0xFFECC065),
      highlight: Color(0xFFFFD684),
      shadow: Color(0xFFD1A246),
      textColor: Color(0xFF4C3356),
    ),
    // 6: Sage / Mint (e.g. The Pisces)
    ClaySpinePalette(
      base: Color(0xFF86CDBC),
      highlight: Color(0xFFA5E2D3),
      shadow: Color(0xFF6BB5A4),
      textColor: Colors.white,
    ),
    // 7: Periwinkle / Sky Blue (e.g. Before Your Memory Fades)
    ClaySpinePalette(
      base: Color(0xFFB4C5F0),
      highlight: Color(0xFFD0DCFA),
      shadow: Color(0xFF98ACE0),
      textColor: Color(0xFF322350),
    ),
    // 8: Royal Purple (e.g. Brother)
    ClaySpinePalette(
      base: Color(0xFF5A449B),
      highlight: Color(0xFF7056BC),
      shadow: Color(0xFF46337D),
      textColor: Colors.white,
    ),
    // 9: Dusty Rose (e.g. Fahrenheit 451)
    ClaySpinePalette(
      base: Color(0xFFEFA1BE),
      highlight: Color(0xFFFFBED5),
      shadow: Color(0xFFD682A0),
      textColor: Colors.white,
    ),
  ];

  static ClaySpinePalette paletteForId(String id) {
    final hash = id.hashCode.abs();
    return spinePalettes[hash % spinePalettes.length];
  }
}

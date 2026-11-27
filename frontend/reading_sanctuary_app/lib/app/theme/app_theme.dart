import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeChoice { dark, parchment }

class ThemeController extends Notifier<AppThemeChoice> {
  @override
  AppThemeChoice build() => AppThemeChoice.parchment; // Unified Home Page Porcelain aesthetic

  void toggle() =>
      state = state == AppThemeChoice.dark ? AppThemeChoice.parchment : AppThemeChoice.dark;
  void set(AppThemeChoice c) => state = c;
}

final themeProvider = NotifierProvider<ThemeController, AppThemeChoice>(ThemeController.new);

abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.light);
  static ThemeData parchment() => _build(Brightness.light);

  /// Consistent typography matching the Home page (Inter with strong weight and negative letter spacing)
  static TextStyle serif(TextStyle? base, {FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.inter(textStyle: base, fontWeight: weight, letterSpacing: -0.3);

  static ThemeData _build(Brightness b) {
    const bg = Color(0xFFF4F0FB);
    const surface = Color(0xFFF9F6FE);
    const text = Color(0xFF2E1A48);
    const primary = Color(0xFF6B45B3);
    const secondary = Color(0xFF9482E6);

    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      error: Color(0xFFC96F5F),
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    );

    final inter = GoogleFonts.interTextTheme(ThemeData.light().textTheme)
        .apply(bodyColor: text, displayColor: text);
    final textTheme = inter.copyWith(
      displayLarge: GoogleFonts.inter(textStyle: inter.displayLarge, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: text),
      displayMedium: GoogleFonts.inter(textStyle: inter.displayMedium, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: text),
      headlineLarge: GoogleFonts.inter(textStyle: inter.headlineLarge, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: text),
      headlineMedium: GoogleFonts.inter(textStyle: inter.headlineMedium, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: text),
      headlineSmall: GoogleFonts.inter(textStyle: inter.headlineSmall, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: text),
      titleLarge: GoogleFonts.inter(textStyle: inter.titleLarge, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: text),
    );

    const outline = Color(0xFFEADBFA);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      dividerColor: outline,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          side: const BorderSide(color: outline),
          foregroundColor: text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

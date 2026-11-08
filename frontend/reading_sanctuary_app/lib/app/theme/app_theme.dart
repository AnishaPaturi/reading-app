import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

enum AppThemeChoice { dark, parchment }

class ThemeController extends Notifier<AppThemeChoice> {
  @override
  AppThemeChoice build() => AppThemeChoice.dark; // Dark Academia is the default

  void toggle() =>
      state = state == AppThemeChoice.dark ? AppThemeChoice.parchment : AppThemeChoice.dark;
  void set(AppThemeChoice c) => state = c;
}

final themeProvider = NotifierProvider<ThemeController, AppThemeChoice>(ThemeController.new);

abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData parchment() => _build(Brightness.light);

  static TextStyle serif(TextStyle? base, {FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.playfairDisplay(textStyle: base, fontWeight: weight);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? AppColors.espresso : AppColors.ivory;
    final surface = dark ? AppColors.card : AppColors.parchment;
    final text = dark ? AppColors.textLight : AppColors.textDark;

    final scheme = ColorScheme(
      brightness: b,
      primary: dark ? AppColors.gold : AppColors.brown,
      onPrimary: dark ? AppColors.espresso : AppColors.ivory,
      secondary: AppColors.bronze,
      onSecondary: AppColors.ivory,
      error: const Color(0xFFC96F5F),
      onError: AppColors.ivory,
      surface: surface,
      onSurface: text,
    );

    final inter = GoogleFonts.interTextTheme(ThemeData(brightness: b).textTheme)
        .apply(bodyColor: text, displayColor: text);
    final textTheme = inter.copyWith(
      displayLarge: serif(inter.displayLarge),
      displayMedium: serif(inter.displayMedium),
      headlineLarge: serif(inter.headlineLarge),
      headlineMedium: serif(inter.headlineMedium),
      headlineSmall: serif(inter.headlineSmall),
      titleLarge: serif(inter.titleLarge),
    );

    final outline = AppColors.gold.withAlpha(90);
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      dividerColor: outline,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.walnut : AppColors.parchment,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: serif(textTheme.titleLarge?.copyWith(fontSize: 24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: scheme.primary, width: 1.5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 44),
          side: BorderSide(color: outline),
          foregroundColor: text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

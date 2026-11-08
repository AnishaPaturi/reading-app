import 'package:flutter/material.dart';

enum ReaderThemeMode {
  light,
  sepia,
  dark;

  Color get backgroundColor {
    switch (this) {
      case ReaderThemeMode.light:
        return const Color(0xFFFAFAFA);
      case ReaderThemeMode.sepia:
        return const Color(0xFFFBF0D9);
      case ReaderThemeMode.dark:
        return const Color(0xFF1E1E1E);
    }
  }

  Color get textColor {
    switch (this) {
      case ReaderThemeMode.light:
        return const Color(0xFF212121);
      case ReaderThemeMode.sepia:
        return const Color(0xFF5F4B32);
      case ReaderThemeMode.dark:
        return const Color(0xFFE0E0E0);
    }
  }
}

enum ReaderMargin {
  narrow(16.0),
  medium(28.0),
  wide(48.0);

  final double horizontalPadding;
  const ReaderMargin(this.horizontalPadding);
}

class ReaderSettings {
  final ReaderThemeMode themeMode;
  final double fontSize;
  final double lineSpacing;
  final ReaderMargin margin;
  final TextAlign textAlign;
  final Axis pageLayout;

  const ReaderSettings({
    this.themeMode = ReaderThemeMode.light,
    this.fontSize = 16.0,
    this.lineSpacing = 1.5,
    this.margin = ReaderMargin.medium,
    this.textAlign = TextAlign.left,
    this.pageLayout = Axis.vertical,
  });

  ReaderSettings copyWith({
    ReaderThemeMode? themeMode,
    double? fontSize,
    double? lineSpacing,
    ReaderMargin? margin,
    TextAlign? textAlign,
    Axis? pageLayout,
  }) {
    return ReaderSettings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      margin: margin ?? this.margin,
      textAlign: textAlign ?? this.textAlign,
      pageLayout: pageLayout ?? this.pageLayout,
    );
  }
}

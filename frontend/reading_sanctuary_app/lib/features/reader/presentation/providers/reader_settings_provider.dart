import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reader_settings.dart';

final readerSettingsProvider =
    StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
  return ReaderSettingsNotifier();
});

class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  ReaderSettingsNotifier() : super(const ReaderSettings());

  void updateTheme(ReaderThemeMode themeMode) {
    state = state.copyWith(themeMode: themeMode);
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size.clamp(12.0, 32.0));
  }

  void updateLineSpacing(double spacing) {
    state = state.copyWith(lineSpacing: spacing.clamp(1.0, 2.5));
  }

  void updateMargin(ReaderMargin margin) {
    state = state.copyWith(margin: margin);
  }

  void updateTextAlign(TextAlign align) {
    state = state.copyWith(textAlign: align);
  }

  void updatePageLayout(Axis layout) {
    state = state.copyWith(pageLayout: layout);
  }
}

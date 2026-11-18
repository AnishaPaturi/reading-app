import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/network_providers.dart';

class BookSizeSettings {
  final Map<String, double> heightFactors; // bookId -> factor (e.g. 1.0)
  final Map<String, String> presets; // bookId -> 'S', 'M', 'L'
  final bool isResizeModeActive;
  final String? selectedBookId;
  final String viewMode; // 'covers' or 'spines'

  const BookSizeSettings({
    this.heightFactors = const {},
    this.presets = const {},
    this.isResizeModeActive = false,
    this.selectedBookId,
    this.viewMode = 'covers',
  });

  double factorFor(String bookId) => heightFactors[bookId] ?? 1.0;
  String presetFor(String bookId) => presets[bookId] ?? 'M';

  BookSizeSettings copyWith({
    Map<String, double>? heightFactors,
    Map<String, String>? presets,
    bool? isResizeModeActive,
    String? selectedBookId,
    bool clearSelectedBookId = false,
    String? viewMode,
  }) {
    return BookSizeSettings(
      heightFactors: heightFactors ?? this.heightFactors,
      presets: presets ?? this.presets,
      isResizeModeActive: isResizeModeActive ?? this.isResizeModeActive,
      selectedBookId: clearSelectedBookId ? null : (selectedBookId ?? this.selectedBookId),
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

class BookSizeNotifier extends StateNotifier<BookSizeSettings> {
  final Ref _ref;
  static const _storageKey = 'sanctuary_book_sizes';
  static const _viewModeKey = 'sanctuary_bookshelf_view_mode';

  BookSizeNotifier(this._ref) : super(const BookSizeSettings()) {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vm = prefs.getString(_viewModeKey) ?? 'covers';

      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        final factors = <String, double>{};
        final presets = <String, String>{};

        decoded.forEach((k, v) {
          if (v is Map) {
            factors[k] = (v['factor'] as num?)?.toDouble() ?? 1.0;
            presets[k] = v['preset']?.toString() ?? 'M';
          } else if (v is num) {
            factors[k] = v.toDouble();
            presets[k] = 'M';
          }
        });

        state = state.copyWith(
          heightFactors: factors,
          presets: presets,
          viewMode: vm,
        );
      } else {
        state = state.copyWith(viewMode: vm);
      }
    } catch (_) {}
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_viewModeKey, state.viewMode);

      final map = <String, dynamic>{};
      state.heightFactors.forEach((k, v) {
        map[k] = {
          'factor': v,
          'preset': state.presets[k] ?? 'M',
        };
      });
      await prefs.setString(_storageKey, jsonEncode(map));
    } catch (_) {}
  }

  void toggleViewMode() {
    final next = state.viewMode == 'covers' ? 'spines' : 'covers';
    state = state.copyWith(viewMode: next);
    _saveToCache();
  }

  void setViewMode(String mode) {
    state = state.copyWith(viewMode: mode);
    _saveToCache();
  }

  void toggleResizeMode() {
    state = state.copyWith(
      isResizeModeActive: !state.isResizeModeActive,
      clearSelectedBookId: state.isResizeModeActive,
    );
  }

  void selectBook(String bookId) {
    if (!state.isResizeModeActive) return;
    state = state.copyWith(
      selectedBookId: state.selectedBookId == bookId ? null : bookId,
      clearSelectedBookId: state.selectedBookId == bookId,
    );
  }

  void setHeightFactor(String bookId, double factor) {
    final factors = Map<String, double>.from(state.heightFactors);
    factors[bookId] = factor.clamp(0.7, 1.4);
    state = state.copyWith(heightFactors: factors);
  }

  void setPreset(String bookId, String preset) {
    double factor;
    switch (preset.toUpperCase()) {
      case 'S':
        factor = 0.82;
        break;
      case 'L':
        factor = 1.25;
        break;
      case 'M':
      default:
        factor = 1.0;
        break;
    }

    final factors = Map<String, double>.from(state.heightFactors);
    final presets = Map<String, String>.from(state.presets);
    factors[bookId] = factor;
    presets[bookId] = preset.toUpperCase();

    state = state.copyWith(heightFactors: factors, presets: presets);
  }

  void autoResetSelected() {
    if (state.selectedBookId == null) return;
    final bookId = state.selectedBookId!;
    final factors = Map<String, double>.from(state.heightFactors)..remove(bookId);
    final presets = Map<String, String>.from(state.presets)..remove(bookId);
    state = state.copyWith(heightFactors: factors, presets: presets);
  }

  void autoResetAll() {
    state = state.copyWith(heightFactors: const {}, presets: const {});
    _saveToCache();
  }

  Future<void> done() async {
    state = state.copyWith(isResizeModeActive: false, clearSelectedBookId: true);
    await _saveToCache();

    // Sync to backend if online
    try {
      final client = _ref.read(apiClientProvider);
      for (final entry in state.heightFactors.entries) {
        await client.post('/shelves/customizations', body: {
          'bookId': entry.key,
          'heightFactor': entry.value,
          'presetSize': state.presets[entry.key] ?? 'M',
        });
      }
    } catch (_) {}
  }
}

final bookSizeProvider =
    StateNotifierProvider<BookSizeNotifier, BookSizeSettings>((ref) {
  return BookSizeNotifier(ref);
});

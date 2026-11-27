import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/classified_book.dart';

class BookSelectionNotifier extends StateNotifier<Set<String>> {
  BookSelectionNotifier() : super(const {});

  /// Checks if a file is currently selected.
  bool isSelected(String pathOrUri) => state.contains(pathOrUri);

  /// Toggles selection of an individual book.
  /// Non-importable books (already imported, duplicate in scan, invalid, unverified) are strictly ignored.
  bool toggle(ClassifiedBook book) {
    if (!book.isImportable) return false;

    final key = book.file.pathOrUri;
    final updated = Set<String>.from(state);
    if (updated.contains(key)) {
      updated.remove(key);
      state = Set.unmodifiable(updated);
      return false;
    } else {
      updated.add(key);
      state = Set.unmodifiable(updated);
      return true;
    }
  }

  /// Selects an individual book if eligible.
  bool select(ClassifiedBook book) {
    if (!book.isImportable) return false;

    final key = book.file.pathOrUri;
    if (!state.contains(key)) {
      final updated = Set<String>.from(state)..add(key);
      state = Set.unmodifiable(updated);
    }
    return true;
  }

  /// Deselects an individual book.
  void deselect(String pathOrUri) {
    if (state.contains(pathOrUri)) {
      final updated = Set<String>.from(state)..remove(pathOrUri);
      state = Set.unmodifiable(updated);
    }
  }

  /// Selects ALL eligible books from the discovery list.
  /// Automatically filters out already-imported, duplicate in scan, invalid, and unverified books.
  int selectAllEligible(List<ClassifiedBook> allBooks) {
    final eligibleKeys = allBooks
        .where((b) => b.isImportable)
        .map((b) => b.file.pathOrUri)
        .toSet();

    state = Set.unmodifiable(eligibleKeys);
    return eligibleKeys.length;
  }

  /// Deselects all books.
  void deselectAll() {
    state = const {};
  }

  /// Returns the subset of ClassifiedBooks matching the current selection.
  List<ClassifiedBook> getSelectedBooks(List<ClassifiedBook> allBooks) {
    return allBooks.where((b) => state.contains(b.file.pathOrUri)).toList();
  }

  /// Calculates total size in bytes of all currently selected books.
  int getSelectedTotalBytes(List<ClassifiedBook> allBooks) {
    var total = 0;
    for (final book in allBooks) {
      if (state.contains(book.file.pathOrUri)) {
        total += book.file.sizeBytes;
      }
    }
    return total;
  }

  /// Formatted total size string for UI display.
  String getSelectedFormattedSize(List<ClassifiedBook> allBooks) {
    return formatBytes(getSelectedTotalBytes(allBooks));
  }

  /// Formats byte count to human readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

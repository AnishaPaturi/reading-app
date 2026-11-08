import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/reader/data/models/reader_annotations.dart';
import 'package:reading_sanctuary_app/features/reader/data/models/reader_position.dart';
import 'package:reading_sanctuary_app/features/reader/data/models/reader_settings.dart';
import 'package:reading_sanctuary_app/features/reader/data/repositories/reader_repository.dart';
import 'package:reading_sanctuary_app/features/reader/domain/enums/reader_file_type.dart';
import 'package:reading_sanctuary_app/features/reader/domain/services/reader_position_service.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/providers/reader_settings_provider.dart';

class FakeReaderRepository implements ReaderRepository {
  ReaderPosition? savedPosition;
  final List<ReaderBookmark> bookmarks = [];
  final List<ReaderHighlight> highlights = [];
  final List<ReaderBookNote> notes = [];

  @override
  Future<ReaderPosition?> getPosition({required String bookId, required String fileId}) async {
    return savedPosition;
  }

  @override
  Future<ReaderPosition> savePosition({
    required String bookId,
    required String fileId,
    required ReaderPosition position,
  }) async {
    savedPosition = position;
    return position;
  }

  @override
  Future<void> resetPosition({required String bookId, required String fileId}) async {
    savedPosition = null;
  }

  @override
  Future<List<ReaderBookmark>> getBookmarks({required String bookId}) async => bookmarks;

  @override
  Future<ReaderBookmark> createBookmark({
    required String bookId,
    required String bookFileId,
    required String locationType,
    required String locationValue,
    int? pageNumber,
    String? label,
    String? note,
  }) async {
    final b = ReaderBookmark(
      id: 'bm-1',
      bookId: bookId,
      bookFileId: bookFileId,
      locationType: locationType,
      locationValue: locationValue,
      pageNumber: pageNumber,
      label: label,
      note: note,
      createdAt: DateTime.now(),
    );
    bookmarks.add(b);
    return b;
  }

  @override
  Future<void> deleteBookmark({required String bookId, required String bookmarkId}) async {
    bookmarks.removeWhere((b) => b.id == bookmarkId);
  }

  @override
  Future<List<ReaderHighlight>> getHighlights({required String bookId}) async => highlights;

  @override
  Future<ReaderHighlight> createHighlight({
    required String bookId,
    required String bookFileId,
    required String selectedText,
    required String locationType,
    required String startLocation,
    required String endLocation,
    int? pageNumber,
    ReaderHighlightColor color = ReaderHighlightColor.yellow,
    String? annotationNote,
  }) async {
    final h = ReaderHighlight(
      id: 'hl-1',
      bookId: bookId,
      bookFileId: bookFileId,
      selectedText: selectedText,
      locationType: locationType,
      startLocation: startLocation,
      endLocation: endLocation,
      pageNumber: pageNumber,
      color: color,
      annotationNote: annotationNote,
      createdAt: DateTime.now(),
    );
    highlights.add(h);
    return h;
  }

  @override
  Future<void> deleteHighlight({required String bookId, required String highlightId}) async {
    highlights.removeWhere((h) => h.id == highlightId);
  }

  @override
  Future<List<ReaderBookNote>> getNotes({required String bookId}) async => notes;

  @override
  Future<ReaderBookNote> createNote({
    required String bookId,
    required String title,
    required String content,
  }) async {
    final n = ReaderBookNote(
      id: 'note-1',
      bookId: bookId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notes.add(n);
    return n;
  }

  @override
  Future<void> deleteNote({required String bookId, required String noteId}) async {
    notes.removeWhere((n) => n.id == noteId);
  }
}

void main() {
  group('ReaderFileType', () {
    test('resolves known formats', () {
      expect(ReaderFileType.fromFormat('pdf'), ReaderFileType.pdf);
      expect(ReaderFileType.fromFormat('PDF'), ReaderFileType.pdf);
      expect(ReaderFileType.fromFormat('epub'), ReaderFileType.epub);
      expect(ReaderFileType.fromFormat('EPUB'), ReaderFileType.epub);
      expect(ReaderFileType.fromFormat('docx'), ReaderFileType.docx);
      expect(ReaderFileType.fromFormat('DOCX'), ReaderFileType.docx);
    });

    test('throws UnsupportedError for unknown formats', () {
      expect(() => ReaderFileType.fromFormat('mobi'), throwsUnsupportedError);
    });
  });

  group('ReaderPosition', () {
    test('serializes and deserializes correctly', () {
      const pos = ReaderPosition(
        locationType: 'PDF_PAGE',
        locationValue: 'page=15',
        pageNumber: 15,
        totalPages: 200,
        progressPercentage: 7.5,
      );

      final json = pos.toJson();
      final fromJson = ReaderPosition.fromJson(json);

      expect(fromJson.locationType, 'PDF_PAGE');
      expect(fromJson.locationValue, 'page=15');
      expect(fromJson.pageNumber, 15);
      expect(fromJson.totalPages, 200);
      expect(fromJson.progressPercentage, 7.5);
    });
  });

  group('ReaderSettingsNotifier', () {
    test('updates theme, fontSize, and spacing correctly', () {
      final notifier = ReaderSettingsNotifier();
      expect(notifier.state.themeMode, ReaderThemeMode.light);

      notifier.updateTheme(ReaderThemeMode.dark);
      expect(notifier.state.themeMode, ReaderThemeMode.dark);

      notifier.updateFontSize(24);
      expect(notifier.state.fontSize, 24);

      // Clamp checks
      notifier.updateFontSize(100);
      expect(notifier.state.fontSize, 32);

      notifier.updateFontSize(5);
      expect(notifier.state.fontSize, 12);

      notifier.updateLineSpacing(2.0);
      expect(notifier.state.lineSpacing, 2.0);

      notifier.updateMargin(ReaderMargin.wide);
      expect(notifier.state.margin, ReaderMargin.wide);

      notifier.updatePageLayout(Axis.horizontal);
      expect(notifier.state.pageLayout, Axis.horizontal);
    });
  });

  group('ReaderPositionService', () {
    test('debounces save calls', () async {
      final repo = FakeReaderRepository();
      final service = ReaderPositionService(
        repository: repo,
        debounceDuration: const Duration(milliseconds: 100),
      );

      const pos1 = ReaderPosition(
        locationType: 'PDF_PAGE',
        locationValue: 'page=1',
        pageNumber: 1,
        progressPercentage: 1.0,
      );
      const pos2 = ReaderPosition(
        locationType: 'PDF_PAGE',
        locationValue: 'page=2',
        pageNumber: 2,
        progressPercentage: 2.0,
      );

      service.onPositionChanged(bookId: 'b1', fileId: 'f1', position: pos1);
      service.onPositionChanged(bookId: 'b1', fileId: 'f1', position: pos2);

      // Before timer expires
      expect(repo.savedPosition, isNull);

      // Wait for debounce timer
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(repo.savedPosition?.pageNumber, 2);
    });
  });
}

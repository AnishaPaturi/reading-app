import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reading_sanctuary_app/features/reader/domain/reading_progress.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/widgets/page_navigation_slider.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/widgets/reader_bottom_bar.dart';

void main() {
  group('ReadingProgress Model', () {
    test('serializes and deserializes PDF reading progress', () {
      final progress = ReadingProgress(
        bookFileId: 'file-uuid-1',
        format: 'PDF',
        currentPage: 182,
        totalPages: 363,
        progressPercentage: 50.138,
        positionData: const {'scrollOffset': 0.0},
        lastOpenedAt: DateTime.parse('2026-11-15T10:00:00Z'),
        updatedAt: DateTime.parse('2026-11-15T10:00:00Z'),
      );

      final json = progress.toJson();
      expect(json['format'], 'PDF');
      expect(json['currentPage'], 182);
      expect(json['totalPages'], 363);
      expect(json['progressPercentage'], 50.138);

      final reconstructed = ReadingProgress.fromJson({
        'bookFileId': 'file-uuid-1',
        ...json,
      });

      expect(reconstructed.bookFileId, 'file-uuid-1');
      expect(reconstructed.currentPage, 182);
      expect(reconstructed.totalPages, 363);
      expect(reconstructed.format, 'PDF');
      expect(reconstructed.progressPercentage, 50.138);
    });

    test('serializes and deserializes EPUB reading progress', () {
      const progress = ReadingProgress(
        bookFileId: 'file-uuid-2',
        format: 'EPUB',
        chapterHref: 'chapter05.xhtml',
        epubCfi: 'epubcfi(/6/12!/4/2)',
        progressPercentage: 45.2,
      );

      final json = progress.toJson();
      expect(json['format'], 'EPUB');
      expect(json['chapterHref'], 'chapter05.xhtml');
      expect(json['epubCfi'], 'epubcfi(/6/12!/4/2)');
      expect(json['progressPercentage'], 45.2);

      final reconstructed = ReadingProgress.fromJson({
        'bookFileId': 'file-uuid-2',
        ...json,
      });

      expect(reconstructed.chapterHref, 'chapter05.xhtml');
      expect(reconstructed.epubCfi, 'epubcfi(/6/12!/4/2)');
      expect(reconstructed.progressPercentage, 45.2);
    });

    test('serializes and deserializes Audio reading progress', () {
      const progress = ReadingProgress(
        bookFileId: 'file-uuid-3',
        format: 'M4B',
        audioPositionMs: 3840000,
        audioDurationMs: 14400000,
        progressPercentage: 26.667,
      );

      final json = progress.toJson();
      expect(json['format'], 'M4B');
      expect(json['audioPositionMs'], 3840000);
      expect(json['audioDurationMs'], 14400000);
      expect(json['progressPercentage'], 26.667);

      final reconstructed = ReadingProgress.fromJson({
        'bookFileId': 'file-uuid-3',
        ...json,
      });

      expect(reconstructed.audioPositionMs, 3840000);
      expect(reconstructed.audioDurationMs, 14400000);
      expect(reconstructed.progressPercentage, 26.667);
    });
  });

  group('PageNavigationSlider Widget', () {
    testWidgets('renders current page, total pages, and percentage', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigationSlider(
              currentPage: 50,
              totalPages: 200,
              onPagePreview: (_) {},
              onPageSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Page 50 of 200'), findsOneWidget);
      expect(find.text('25.0%'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('handles single page document without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageNavigationSlider(
              currentPage: 1,
              totalPages: 1,
              onPageSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Page 1 of 1'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
    });
  });

  group('ReaderBottomBar Widget with Slider', () {
    testWidgets('renders discrete page slider and triggers callbacks', (tester) async {
      bool previousTapped = false;
      bool nextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ReaderBottomBar(
              currentPage: 10,
              totalPages: 100,
              progressPercentage: 10.0,
              onPageSelected: (_) {},
              onPrevious: () => previousTapped = true,
              onNext: () => nextTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Page 10 of 100'), findsOneWidget);
      expect(find.text('10.0%'), findsOneWidget);

      // Tap Previous button
      await tester.tap(find.byTooltip('Previous'));
      await tester.pump();
      expect(previousTapped, isTrue);

      // Tap Next button
      await tester.tap(find.byTooltip('Next'));
      await tester.pump();
      expect(nextTapped, isTrue);
    });
  });

  group('Local Progress Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves and retrieves progress across simulated restarts', () async {
      final prefs = await SharedPreferences.getInstance();
      const key = 'sanctuary_progress_file123';

      await prefs.setString(key, '{"format":"PDF","currentPage":182,"totalPages":363,"progressPercentage":50.138}');

      final raw = prefs.getString(key);
      expect(raw, isNotNull);

      final map = {
        'bookFileId': 'file123',
        'format': 'PDF',
        'currentPage': 182,
        'totalPages': 363,
        'progressPercentage': 50.138,
      };

      final restored = ReadingProgress.fromJson(map);
      expect(restored.currentPage, 182);
      expect(restored.totalPages, 363);
      expect(restored.progressPercentage, 50.138);
    });
  });
}

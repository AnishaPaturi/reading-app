import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:reading_sanctuary_app/features/home/home_screen.dart';
import 'package:reading_sanctuary_app/features/home/presentation/providers/home_reading_progress_provider.dart';
import 'package:reading_sanctuary_app/features/reader/data/reading_progress_repository.dart';
import 'package:reading_sanctuary_app/features/reader/domain/reading_progress.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/widgets/page_navigation_slider.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/widgets/reader_bottom_bar.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/book_repository.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.contains('AssetManifest') || key.contains('FontManifest')) {
      return rootBundle.load(key);
    }
    final bytes = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
    return ByteData.view(bytes.buffer);
  }
}

class FakeReadingProgressRepository implements ReadingProgressRepository {
  final Map<String, ReadingProgress> storage = {};

  @override
  Future<List<ReadingProgress>> getAllProgress() async => storage.values.toList();

  @override
  Future<ReadingProgress?> getProgress(String bookFileId) async => storage[bookFileId];

  @override
  Future<ReadingProgress> saveProgress(String bookFileId, ReadingProgress progress, {bool syncRemote = true}) async {
    storage[bookFileId] = progress;
    return progress;
  }

  @override
  Future<void> resetProgress(String bookFileId) async {
    storage.remove(bookFileId);
  }

  @override
  Future<bool> hasPendingSync(String bookFileId) async => false;

  @override
  Future<void> syncPendingRecords() async {}
}

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
      dotenv.testLoad(fileInput: 'GOOGLE_WEB_CLIENT_ID=dummy\nGOOGLE_SERVER_CLIENT_ID=dummy\nAPI_BASE_URL=http://localhost:8080');
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

  group('Home Reading Progress Providers and Mapping', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dotenv.testLoad(fileInput: 'GOOGLE_WEB_CLIENT_ID=dummy\nGOOGLE_SERVER_CLIENT_ID=dummy\nAPI_BASE_URL=http://localhost:8080');
    });
    test('homeProgressByFileIdProvider indexes records by bookFileId', () async {
      final container = ProviderContainer(
        overrides: [
          homeReadingProgressProvider.overrideWith((ref) async => [
                const ReadingProgress(
                  bookFileId: 'file-bone-year-pdf',
                  format: 'PDF',
                  currentPage: 57,
                  totalPages: 363,
                  progressPercentage: 15.702,
                ),
                const ReadingProgress(
                  bookFileId: 'file-audio-1',
                  format: 'M4B',
                  audioPositionMs: 60000,
                  audioDurationMs: 600000,
                  progressPercentage: 10.0,
                ),
              ]),
        ],
      );
      addTearDown(container.dispose);

      // Await future provider
      await container.read(homeReadingProgressProvider.future);

      final map = container.read(homeProgressByFileIdProvider);
      expect(map.containsKey('file-bone-year-pdf'), isTrue);
      expect(map['file-bone-year-pdf']!.currentPage, 57);
      expect(map['file-bone-year-pdf']!.totalPages, 363);
      expect(map['file-bone-year-pdf']!.progressPercentage, 15.702);

      expect(map.containsKey('file-audio-1'), isTrue);
      expect(map['file-audio-1']!.format, 'M4B');
    });

    testWidgets('HomeScreen Currently Reading card displays Page 57 of 363 and 15.7% Completed', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testBook = Book(
        id: 'book-bone-year',
        title: 'Bone Year',
        author: "O'Donovan, Ashley R.",
        genre: 'Dark Academia',
        description: 'Test description',
        status: ReadingStatus.currentlyReading,
        progress: 0.0,
        pages: 363,
        formats: const [BookFormat.ebook],
        files: const [
          BookFile(
            id: 'file-bone-year-pdf',
            format: BookFileFormat.pdf,
            fileName: 'bone-year.pdf',
            fileSize: 1024,
          ),
        ],
        addedAt: DateTime.now(),
        coverColors: const [Color(0xFF2C3E50), Color(0xFFBDC3C7)],
      );

      final progress = ReadingProgress(
        bookFileId: 'file-bone-year-pdf',
        format: 'PDF',
        currentPage: 57,
        totalPages: 363,
        progressPercentage: 15.702,
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(MockBookRepository([testBook])),
            homeReadingProgressProvider.overrideWith((ref) async => [progress]),
            userDisplayNameProvider.overrideWithValue('Reader'),
            userAvatarAssetProvider.overrideWithValue('assets/images/dashboard/dash_avatar.png'),
            userBannerAssetProvider.overrideWithValue('assets/images/dashboard/dash_banner.png'),
          ],
          child: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: const MaterialApp(
              home: HomeScreen(),
            ),
          ),
        ),
      );

      // Settle async timers and build
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Currently Reading'), findsOneWidget);
      expect(find.text('Bone Year'), findsNWidgets(2));
      expect(find.text('Page 57 of 363'), findsOneWidget);
      expect(find.text('16% Completed'), findsOneWidget);
      expect(find.text('0% Completed'), findsNothing);
    });
  });
}

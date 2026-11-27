import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/batch_import_state.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/classified_book.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/duplicate_status.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/presentation/screens/discover_books_screen.dart';
import 'package:reading_sanctuary_app/features/book_discovery/presentation/widgets/batch_import_progress_panel.dart';
import 'package:reading_sanctuary_app/features/book_discovery/presentation/widgets/discovered_book_card.dart';
import 'package:reading_sanctuary_app/features/book_discovery/presentation/widgets/discovery_summary_card.dart';
import 'package:reading_sanctuary_app/features/book_discovery/providers/book_discovery_providers.dart';
import 'package:reading_sanctuary_app/features/book_discovery/providers/book_selection_provider.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/book_scanner_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/discovery_engine.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/duplicate_detection_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/file_checksum_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/folder_manager_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/platform_book_scanner.dart';
import 'package:reading_sanctuary_app/features/library/data/models/book_metadata.dart';
import 'package:reading_sanctuary_app/features/library/data/models/reconcile_response.dart';
import 'package:reading_sanctuary_app/features/library/data/models/selected_book_file.dart';
import 'package:reading_sanctuary_app/features/library/data/services/book_upload_service.dart';
import 'package:reading_sanctuary_app/features/shell/destinations.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';

class FakePlatformBookScanner extends PlatformBookScanner {
  final List<ScanFolder> initialFolders;
  ScanFolder? nextPickedFolder;

  FakePlatformBookScanner({this.initialFolders = const []});

  String get platformName => 'FakePlatform';

  @override
  String get platformCapabilitiesDescription =>
      'Testing platform scanner with mock SAF and filesystem permissions.';

  @override
  Future<ScanFolder?> pickFolder() async => nextPickedFolder;

  @override
  Future<List<DiscoveredFile>> scanFolder(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async => [];

  @override
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async* {}

  @override
  Future<bool> verifyPermission(ScanFolder folder) async => folder.isAccessible;

  @override
  Future<bool> releasePermission(ScanFolder folder) async => true;

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async =>
      Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]);
}

class FakeUploadServiceForUI extends BookUploadService {
  FakeUploadServiceForUI() : super(apiClient: ApiClient(tokenProvider: () => 'token'));

  @override
  Future<BookMetadata> uploadBook(SelectedBookFile file, {void Function(int sent, int total)? onProgress}) async {
    return BookMetadata(
      uploadId: 'mock-upload-${file.name}',
      title: file.name,
      author: 'Mock Author',
      format: file.extension.toUpperCase(),
    );
  }

  @override
  Future<Book> confirmBook({
    required String uploadId,
    required BookMetadata metadata,
    required String readingStatus,
    String? existingBookId,
  }) async {
    return Book(
      id: 'mock-book-$uploadId',
      title: metadata.title ?? 'Mock Title',
      author: metadata.author ?? 'Mock Author',
      genre: 'Fiction',
      description: '',
      status: ReadingStatus.toRead,
      progress: 0.0,
      pages: 150,
      formats: const [BookFormat.ebook],
      addedAt: DateTime.now(),
      coverColors: const [],
    );
  }

  @override
  Future<ReconcileResponse> reconcileUpload({String? uploadId, required String checksum}) async {
    return const ReconcileResponse(status: ReconcileStatus.notFound);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ClassifiedBook createTestBook({
    required String name,
    required DuplicateClassification classification,
    int size = 1024 * 1024,
    String? existingTitle,
  }) {
    return ClassifiedBook(
      file: DiscoveredFile(
        id: name,
        name: name,
        pathOrUri: '/storage/$name',
        extension: name.split('.').last,
        sizeBytes: size,
        lastModified: DateTime.now(),
        parentFolderIdentifier: '/storage',
      ),
      checksum: 'hash_$name',
      classification: classification,
      existingBookTitle: existingTitle,
      isValidFormat: classification != DuplicateClassification.invalid,
    );
  }

  group('Phase 5 Navigation & Route Integrity', () {
    test('Route metadata: /library/discover has correct title and is marked as detail route', () {
      expect(titleFor('/library/discover'), 'Discover Books');
      expect(isDetailRoute('/library/discover'), isTrue);
    });

    test('Route separation: /discover remains the online curated DiscoverScreen', () {
      expect(titleFor('/discover'), 'Reading Sanctuary');
      // Verify online route path is distinct from local library discover
      expect('/discover', isNot(equals('/library/discover')));
    });
  });

  group('DiscoverBooksScreen UI & Components', () {
    testWidgets('Empty State: renders instructions to add folder when no folders are registered', (tester) async {
      final fakeScanner = FakePlatformBookScanner();
      final folderManager = FolderManagerService(scanner: fakeScanner);
      final scannerService = BookScannerService(scanner: fakeScanner, folderManager: folderManager);
      final duplicateService = DuplicateDetectionService(
        apiClient: ApiClient(tokenProvider: () => 'token'),
        checksumService: FileChecksumService(),
        platformScanner: fakeScanner,
      );
      final discoveryEngine = DiscoveryEngine(
        scannerService: scannerService,
        duplicateDetectionService: duplicateService,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            folderManagerServiceProvider.overrideWith((ref) => folderManager),
            bookScannerServiceProvider.overrideWith((ref) => scannerService),
            discoveryEngineProvider.overrideWith((ref) => discoveryEngine),
          ],
          child: const MaterialApp(
            home: DiscoverBooksScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Discover Books'), findsOneWidget);
      expect(find.text('No Folders Registered'), findsOneWidget);
      expect(find.text('Add Scan Folder'), findsOneWidget);
      expect(find.textContaining('Testing platform scanner with mock SAF'), findsOneWidget);
    });

    testWidgets('Folder Management: displays registered folders with active status and remove action', (tester) async {
      const folder1 = ScanFolder(
        id: 'f1',
        name: 'Downloads',
        pathOrUri: '/storage/downloads',
        status: FolderAccessStatus.active,
      );
      final fakeScanner = FakePlatformBookScanner(initialFolders: [folder1]);
      final folderManager = FolderManagerService(scanner: fakeScanner);
      await folderManager.registerFolder(folder1);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            folderManagerServiceProvider.overrideWith((ref) => folderManager),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DiscoverBooksScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Scan Folders (1)'), findsOneWidget);
      expect(find.text('Downloads'), findsOneWidget);
      expect(find.text('Active & Accessible'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('Discovery Summary: renders accurate category counts for all classification types', (tester) async {
      var retryClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoverySummaryCard(
              totalCount: 5,
              newCount: 2,
              alreadyImportedCount: 1,
              duplicateInScanCount: 1,
              unverifiedCount: 1,
              invalidOrErrorCount: 0,
              onRetryVerification: () => retryClicked = true,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Discovery Summary'), findsOneWidget);
      expect(find.text('5 total discovered'), findsOneWidget);
      expect(find.textContaining('Ready to Import'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.textContaining('In Library'), findsOneWidget);
      expect(find.textContaining('Duplicates'), findsOneWidget);
      expect(find.textContaining('Unverified'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retryClicked, isTrue);
    });

    testWidgets('Book Card Distinction: importable books have active checkbox; non-importable show block icon', (tester) async {
      final importableBook = createTestBook(name: 'novel.epub', classification: DuplicateClassification.newBook);
      final alreadyImportedBook = createTestBook(
        name: 'existing.pdf',
        classification: DuplicateClassification.alreadyImported,
        existingTitle: 'Existing Masterpiece',
      );

      var toggleCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DiscoveredBookCard(
                  book: importableBook,
                  isSelected: true,
                  onSelectChanged: (_) => toggleCalled = true,
                ),
                DiscoveredBookCard(
                  book: alreadyImportedBook,
                  isSelected: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('novel.epub'), findsOneWidget);
      expect(find.text('Ready to Import'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      expect(find.text('existing.pdf'), findsOneWidget);
      expect(find.text('Already in Library: "Existing Masterpiece"'), findsOneWidget);
      expect(find.byIcon(Icons.block_rounded), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      expect(toggleCalled, isTrue);
    });

    testWidgets('Selection toolbar: Select All selects only eligible books and reflects formatted size', (tester) async {
      final b1 = createTestBook(name: 'book1.epub', classification: DuplicateClassification.newBook, size: 2 * 1024 * 1024);
      final b2 = createTestBook(name: 'book2.epub', classification: DuplicateClassification.newBook, size: 3 * 1024 * 1024);
      final bImported = createTestBook(name: 'imported.epub', classification: DuplicateClassification.alreadyImported);

      final container = ProviderContainer();
      final notifier = container.read(bookSelectionProvider.notifier);

      final selectedCount = notifier.selectAllEligible([b1, b2, bImported]);
      expect(selectedCount, 2);
      expect(container.read(bookSelectionProvider), equals({'/storage/book1.epub', '/storage/book2.epub'}));

      final totalBytes = notifier.getSelectedTotalBytes([b1, b2, bImported]);
      expect(totalBytes, 5 * 1024 * 1024);
      expect(BookSelectionNotifier.formatBytes(totalBytes), '5.0 MB');

      notifier.deselectAll();
      expect(container.read(bookSelectionProvider), isEmpty);
    });

    testWidgets('BatchImportProgressPanel: renders active progress, cancel action, and retry on failure', (tester) async {
      final b1 = createTestBook(name: 'importing_book.epub', classification: DuplicateClassification.newBook);
      var cancelCalled = false;
      var retryCalled = false;

      // 1. In-progress state
      const inProgressState = BatchImportState(
        status: BatchImportStatus.importing,
        totalCount: 3,
        completedCount: 1,
        failedCount: 0,
        overallProgress: 0.33,
        currentProcessingTitle: 'importing_book.epub',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchImportProgressPanel(
              importState: inProgressState,
              onCancel: () => cancelCalled = true,
              onRetryFailed: () => retryCalled = true,
              onDismiss: () {},
              onViewLibrary: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Importing Books...'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Processing: importing_book.epub'), findsOneWidget);
      expect(find.text('Cancel Import'), findsOneWidget);

      await tester.tap(find.text('Cancel Import'));
      expect(cancelCalled, isTrue);

      // 2. Failure state
      final failedItem = BatchImportItem(
        book: b1,
        status: BatchItemStatus.failed,
        errorMessage: 'Network connection dropped',
      );
      final failedState = BatchImportState(
        status: BatchImportStatus.completed,
        totalCount: 2,
        completedCount: 1,
        failedCount: 1,
        overallProgress: 1.0,
        items: {'/storage/importing_book.epub': failedItem},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchImportProgressPanel(
              importState: failedState,
              onCancel: () {},
              onRetryFailed: () => retryCalled = true,
              onDismiss: () {},
              onViewLibrary: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Import Completed with Issues'), findsOneWidget);
      expect(find.textContaining('1 succeeded, 1 failed'), findsOneWidget);
      expect(find.textContaining('Network connection dropped'), findsOneWidget);
      expect(find.text('Retry Failed (1)'), findsOneWidget);

      await tester.tap(find.text('Retry Failed (1)'));
      expect(retryCalled, isTrue);
    });
  });
}

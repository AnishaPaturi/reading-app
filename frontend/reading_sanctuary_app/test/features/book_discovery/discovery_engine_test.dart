import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/book_scanner_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/discovery_engine.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/duplicate_detection_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/file_checksum_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/folder_manager_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/platform_book_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EngineTestPlatformScanner implements PlatformBookScanner {
  final Map<String, List<DiscoveredFile>> folderFiles = {};
  bool shouldThrowOnScan = false;

  @override
  String get platformCapabilitiesDescription => 'Engine Test Scanner';

  @override
  Future<ScanFolder?> pickFolder() async => null;

  @override
  Future<bool> verifyPermission(ScanFolder folder) async => true;

  @override
  Future<bool> releasePermission(ScanFolder folder) async => true;

  @override
  Future<List<DiscoveredFile>> scanFolder(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async {
    if (shouldThrowOnScan) throw Exception('Permission denied accessing storage');
    return folderFiles[folder.id] ?? [];
  }

  @override
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async* {
    for (final file in folderFiles[folder.id] ?? <DiscoveredFile>[]) {
      yield file;
    }
  }

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async => null;
}

class ThrowingScannerService extends BookScannerService {
  ThrowingScannerService({required super.scanner, required super.folderManager});

  @override
  Future<List<DiscoveredFile>> scanAllFolders({Set<String>? supportedExtensions}) async {
    throw Exception('Storage service crashed');
  }
}

class EngineFakeApiClient extends ApiClient {
  dynamic postResponse;
  final List<String> endpointsCalled = [];

  EngineFakeApiClient({this.postResponse}) : super(tokenProvider: () => 'token');

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    endpointsCalled.add(endpoint);
    return postResponse;
  }
}

class EngineFakeChecksumService extends FileChecksumService {
  final Map<String, String?> hashes;

  EngineFakeChecksumService(this.hashes);

  @override
  Future<String?> computeChecksum(DiscoveredFile file) async {
    return hashes[file.pathOrUri];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final pdfHeader = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF
  final epubHeader = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]); // PK..

  late EngineTestPlatformScanner mockScanner;
  late FolderManagerService folderManager;
  late BookScannerService scannerService;
  late EngineFakeApiClient mockApiClient;
  late EngineFakeChecksumService mockChecksumService;
  late DuplicateDetectionService duplicateService;
  late DiscoveryEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockScanner = EngineTestPlatformScanner();
    folderManager = FolderManagerService(scanner: mockScanner);
    await folderManager.initialize();

    scannerService = BookScannerService(
      scanner: mockScanner,
      folderManager: folderManager,
    );

    mockApiClient = EngineFakeApiClient(
      postResponse: {
        'duplicates': [
          {
            'clientRefId': 'b2',
            'checksum': 'hash_gatsby',
            'existingBookId': 'book-uuid-gatsby',
            'existingBookTitle': 'The Great Gatsby',
          }
        ],
        'verifiedChecksums': ['hash_habits', 'hash_gatsby'],
      },
    );

    mockChecksumService = EngineFakeChecksumService({
      '/books/atomic_habits.pdf': 'hash_habits',
      '/books/gatsby.epub': 'hash_gatsby',
      '/books/gatsby_copy.epub': 'hash_gatsby',
      '/books/broken.epub': null, // unhashable
    });

    duplicateService = DuplicateDetectionService(
      checksumService: mockChecksumService,
      apiClient: mockApiClient,
      platformScanner: mockScanner,
    );

    engine = DiscoveryEngine(
      scannerService: scannerService,
      duplicateDetectionService: duplicateService,
    );
  });

  test('runDiscovery when no files found ends in complete phase with empty list', () async {
    final phases = <DiscoveryEnginePhase>[];
    engine.addListener(() {
      phases.add(engine.progress.phase);
    });

    final results = await engine.runDiscovery();

    expect(results, isEmpty);
    expect(engine.classifiedBooks, isEmpty);
    expect(engine.progress.phase, DiscoveryEnginePhase.complete);
    expect(engine.progress.statusMessage, contains('No book files found'));
    expect(phases, containsAll([DiscoveryEnginePhase.scanning, DiscoveryEnginePhase.complete]));
  });

  test('runDiscovery performs complete pipeline: scanning, hashing, duplicate detection, and classification', () async {
    const folder = ScanFolder(id: 'f1', name: 'Books', pathOrUri: '/books');
    await folderManager.registerFolder(folder);

    final f1 = DiscoveredFile(
      id: 'b1',
      name: 'atomic_habits.pdf',
      pathOrUri: '/books/atomic_habits.pdf',
      extension: 'pdf',
      sizeBytes: 10000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: pdfHeader,
    );

    final f2 = DiscoveredFile(
      id: 'b2',
      name: 'gatsby.epub',
      pathOrUri: '/books/gatsby.epub',
      extension: 'epub',
      sizeBytes: 20000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: epubHeader,
    );

    final f3 = DiscoveredFile(
      id: 'b3',
      name: 'gatsby_copy.epub',
      pathOrUri: '/books/gatsby_copy.epub',
      extension: 'epub',
      sizeBytes: 20000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: epubHeader,
    );

    final f4 = DiscoveredFile(
      id: 'b4',
      name: 'broken.epub',
      pathOrUri: '/books/broken.epub',
      extension: 'epub',
      sizeBytes: 5000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: epubHeader,
    );

    mockScanner.folderFiles['f1'] = [f1, f2, f3, f4];

    final progressPhases = <DiscoveryEnginePhase>[];
    engine.addListener(() {
      progressPhases.add(engine.progress.phase);
    });

    final results = await engine.runDiscovery();

    expect(results.length, 4);
    expect(progressPhases, contains(DiscoveryEnginePhase.scanning));
    expect(progressPhases, contains(DiscoveryEnginePhase.processingAndHashing));
    expect(progressPhases, contains(DiscoveryEnginePhase.complete));

    // Verify getter categorization
    expect(engine.newBooks.length, 1);
    expect(engine.newBooks.first.file.name, 'atomic_habits.pdf');
    expect(engine.newBooks.first.isImportable, isTrue);

    expect(engine.alreadyImportedBooks.length, 1);
    expect(engine.alreadyImportedBooks.first.file.name, 'gatsby.epub');
    expect(engine.alreadyImportedBooks.first.existingBookTitle, 'The Great Gatsby');
    expect(engine.alreadyImportedBooks.first.isAlreadyImported, isTrue);

    expect(engine.duplicateInScanBooks.length, 1);
    expect(engine.duplicateInScanBooks.first.file.name, 'gatsby_copy.epub');
    expect(engine.duplicateInScanBooks.first.isDuplicateInScan, isTrue);
    expect(engine.duplicateInScanBooks.first.existingBookTitle, 'The Great Gatsby'); // propagated

    expect(engine.invalidOrErrorBooks.length, 1);
    expect(engine.invalidOrErrorBooks.first.file.name, 'broken.epub');
    expect(engine.invalidOrErrorBooks.first.hasError, isTrue);

    // Verify progress final state
    expect(engine.progress.phase, DiscoveryEnginePhase.complete);
    expect(engine.progress.progressPercent, 1.0);
    expect(engine.progress.totalFiles, 4);
    expect(engine.progress.processedFiles, 4);
  });

  test('runDiscovery NEVER triggers book upload or import endpoints', () async {
    const folder = ScanFolder(id: 'f1', name: 'Books', pathOrUri: '/books');
    await folderManager.registerFolder(folder);

    final file = DiscoveredFile(
      id: 'b1',
      name: 'atomic_habits.pdf',
      pathOrUri: '/books/atomic_habits.pdf',
      extension: 'pdf',
      sizeBytes: 10000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: pdfHeader,
    );

    mockScanner.folderFiles['f1'] = [file];

    await engine.runDiscovery();

    // Verify API endpoints invoked
    // Only /books/check-duplicates is allowed!
    for (final endpoint in mockApiClient.endpointsCalled) {
      expect(endpoint, equals('/books/check-duplicates'));
      expect(endpoint, isNot(equals('/books')));
      expect(endpoint, isNot(contains('/upload')));
      expect(endpoint, isNot(contains('/import')));
    }
  });

  test('runDiscovery transitions to error phase when scanner throws an exception', () async {
    final throwingScannerService = ThrowingScannerService(
      scanner: mockScanner,
      folderManager: folderManager,
    );
    final errorEngine = DiscoveryEngine(
      scannerService: throwingScannerService,
      duplicateDetectionService: duplicateService,
    );

    final results = await errorEngine.runDiscovery();

    expect(results, isEmpty);
    expect(errorEngine.progress.phase, DiscoveryEnginePhase.error);
    expect(errorEngine.progress.statusMessage, contains('Discovery failed'));
  });

  test('reset clears classified books and returns engine to idle phase', () async {
    const folder = ScanFolder(id: 'f1', name: 'Books', pathOrUri: '/books');
    await folderManager.registerFolder(folder);

    final file = DiscoveredFile(
      id: 'b1',
      name: 'atomic_habits.pdf',
      pathOrUri: '/books/atomic_habits.pdf',
      extension: 'pdf',
      sizeBytes: 10000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: pdfHeader,
    );

    mockScanner.folderFiles['f1'] = [file];

    await engine.runDiscovery();
    expect(engine.classifiedBooks, isNotEmpty);
    expect(engine.progress.phase, DiscoveryEnginePhase.complete);

    engine.reset();
    expect(engine.classifiedBooks, isEmpty);
    expect(engine.progress.phase, DiscoveryEnginePhase.idle);
    expect(engine.progress.statusMessage, 'Ready to discover books');
  });

  test('retryVerification transitions phase to checkingDuplicates and re-evaluates unverified books', () async {
    const folder = ScanFolder(id: 'f1', name: 'Books', pathOrUri: '/books');
    await folderManager.registerFolder(folder);

    final file = DiscoveredFile(
      id: 'b1',
      name: 'atomic_habits.pdf',
      pathOrUri: '/books/atomic_habits.pdf',
      extension: 'pdf',
      sizeBytes: 10000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: pdfHeader,
    );

    mockScanner.folderFiles['f1'] = [file];

    // Initial run: API fails
    mockApiClient.postResponse = null; // causes offline failure
    await engine.runDiscovery();

    expect(engine.unverifiedBooks.length, 1);
    expect(engine.unverifiedBooks.first.isImportable, isFalse);

    // Backend comes online
    mockApiClient.postResponse = {
      'duplicates': [],
      'verifiedChecksums': ['hash_habits'],
    };

    final phases = <DiscoveryEnginePhase>[];
    engine.addListener(() {
      phases.add(engine.progress.phase);
    });

    final retried = await engine.retryVerification();

    expect(retried.length, 1);
    expect(engine.newBooks.length, 1);
    expect(engine.unverifiedBooks, isEmpty);
    expect(engine.newBooks.first.isImportable, isTrue);
    expect(phases, contains(DiscoveryEnginePhase.checkingDuplicates));
    expect(phases, contains(DiscoveryEnginePhase.complete));
  });
}

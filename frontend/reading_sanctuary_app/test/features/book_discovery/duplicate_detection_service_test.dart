import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/core/network/api_exception.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/duplicate_status.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/duplicate_detection_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/file_checksum_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/platform_book_scanner.dart';

class FakeApiClient extends ApiClient {
  dynamic postResponse;
  dynamic postError;
  final List<Map<String, dynamic>> postCalls = [];
  dynamic Function(String endpoint, dynamic body)? onPost;

  FakeApiClient({this.postResponse, this.postError, this.onPost})
      : super(tokenProvider: () => 'test_token');

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    postCalls.add({'endpoint': endpoint, 'body': body});
    if (onPost != null) {
      return onPost!(endpoint, body);
    }
    if (postError != null) {
      throw postError!;
    }
    return postResponse;
  }
}

class FakeChecksumService extends FileChecksumService {
  final Map<String, String?> predefinedHashes;
  final List<String> hashedPaths = [];

  FakeChecksumService(this.predefinedHashes);

  @override
  Future<String?> computeChecksum(DiscoveredFile file) async {
    hashedPaths.add(file.pathOrUri);
    return predefinedHashes[file.pathOrUri];
  }
}

class FakePlatformScanner implements PlatformBookScanner {
  final Map<String, Uint8List?> headers;
  FakePlatformScanner({this.headers = const {}});

  @override
  String get platformCapabilitiesDescription => 'Fake Scanner';

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
  }) async => [];

  @override
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async* {}

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async {
    return headers[pathOrUri];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Standard magic byte headers
  final pdfHeader = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF
  final epubHeader = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]); // PK..
  final mp3Header = Uint8List.fromList([0x49, 0x44, 0x33, 0x03]); // ID3

  test('classifyFiles classifies empty files (0 bytes) as invalid', () async {
    final fakeChecksum = FakeChecksumService({});
    final service = DuplicateDetectionService(checksumService: fakeChecksum);

    final emptyFile = DiscoveredFile(
      id: 'empty-1',
      name: 'corrupted.pdf',
      pathOrUri: '/books/corrupted.pdf',
      extension: 'pdf',
      sizeBytes: 0,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
    );

    final results = await service.classifyFiles([emptyFile]);

    expect(results.length, 1);
    expect(results.first.classification, DuplicateClassification.invalid);
    expect(results.first.isValidFormat, isFalse);
    expect(results.first.errorMessage, contains('0 bytes'));
    expect(fakeChecksum.hashedPaths, isEmpty); // Must not attempt hashing
  });

  test('classifyFiles classifies signature mismatch as invalid and skips hashing', () async {
    final fakeChecksum = FakeChecksumService({});
    final service = DuplicateDetectionService(checksumService: fakeChecksum);

    final invalidPdf = DiscoveredFile(
      id: 'bad-1',
      name: 'fake.pdf',
      pathOrUri: '/books/fake.pdf',
      extension: 'pdf',
      sizeBytes: 2048,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: Uint8List.fromList([0x47, 0x49, 0x46, 0x38]), // GIF89a magic bytes
    );

    final results = await service.classifyFiles([invalidPdf]);

    expect(results.length, 1);
    expect(results.first.classification, DuplicateClassification.invalid);
    expect(results.first.isValidFormat, isFalse);
    expect(results.first.errorMessage, contains('does not match PDF format'));
    expect(fakeChecksum.hashedPaths, isEmpty);
  });

  test('classifyFiles reads header from platformScanner when headerBytes is null', () async {
    final fakeChecksum = FakeChecksumService({'/books/read_header.pdf': 'valid_hash_123'});
    final fakeScanner = FakePlatformScanner(
      headers: {'/books/read_header.pdf': pdfHeader},
    );
    final fakeApi = FakeApiClient(postResponse: {'duplicates': [], 'verifiedChecksums': ['valid_hash_123']});
    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      platformScanner: fakeScanner,
      apiClient: fakeApi,
    );

    final file = DiscoveredFile(
      id: 'header-1',
      name: 'read_header.pdf',
      pathOrUri: '/books/read_header.pdf',
      extension: 'pdf',
      sizeBytes: 4096,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: null, // deliberately null
    );

    final results = await service.classifyFiles([file]);

    expect(results.length, 1);
    expect(results.first.isValidFormat, isTrue);
    expect(results.first.checksum, 'valid_hash_123');
    expect(results.first.classification, DuplicateClassification.newBook);
    expect(fakeChecksum.hashedPaths, contains('/books/read_header.pdf'));
  });

  test('classifyFiles classifies unreadable / unhashable file as error', () async {
    final fakeChecksum = FakeChecksumService({
      '/books/locked.epub': null, // failed hash
    });
    final service = DuplicateDetectionService(checksumService: fakeChecksum);

    final lockedFile = DiscoveredFile(
      id: 'locked-1',
      name: 'locked.epub',
      pathOrUri: '/books/locked.epub',
      extension: 'epub',
      sizeBytes: 10000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: epubHeader,
    );

    final results = await service.classifyFiles([lockedFile]);

    expect(results.length, 1);
    expect(results.first.classification, DuplicateClassification.error);
    expect(results.first.errorMessage, contains('Could not access or hash'));
  });

  test('classifyFiles detects duplicates within the scan across different folders and preserves relationship', () async {
    const identicalHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
    final fakeChecksum = FakeChecksumService({
      '/downloads/Atomic Habits.pdf': identicalHash,
      '/documents/backups/Atomic Habits Copy.pdf': identicalHash,
    });
    final fakeApi = FakeApiClient(postResponse: {'duplicates': [], 'verifiedChecksums': [identicalHash]});
    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      apiClient: fakeApi,
    );

    final file1 = DiscoveredFile(
      id: 'f1',
      name: 'Atomic Habits.pdf',
      pathOrUri: '/downloads/Atomic Habits.pdf',
      extension: 'pdf',
      sizeBytes: 50000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/downloads',
      headerBytes: pdfHeader,
    );

    final file2 = DiscoveredFile(
      id: 'f2',
      name: 'Atomic Habits Copy.pdf',
      pathOrUri: '/documents/backups/Atomic Habits Copy.pdf',
      extension: 'pdf',
      sizeBytes: 50000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/documents/backups',
      headerBytes: pdfHeader,
    );

    final results = await service.classifyFiles([file1, file2]);

    expect(results.length, 2);

    final duplicateInScan = results.firstWhere((r) => r.file.id == 'f2');
    expect(duplicateInScan.classification, DuplicateClassification.duplicateInScan);
    expect(duplicateInScan.duplicateOfPathOrUri, '/downloads/Atomic Habits.pdf');
    expect(duplicateInScan.isImportable, isFalse);

    final primary = results.firstWhere((r) => r.file.id == 'f1');
    expect(primary.classification, DuplicateClassification.newBook);
    expect(primary.isImportable, isTrue);
  });

  test('classifyFiles queries backend duplicate check and identifies alreadyImported books', () async {
    const importedHash = 'aaaa1111222233334444555566667777888899990000aaaabbbbccccddddeeee';
    const newHash = 'bbbb1111222233334444555566667777888899990000aaaabbbbccccddddeeee';

    final fakeChecksum = FakeChecksumService({
      '/books/imported_book.epub': importedHash,
      '/books/brand_new_book.epub': newHash,
    });

    final fakeApi = FakeApiClient(
      postResponse: {
        'duplicates': [
          {
            'clientRefId': 'f-imported',
            'checksum': importedHash,
            'existingBookId': 'book-uuid-999',
            'existingBookTitle': 'The Great Gatsby',
            'existingFileFormat': 'EPUB',
            'existingFileName': 'gatsby.epub',
          }
        ],
        'existingChecksums': [importedHash],
        'verifiedChecksums': [importedHash, newHash],
      },
    );

    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      apiClient: fakeApi,
    );

    final fileImported = DiscoveredFile(
      id: 'f-imported',
      name: 'imported_book.epub',
      pathOrUri: '/books/imported_book.epub',
      extension: 'epub',
      sizeBytes: 15000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: epubHeader,
    );

    final fileNew = DiscoveredFile(
      id: 'f-new',
      name: 'brand_new_book.epub',
      pathOrUri: '/books/brand_new_book.epub',
      extension: 'epub',
      sizeBytes: 25000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: epubHeader,
    );

    final results = await service.classifyFiles([fileImported, fileNew]);

    // Verify classification
    final importedResult = results.firstWhere((r) => r.file.id == 'f-imported');
    expect(importedResult.classification, DuplicateClassification.alreadyImported);
    expect(importedResult.existingBookTitle, 'The Great Gatsby');
    expect(importedResult.existingBookId, 'book-uuid-999');
    expect(importedResult.isImportable, isFalse);

    final newResult = results.firstWhere((r) => r.file.id == 'f-new');
    expect(newResult.classification, DuplicateClassification.newBook);
    expect(newResult.existingBookTitle, isNull);
    expect(newResult.isImportable, isTrue);
  });

  test('classifyFiles propagates existingBookTitle to scan duplicates of already imported books', () async {
    const importedHash = 'hash_imported_book_xyz';
    final fakeChecksum = FakeChecksumService({
      '/folder1/book.epub': importedHash,
      '/folder2/book_copy.epub': importedHash,
    });

    final fakeApi = FakeApiClient(
      postResponse: {
        'duplicates': [
          {
            'clientRefId': 'b1',
            'checksum': importedHash,
            'existingBookId': 'book-uuid-777',
            'existingBookTitle': 'Dune',
          }
        ],
        'verifiedChecksums': [importedHash],
      },
    );

    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      apiClient: fakeApi,
    );

    final file1 = DiscoveredFile(
      id: 'b1',
      name: 'book.epub',
      pathOrUri: '/folder1/book.epub',
      extension: 'epub',
      sizeBytes: 30000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/folder1',
      headerBytes: epubHeader,
    );

    final file2 = DiscoveredFile(
      id: 'b2',
      name: 'book_copy.epub',
      pathOrUri: '/folder2/book_copy.epub',
      extension: 'epub',
      sizeBytes: 30000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/folder2',
      headerBytes: epubHeader,
    );

    final results = await service.classifyFiles([file1, file2]);

    final primary = results.firstWhere((r) => r.file.id == 'b1');
    expect(primary.classification, DuplicateClassification.alreadyImported);
    expect(primary.existingBookTitle, 'Dune');

    final scanDuplicate = results.firstWhere((r) => r.file.id == 'b2');
    expect(scanDuplicate.classification, DuplicateClassification.duplicateInScan);
    expect(scanDuplicate.existingBookTitle, 'Dune');
    expect(scanDuplicate.existingBookId, 'book-uuid-777');
    expect(scanDuplicate.isImportable, isFalse);
  });

  // REGRESSION TEST 1 & 2
  test('Regression 1 & 2: Backend unavailable: files must not become newBook and must not be importable', () async {
    final fakeChecksum = FakeChecksumService({
      '/books/offline.mp3': 'offline_hash_111',
    });

    final fakeApi = FakeApiClient(
      postError: const NetworkException('Connection refused - device offline'),
    );

    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      apiClient: fakeApi,
    );

    final file = DiscoveredFile(
      id: 'off-1',
      name: 'offline.mp3',
      pathOrUri: '/books/offline.mp3',
      extension: 'mp3',
      sizeBytes: 100000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: mp3Header,
    );

    final results = await service.classifyFiles([file]);

    expect(results.length, 1);
    final book = results.first;

    // Must NOT become newBook (Regression 1)
    expect(book.classification, isNot(equals(DuplicateClassification.newBook)));
    expect(book.classification, equals(DuplicateClassification.verificationFailed));

    // Must NOT be importable (Regression 2)
    expect(book.isImportable, isFalse);

    // Calculated checksum must be preserved
    expect(book.checksum, equals('offline_hash_111'));
    expect(book.isValidFormat, isTrue);
    expect(book.hasError, isTrue);
    expect(book.errorMessage, contains('Connection refused'));
  });

  // REGRESSION TEST 3 & 4
  test('Regression 3 & 4: Successful retry: verified new files become newBook, existing become alreadyImported', () async {
    const newHash = 'hash_new_book';
    const existingHash = 'hash_existing_book';

    final fakeChecksum = FakeChecksumService({
      '/books/new.epub': newHash,
      '/books/existing.epub': existingHash,
    });

    // Initial scan: backend fails
    final fakeApi = FakeApiClient(
      postError: const NetworkException('Initial network outage'),
    );

    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      apiClient: fakeApi,
    );

    final f1 = DiscoveredFile(
      id: 'f1',
      name: 'new.epub',
      pathOrUri: '/books/new.epub',
      extension: 'epub',
      sizeBytes: 10000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: epubHeader,
    );

    final f2 = DiscoveredFile(
      id: 'f2',
      name: 'existing.epub',
      pathOrUri: '/books/existing.epub',
      extension: 'epub',
      sizeBytes: 20000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: epubHeader,
    );

    final initialResults = await service.classifyFiles([f1, f2]);
    expect(initialResults.every((b) => b.classification == DuplicateClassification.verificationFailed), isTrue);
    expect(initialResults.every((b) => !b.isImportable), isTrue);

    // Configure retry: backend now succeeds!
    fakeApi.postError = null;
    fakeApi.postResponse = {
      'duplicates': [
        {
          'clientRefId': 'f2',
          'checksum': existingHash,
          'existingBookId': 'book-uuid-existing',
          'existingBookTitle': 'War and Peace',
        }
      ],
      'verifiedChecksums': [newHash, existingHash],
    };

    // Track hasher calls: retry must NOT recalculate checksums
    fakeChecksum.hashedPaths.clear();

    final retriedResults = await service.retryVerification(initialResults);

    // Zero hash recalculations
    expect(fakeChecksum.hashedPaths, isEmpty);

    // Regression 3: Verified new files become newBook and are importable
    final newBook = retriedResults.firstWhere((b) => b.file.id == 'f1');
    expect(newBook.classification, equals(DuplicateClassification.newBook));
    expect(newBook.isImportable, isTrue);

    // Regression 4: Existing files become alreadyImported
    final existingBook = retriedResults.firstWhere((b) => b.file.id == 'f2');
    expect(existingBook.classification, equals(DuplicateClassification.alreadyImported));
    expect(existingBook.existingBookTitle, 'War and Peace');
    expect(existingBook.existingBookId, 'book-uuid-existing');
    expect(existingBook.isImportable, isFalse);
  });

  // REGRESSION TEST 5
  test('Regression 5: Partial backend response: unverified files remain non-importable', () async {
    const verifiedHash = 'hash_verified_123';
    const unverifiedHash = 'hash_missing_from_response';

    final fakeChecksum = FakeChecksumService({
      '/books/b1.pdf': verifiedHash,
      '/books/b2.pdf': unverifiedHash,
    });

    // Backend responds with status for b1 only, omitting b2
    final fakeApi = FakeApiClient(
      postResponse: {
        'duplicates': [],
        'verifiedChecksums': [verifiedHash], // only b1 is verified
      },
    );

    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      apiClient: fakeApi,
    );

    final file1 = DiscoveredFile(
      id: 'b1',
      name: 'b1.pdf',
      pathOrUri: '/books/b1.pdf',
      extension: 'pdf',
      sizeBytes: 1000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: pdfHeader,
    );

    final file2 = DiscoveredFile(
      id: 'b2',
      name: 'b2.pdf',
      pathOrUri: '/books/b2.pdf',
      extension: 'pdf',
      sizeBytes: 2000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/books',
      headerBytes: pdfHeader,
    );

    final results = await service.classifyFiles([file1, file2]);

    final b1Result = results.firstWhere((r) => r.file.id == 'b1');
    expect(b1Result.classification, DuplicateClassification.newBook);
    expect(b1Result.isImportable, isTrue);

    // b2 omitted from backend response: must remain non-importable verificationFailed
    final b2Result = results.firstWhere((r) => r.file.id == 'b2');
    expect(b2Result.classification, DuplicateClassification.verificationFailed);
    expect(b2Result.isImportable, isFalse);
    expect(b2Result.checksum, equals(unverifiedHash));
  });

  // REGRESSION TEST 6
  test('Regression 6: One failed batch among multiple batches', () async {
    // Generate 150 files: batch 1 has 100 files, batch 2 has 50 files
    final hashes = <String, String>{};
    final files = <DiscoveredFile>[];

    for (var i = 1; i <= 150; i++) {
      final path = '/books/book_$i.pdf';
      final hash = 'hash_$i';
      hashes[path] = hash;
      files.add(
        DiscoveredFile(
          id: 'file-$i',
          name: 'book_$i.pdf',
          pathOrUri: path,
          extension: 'pdf',
          sizeBytes: 1000 + i,
          lastModified: DateTime.now(),
          parentFolderIdentifier: '/books',
          headerBytes: pdfHeader,
        ),
      );
    }

    final fakeChecksum = FakeChecksumService(hashes);

    var callCount = 0;
    final fakeApi = FakeApiClient(
      onPost: (endpoint, body) {
        callCount++;
        if (callCount == 1) {
          // Batch 1 (files 1..100) succeeds
          final batchFiles = (body as Map<String, dynamic>)['files'] as List<dynamic>;
          final verifiedList = batchFiles.map((f) => f['checksum'] as String).toList();
          return {
            'duplicates': [],
            'verifiedChecksums': verifiedList,
          };
        } else {
          // Batch 2 (files 101..150) fails!
          throw const ServerException('HTTP 500: Database connection timeout in batch 2');
        }
      },
    );

    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      apiClient: fakeApi,
    );

    final results = await service.classifyFiles(files);

    expect(results.length, 150);

    // Batch 1 files (1..100) must be successfully verified as newBook
    final batch1Results = results.where((r) => int.parse(r.file.id.split('-')[1]) <= 100).toList();
    expect(batch1Results.length, 100);
    expect(batch1Results.every((r) => r.classification == DuplicateClassification.newBook), isTrue);
    expect(batch1Results.every((r) => r.isImportable), isTrue);

    // Batch 2 files (101..150) must be verificationFailed and NOT importable
    final batch2Results = results.where((r) => int.parse(r.file.id.split('-')[1]) > 100).toList();
    expect(batch2Results.length, 50);
    expect(batch2Results.every((r) => r.classification == DuplicateClassification.verificationFailed), isTrue);
    expect(batch2Results.every((r) => !r.isImportable), isTrue);
    expect(batch2Results.first.errorMessage, contains('Database connection timeout'));
  });

  test('classifyFiles reports accurate step-by-step progress via onProgress callback', () async {
    final fakeChecksum = FakeChecksumService({
      '/books/b1.pdf': 'hash1',
      '/books/b2.pdf': 'hash2',
    });

    final fakeApi = FakeApiClient(postResponse: {'duplicates': [], 'verifiedChecksums': ['hash1', 'hash2']});

    final service = DuplicateDetectionService(
      checksumService: fakeChecksum,
      apiClient: fakeApi,
    );

    final files = [
      DiscoveredFile(
        id: '1',
        name: 'b1.pdf',
        pathOrUri: '/books/b1.pdf',
        extension: 'pdf',
        sizeBytes: 100,
        lastModified: DateTime.now(),
        parentFolderIdentifier: '/books',
        headerBytes: pdfHeader,
      ),
      DiscoveredFile(
        id: '2',
        name: 'b2.pdf',
        pathOrUri: '/books/b2.pdf',
        extension: 'pdf',
        sizeBytes: 200,
        lastModified: DateTime.now(),
        parentFolderIdentifier: '/books',
        headerBytes: pdfHeader,
      ),
    ];

    final progressUpdates = <Map<String, dynamic>>[];
    await service.classifyFiles(
      files,
      onProgress: (processed, total, currentName) {
        progressUpdates.add({
          'processed': processed,
          'total': total,
          'currentName': currentName,
        });
      },
    );

    expect(progressUpdates.length, 2);
    expect(progressUpdates[0], {'processed': 1, 'total': 2, 'currentName': 'b1.pdf'});
    expect(progressUpdates[1], {'processed': 2, 'total': 2, 'currentName': 'b2.pdf'});
  });
}

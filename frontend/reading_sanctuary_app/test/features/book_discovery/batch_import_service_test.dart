import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/batch_import_state.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/classified_book.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/duplicate_status.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/batch_import_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform_file_stream_service.dart';
import 'package:reading_sanctuary_app/features/library/data/models/book_metadata.dart';
import 'package:reading_sanctuary_app/features/library/data/models/reconcile_response.dart';
import 'package:reading_sanctuary_app/features/library/data/models/selected_book_file.dart';
import 'package:reading_sanctuary_app/features/library/data/services/book_upload_service.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';

class FakeBookUploadService extends BookUploadService {
  final List<String> uploadedFiles = [];
  final List<String> confirmedUploadIds = [];
  final List<String> reconciledChecksums = [];
  ReconcileResponse? reconcileResponseOverride;
  String? uploadFailureOn;
  String? confirmFailureOn;

  FakeBookUploadService() : super(apiClient: ApiClient(tokenProvider: () => 'token'));

  @override
  Future<ReconcileResponse> reconcileUpload({
    String? uploadId,
    required String checksum,
  }) async {
    reconciledChecksums.add(checksum);
    if (reconcileResponseOverride != null) {
      return reconcileResponseOverride!;
    }
    return const ReconcileResponse(status: ReconcileStatus.notFound);
  }

  @override
  Future<BookMetadata> uploadBook(SelectedBookFile file, {void Function(int sent, int total)? onProgress}) async {
    uploadedFiles.add(file.name);
    onProgress?.call(100, 100);
    if (uploadFailureOn == file.name) {
      throw Exception('Network timeout during upload of ${file.name}');
    }
    return BookMetadata(
      uploadId: 'upload-${file.name}',
      title: file.name.replaceAll('.epub', ''),
      author: 'Author of ${file.name}',
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
    confirmedUploadIds.add(uploadId);
    if (confirmFailureOn == uploadId) {
      throw Exception('Failed confirming $uploadId: Duplicate title conflict');
    }
    return Book(
      id: 'book-$uploadId',
      title: metadata.title ?? 'Untitled',
      author: metadata.author ?? 'Unknown',
      genre: metadata.genre ?? 'General',
      description: metadata.description ?? '',
      status: ReadingStatus.toRead,
      progress: 0.0,
      pages: metadata.pages ?? 200,
      formats: const [BookFormat.ebook],
      addedAt: DateTime.now(),
      coverColors: const [],
    );
  }
}

class FakeStreamService extends PlatformFileStreamService {
  @override
  Future<SelectedBookFile> createSelectedBookFile(DiscoveredFile file) async {
    return SelectedBookFile(
      name: file.name,
      extension: file.extension,
      size: file.sizeBytes,
      readStream: Stream.value([1, 2, 3]),
    );
  }
}

void main() {
  late FakeBookUploadService uploadService;
  late FakeStreamService streamService;
  late BatchImportService batchService;
  var libraryInvalidatedCount = 0;

  ClassifiedBook createBook(String name, {DuplicateClassification classification = DuplicateClassification.newBook}) {
    return ClassifiedBook(
      file: DiscoveredFile(
        id: name,
        name: name,
        pathOrUri: '/books/$name',
        extension: 'epub',
        sizeBytes: 1000,
        lastModified: DateTime.now(),
        parentFolderIdentifier: '/books',
      ),
      checksum: 'hash_$name',
      classification: classification,
      isValidFormat: true,
    );
  }

  setUp(() {
    libraryInvalidatedCount = 0;
    uploadService = FakeBookUploadService();
    streamService = FakeStreamService();
    batchService = BatchImportService(
      uploadService: uploadService,
      streamService: streamService,
      onLibraryUpdated: () => libraryInvalidatedCount++,
    );
  });

  test('Single-book import: uploads and confirms single book, refreshing library', () async {
    final book = createBook('The_Hobbit.epub');

    BatchImportState? finalState;
    await batchService.runBatchImport(
      books: [book],
      onStateChange: (s) => finalState = s,
    );

    expect(finalState, isNotNull);
    expect(finalState!.status, BatchImportStatus.completed);
    expect(finalState!.completedCount, 1);
    expect(finalState!.failedCount, 0);
    expect(finalState!.overallProgress, 1.0);

    expect(uploadService.uploadedFiles, contains('The_Hobbit.epub'));
    expect(uploadService.confirmedUploadIds, contains('upload-The_Hobbit.epub'));
    expect(libraryInvalidatedCount, 1);

    final item = finalState!.items['/books/The_Hobbit.epub'];
    expect(item, isNotNull);
    expect(item!.isCompleted, isTrue);
    expect(item.importedBook?.title, 'The_Hobbit');
  });

  test('Multiple-book import: imports all queued books and tracks progress smoothly', () async {
    final b1 = createBook('Book1.epub');
    final b2 = createBook('Book2.epub');
    final b3 = createBook('Book3.epub');

    final progressStates = <double>[];
    BatchImportState? finalState;

    await batchService.runBatchImport(
      books: [b1, b2, b3],
      onStateChange: (s) {
        progressStates.add(s.overallProgress);
        finalState = s;
      },
    );

    expect(finalState!.status, BatchImportStatus.completed);
    expect(finalState!.completedCount, 3);
    expect(finalState!.failedCount, 0);
    expect(uploadService.uploadedFiles.length, 3);
    expect(uploadService.confirmedUploadIds.length, 3);
    expect(libraryInvalidatedCount, 3);
    expect(progressStates.last, 1.0);
  });

  test('Partial batch failure: one failed book does not terminate the entire batch', () async {
    final b1 = createBook('Good1.epub');
    final b2 = createBook('Bad2.epub');
    final b3 = createBook('Good3.epub');

    // Make book 2 fail
    uploadService.uploadFailureOn = 'Bad2.epub';

    BatchImportState? finalState;
    await batchService.runBatchImport(
      books: [b1, b2, b3],
      onStateChange: (s) => finalState = s,
    );

    expect(finalState!.completedCount, 2);
    expect(finalState!.failedCount, 1);
    expect(finalState!.hasFailures, isTrue);

    // B1 and B3 must have succeeded
    expect(finalState!.items['/books/Good1.epub']!.isCompleted, isTrue);
    expect(finalState!.items['/books/Good3.epub']!.isCompleted, isTrue);

    // B2 must be marked failed with clear error message
    final failedItem = finalState!.items['/books/Bad2.epub']!;
    expect(failedItem.isFailed, isTrue);
    expect(failedItem.errorMessage, contains('Network timeout during upload of Bad2.epub'));

    // Library invalidated for successful books
    expect(libraryInvalidatedCount, 2);
  });

  test('Retry failed imports: re-imports only failed books without touching completed books', () async {
    final b1 = createBook('Good1.epub');
    final b2 = createBook('FailThenSucceed.epub');

    // First attempt: b2 fails
    uploadService.uploadFailureOn = 'FailThenSucceed.epub';

    BatchImportState? stateAfterFirstRun;
    await batchService.runBatchImport(
      books: [b1, b2],
      onStateChange: (s) => stateAfterFirstRun = s,
    );

    expect(stateAfterFirstRun!.completedCount, 1);
    expect(stateAfterFirstRun!.failedCount, 1);

    // Fix failure condition and retry
    uploadService.uploadFailureOn = null;
    uploadService.uploadedFiles.clear();

    BatchImportState? retryState;
    await batchService.retryFailedImports(
      currentState: stateAfterFirstRun!,
      onStateChange: (s) => retryState = s,
    );

    expect(retryState!.completedCount, 1);
    expect(retryState!.failedCount, 0);
    // Only the failed book was uploaded during retry
    expect(uploadService.uploadedFiles, equals(['FailThenSucceed.epub']));
  });

  test('Cancellation behavior: stops processing remaining books and marks them cancelled', () async {
    final b1 = createBook('Book1.epub');
    final b2 = createBook('Book2.epub');
    final b3 = createBook('Book3.epub');

    var cancelRequested = false;
    BatchImportState? finalState;

    await batchService.runBatchImport(
      books: [b1, b2, b3],
      onStateChange: (s) {
        finalState = s;
        // Request cancellation as soon as Book1 completes
        if (s.completedCount == 1) {
          cancelRequested = true;
        }
      },
      isCancelled: () => cancelRequested,
    );

    expect(finalState!.status, BatchImportStatus.cancelled);
    expect(finalState!.completedCount, 1);
    expect(finalState!.items['/books/Book1.epub']!.isCompleted, isTrue);
    expect(finalState!.items['/books/Book2.epub']!.isCancelled, isTrue);
    expect(finalState!.items['/books/Book3.epub']!.isCancelled, isTrue);
  });

  test('Exclusion of non-importable classifications: filters out alreadyImported and unverified files', () async {
    final bValid = createBook('valid.epub', classification: DuplicateClassification.newBook);
    final bImported = createBook('imported.epub', classification: DuplicateClassification.alreadyImported);
    final bUnverified = createBook('unverified.epub', classification: DuplicateClassification.verificationFailed);

    BatchImportState? finalState;
    await batchService.runBatchImport(
      books: [bValid, bImported, bUnverified],
      onStateChange: (s) => finalState = s,
    );

    expect(finalState!.totalCount, 1);
    expect(uploadService.uploadedFiles, equals(['valid.epub']));
    expect(finalState!.items.containsKey('/books/imported.epub'), isFalse);
    expect(finalState!.items.containsKey('/books/unverified.epub'), isFalse);
  });

  test('Duplicate queue prevention: deduplicates items with identical pathOrUri in the queue', () async {
    final b1 = createBook('duplicate.epub');
    final b1Copy = createBook('duplicate.epub'); // same pathOrUri

    BatchImportState? finalState;
    await batchService.runBatchImport(
      books: [b1, b1Copy],
      onStateChange: (s) => finalState = s,
    );

    expect(finalState!.totalCount, 1);
    expect(uploadService.uploadedFiles.length, 1);
  });

  test('Confirmation retry safety: reconciles with backend when client response was lost and avoids duplicate uploads', () async {
    final book = createBook('LostResponseBook.epub');

    // Simulate confirmation failure due to network timeout (lost client response)
    uploadService.confirmFailureOn = 'upload-LostResponseBook.epub';

    BatchImportState? stateAfterDrop;
    await batchService.runBatchImport(
      books: [book],
      onStateChange: (s) => stateAfterDrop = s,
    );

    // Initial attempt failed during confirmation
    expect(stateAfterDrop!.failedCount, 1);
    expect(stateAfterDrop!.completedCount, 0);
    final failedItem = stateAfterDrop!.items['/books/LostResponseBook.epub']!;
    expect(failedItem.uploadId, 'upload-LostResponseBook.epub');
    expect(failedItem.retryCount, 1);

    // Now configure fake server reconciliation to show the book actually saved on backend
    uploadService.reconcileResponseOverride = ReconcileResponse(
      status: ReconcileStatus.alreadyConfirmed,
      checksum: 'hash_LostResponseBook.epub',
      book: Book(
        id: 'book-already-confirmed-123',
        title: 'LostResponseBook',
        author: 'Unknown',
        genre: 'General',
        description: '',
        status: ReadingStatus.toRead,
        progress: 0.0,
        pages: 200,
        formats: const [BookFormat.ebook],
        addedAt: DateTime.now(),
        coverColors: const [],
      ),
    );

    // Clear tracking
    uploadService.uploadedFiles.clear();
    uploadService.confirmedUploadIds.clear();

    BatchImportState? stateAfterRetry;
    await batchService.retryFailedImports(
      currentState: stateAfterDrop!,
      onStateChange: (s) => stateAfterRetry = s,
    );

    // Verify reconciliation succeeded without re-uploading or re-confirming!
    expect(stateAfterRetry!.completedCount, 1);
    expect(stateAfterRetry!.failedCount, 0);
    expect(stateAfterRetry!.items['/books/LostResponseBook.epub']!.isCompleted, isTrue);
    expect(stateAfterRetry!.items['/books/LostResponseBook.epub']!.importedBook!.id, 'book-already-confirmed-123');
    // ZERO new uploads and ZERO new confirmation requests were performed
    expect(uploadService.uploadedFiles, isEmpty);
    expect(uploadService.confirmedUploadIds, isEmpty);
    // Backend reconciliation was queried with the correct checksum
    expect(uploadService.reconciledChecksums, contains('hash_LostResponseBook.epub'));
  });
}

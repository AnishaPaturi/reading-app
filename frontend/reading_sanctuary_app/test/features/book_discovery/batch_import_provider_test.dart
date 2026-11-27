import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/batch_import_state.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/classified_book.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/duplicate_status.dart';
import 'package:reading_sanctuary_app/features/book_discovery/providers/batch_import_provider.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/batch_import_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform_file_stream_service.dart';
import 'package:reading_sanctuary_app/features/library/data/models/book_metadata.dart';
import 'package:reading_sanctuary_app/features/library/data/models/selected_book_file.dart';
import 'package:reading_sanctuary_app/features/library/data/services/book_upload_service.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';

class SlowFakeUploadService extends BookUploadService {
  final Completer<void> gate = Completer<void>();
  int uploadCallCount = 0;

  SlowFakeUploadService() : super(apiClient: ApiClient(tokenProvider: () => 'token'));

  @override
  Future<BookMetadata> uploadBook(SelectedBookFile file, {void Function(int sent, int total)? onProgress}) async {
    uploadCallCount++;
    await gate.future; // Hold until released
    return BookMetadata(
      uploadId: 'upload-${file.name}',
      title: file.name,
      format: 'EPUB',
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
      id: 'book-$uploadId',
      title: metadata.title ?? 'Untitled',
      author: 'Author',
      genre: 'General',
      description: '',
      status: ReadingStatus.toRead,
      progress: 0.0,
      pages: 100,
      formats: const [BookFormat.ebook],
      addedAt: DateTime.now(),
      coverColors: const [],
    );
  }
}

class ProviderFakeStreamService extends PlatformFileStreamService {
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
  late SlowFakeUploadService uploadService;
  late ProviderFakeStreamService streamService;
  late BatchImportService batchService;
  late BatchImportNotifier notifier;

  ClassifiedBook createBook(String name) {
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
      classification: DuplicateClassification.newBook,
      isValidFormat: true,
    );
  }

  setUp(() {
    uploadService = SlowFakeUploadService();
    streamService = ProviderFakeStreamService();
    batchService = BatchImportService(
      uploadService: uploadService,
      streamService: streamService,
    );
    notifier = BatchImportNotifier(service: batchService);
  });

  test('Riverpod provider state: initial state is idle with 0 progress', () {
    expect(notifier.state.status, BatchImportStatus.idle);
    expect(notifier.state.totalCount, 0);
    expect(notifier.state.completedCount, 0);
    expect(notifier.state.failedCount, 0);
    expect(notifier.state.overallProgress, 0.0);
    expect(notifier.state.isImporting, isFalse);
  });

  test('Double-submission protection: concurrent startImport calls while importing are ignored', () async {
    final book1 = createBook('slow1.epub');
    final book2 = createBook('slow2.epub');

    // Start first import (will pause at gate)
    final future1 = notifier.startImport([book1]);

    // Verify state transitioned to importing
    expect(notifier.state.isImporting, isTrue);

    // Attempt second import concurrently while first is in progress
    final future2 = notifier.startImport([book2]);

    // Release gate to complete first import
    uploadService.gate.complete();
    await future1;
    await future2;

    // Only 1 upload was ever called because the second was blocked by double-submission protection
    expect(uploadService.uploadCallCount, 1);
    expect(notifier.state.status, BatchImportStatus.completed);
  });

  test('Reset: returns state to idle and clears items', () async {
    final book = createBook('quick.epub');
    uploadService.gate.complete();

    await notifier.startImport([book]);
    expect(notifier.state.status, BatchImportStatus.completed);

    notifier.reset();
    expect(notifier.state.status, BatchImportStatus.idle);
    expect(notifier.state.items, isEmpty);
  });
}

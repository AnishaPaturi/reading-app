import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/features/library/data/models/book_metadata.dart';
import 'package:reading_sanctuary_app/features/library/data/models/selected_book_file.dart';
import 'package:reading_sanctuary_app/features/library/data/services/book_file_picker_service.dart';
import 'package:reading_sanctuary_app/features/library/data/services/book_upload_service.dart';
import 'package:reading_sanctuary_app/features/library/presentation/providers/book_upload_provider.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';

class FakePickerService extends BookFilePickerService {
  SelectedBookFile? fileToReturn;

  @override
  Future<SelectedBookFile?> pickBookFile() async => fileToReturn;
}

class FakeUploadService extends BookUploadService {
  FakeUploadService() : super(apiClient: ApiClient(tokenProvider: () => 'token'));

  @override
  Future<BookMetadata> uploadBook(SelectedBookFile file, {void Function(int sent, int total)? onProgress}) async {
    onProgress?.call(100, 100);
    return const BookMetadata(
      uploadId: 'upload-uuid-manual-1',
      title: 'Manual Upload Title',
      author: 'Manual Author',
      format: 'EPUB',
      pages: 350,
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
      id: 'book-uuid-1',
      title: metadata.title ?? 'Manual Upload Title',
      author: metadata.author ?? 'Manual Author',
      genre: 'General',
      description: '',
      status: ReadingStatus.toRead,
      progress: 0.0,
      pages: 350,
      formats: const [BookFormat.ebook],
      addedAt: DateTime.now(),
      coverColors: const [],
    );
  }
}

class MockBooksNotifier extends BooksNotifier {
  @override
  Future<List<Book>> build() async => [];
}

void main() {
  test('Existing Add Book flow regression: pickAndScanBook and confirmAndSaveBook succeed without error', () async {
    final pickerService = FakePickerService();
    pickerService.fileToReturn = const SelectedBookFile(
      name: 'manual_book.epub',
      extension: 'epub',
      size: 50000,
      path: '/path/manual_book.epub',
    );

    final uploadService = FakeUploadService();

    final testUploadNotifierProvider = StateNotifierProvider<BookUploadNotifier, BookUploadState>((ref) {
      return BookUploadNotifier(
        pickerService: pickerService,
        uploadService: uploadService,
        ref: ref,
      );
    });

    final container = ProviderContainer(
      overrides: [
        booksProvider.overrideWith(() => MockBooksNotifier()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(testUploadNotifierProvider.notifier);

    expect(notifier.state.status, BookUploadStatus.idle);

    // 1. Pick and scan file
    await notifier.pickAndScanBook();

    expect(notifier.state.status, BookUploadStatus.readyForReview);
    expect(notifier.state.uploadId, 'upload-uuid-manual-1');
    expect(notifier.state.metadata?.title, 'Manual Upload Title');

    // 2. Modify metadata in review screen
    notifier.updateMetadata(
      notifier.state.metadata!.copyWith(title: 'Edited Manual Title'),
    );
    expect(notifier.state.metadata?.title, 'Edited Manual Title');

    // 3. Confirm and save
    final savedBook = await notifier.confirmAndSaveBook(readingStatus: 'UNREAD');

    expect(savedBook, isNotNull);
    expect(notifier.state.status, BookUploadStatus.success);
    expect(notifier.state.savedBook?.title, 'Edited Manual Title');
  });
}

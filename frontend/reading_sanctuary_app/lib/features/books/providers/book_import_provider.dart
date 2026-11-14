import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_config.dart';
import '../../../features/authentication/presentation/providers/auth_provider.dart';
import '../../../features/bookshelf/presentation/providers/bookshelf_provider.dart';
import '../../../features/reader/presentation/providers/reader_provider.dart';
import '../../../shared/models/book.dart';
import '../../../shared/services/providers.dart';
import '../data/book_api_service.dart';

enum BookImportStatus {
  idle,
  uploading,
  processing,
  success,
  failure,
}

class BookImportState {
  final BookImportStatus status;
  final double uploadProgress;
  final String? errorMessage;
  final Book? importedBook;

  const BookImportState({
    this.status = BookImportStatus.idle,
    this.uploadProgress = 0.0,
    this.errorMessage,
    this.importedBook,
  });

  BookImportState copyWith({
    BookImportStatus? status,
    double? uploadProgress,
    String? errorMessage,
    Book? importedBook,
  }) {
    return BookImportState(
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      importedBook: importedBook ?? this.importedBook,
    );
  }
}

final bookApiServiceProvider = Provider<BookApiService>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
  return BookApiService(dio);
});

final bookImportProvider =
    StateNotifierProvider<BookImportNotifier, BookImportState>((ref) {
  final apiService = ref.watch(bookApiServiceProvider);
  return BookImportNotifier(apiService: apiService, ref: ref);
});

class BookImportNotifier extends StateNotifier<BookImportState> {
  final BookApiService _apiService;
  final Ref _ref;

  BookImportNotifier({
    required BookApiService apiService,
    required Ref ref,
  })  : _apiService = apiService,
        _ref = ref,
        super(const BookImportState());

  Future<Book?> importBook({
    required PlatformFile file,
    required String title,
    required String author,
    required String readingStatus,
    String? shelfId,
  }) async {
    state = state.copyWith(
      status: BookImportStatus.uploading,
      uploadProgress: 0.1,
      errorMessage: null,
    );

    try {
      final token = _ref.read(authTokenProvider) ??
          _ref.read(authNotifierProvider).user?.token ??
          '';

      final response = await _apiService.uploadBook(
        file: file,
        accessToken: token,
        title: title,
        author: author,
        readingStatus: readingStatus,
        shelfId: shelfId,
        onSendProgress: (sent, total) {
          if (total > 0) {
            final progress = (sent / total).clamp(0.1, 0.95);
            state = state.copyWith(
              uploadProgress: progress,
              status: progress >= 0.9
                  ? BookImportStatus.processing
                  : BookImportStatus.uploading,
            );
          }
        },
      );

      final book = Book.fromJson(response);

      // Invalidate existing library and bookshelf providers
      _ref.invalidate(booksProvider);
      _ref.invalidate(bookshelfListNotifierProvider);

      if (shelfId != null && shelfId.isNotEmpty) {
        try {
          await _ref
              .read(bookshelfListNotifierProvider.notifier)
              .addBookToShelf(shelfId, book.id);
        } catch (_) {}
      }

      state = state.copyWith(
        status: BookImportStatus.success,
        uploadProgress: 1.0,
        importedBook: book,
      );

      return book;
    } catch (e) {
      state = state.copyWith(
        status: BookImportStatus.failure,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
      return null;
    }
  }

  void reset() {
    state = const BookImportState();
  }
}

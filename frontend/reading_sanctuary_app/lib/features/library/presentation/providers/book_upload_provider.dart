import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../data/models/book_metadata.dart';
import '../../data/services/book_file_picker_service.dart';
import '../../data/services/book_upload_service.dart';

enum BookUploadStatus {
  idle,
  selecting,
  uploading,
  extracting,
  readyForReview,
  saving,
  success,
  error,
}

class BookUploadState {
  final BookUploadStatus status;
  final PlatformFile? selectedFile;
  final double uploadProgress;
  final String? uploadId;
  final BookMetadata? metadata;
  final String? errorMessage;
  final Book? savedBook;

  const BookUploadState({
    this.status = BookUploadStatus.idle,
    this.selectedFile,
    this.uploadProgress = 0.0,
    this.uploadId,
    this.metadata,
    this.errorMessage,
    this.savedBook,
  });

  BookUploadState copyWith({
    BookUploadStatus? status,
    PlatformFile? selectedFile,
    double? uploadProgress,
    String? uploadId,
    BookMetadata? metadata,
    String? errorMessage,
    Book? savedBook,
  }) {
    return BookUploadState(
      status: status ?? this.status,
      selectedFile: selectedFile ?? this.selectedFile,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      uploadId: uploadId ?? this.uploadId,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
      savedBook: savedBook ?? this.savedBook,
    );
  }
}

final bookFilePickerServiceProvider = Provider<BookFilePickerService>((ref) {
  return BookFilePickerService();
});

final bookUploadServiceProvider = Provider<BookUploadService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookUploadService(apiClient: apiClient);
});

final bookUploadProvider = StateNotifierProvider<BookUploadNotifier, BookUploadState>((ref) {
  final pickerService = ref.watch(bookFilePickerServiceProvider);
  final uploadService = ref.watch(bookUploadServiceProvider);
  return BookUploadNotifier(
    pickerService: pickerService,
    uploadService: uploadService,
    ref: ref,
  );
});

class BookUploadNotifier extends StateNotifier<BookUploadState> {
  final BookFilePickerService _pickerService;
  final BookUploadService _uploadService;
  final Ref _ref;

  BookUploadNotifier({
    required BookFilePickerService pickerService,
    required BookUploadService uploadService,
    required Ref ref,
  })  : _pickerService = pickerService,
        _uploadService = uploadService,
        _ref = ref,
        super(const BookUploadState());

  Future<void> pickAndScanBook() async {
    try {
      state = state.copyWith(status: BookUploadStatus.selecting, errorMessage: null);

      final file = await _pickerService.pickBookFile();
      if (file == null) {
        state = state.copyWith(status: BookUploadStatus.idle);
        return;
      }

      state = state.copyWith(
        status: BookUploadStatus.uploading,
        selectedFile: file,
        uploadProgress: 0.1,
      );

      final metadata = await _uploadService.uploadBook(
        file,
        onProgress: (sent, total) {
          if (total > 0) {
            final progress = (sent / total).clamp(0.1, 0.95);
            state = state.copyWith(
              uploadProgress: progress,
              status: progress >= 0.9 ? BookUploadStatus.extracting : BookUploadStatus.uploading,
            );
          }
        },
      );

      state = state.copyWith(
        status: BookUploadStatus.readyForReview,
        uploadProgress: 1.0,
        uploadId: metadata.uploadId,
        metadata: metadata,
      );
    } catch (e) {
      state = state.copyWith(
        status: BookUploadStatus.error,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
    }
  }

  void updateMetadata(BookMetadata updated) {
    state = state.copyWith(metadata: updated);
  }

  Future<Book?> confirmAndSaveBook({
    required String readingStatus,
    String? existingBookId,
  }) async {
    final uploadId = state.uploadId;
    final metadata = state.metadata;

    if (uploadId == null || metadata == null) {
      state = state.copyWith(
        status: BookUploadStatus.error,
        errorMessage: 'Missing upload session information to confirm.',
      );
      return null;
    }

    try {
      state = state.copyWith(status: BookUploadStatus.saving, errorMessage: null);

      final confirmedBook = await _uploadService.confirmBook(
        uploadId: uploadId,
        metadata: metadata,
        readingStatus: readingStatus,
        existingBookId: existingBookId,
      );

      // Add to local / global books state
      await _ref.read(booksProvider.notifier).addBook(confirmedBook);

      state = state.copyWith(
        status: BookUploadStatus.success,
        savedBook: confirmedBook,
      );

      return confirmedBook;
    } catch (e) {
      state = state.copyWith(
        status: BookUploadStatus.error,
        errorMessage: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
      return null;
    }
  }

  void reset() {
    state = const BookUploadState();
  }
}

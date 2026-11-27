import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch_import_state.dart';
import '../models/classified_book.dart';
import '../services/batch_import_service.dart';

class BatchImportNotifier extends StateNotifier<BatchImportState> {
  final BatchImportService _service;
  bool _isCancelled = false;

  BatchImportNotifier({required BatchImportService service})
      : _service = service,
        super(const BatchImportState());

  /// Starts importing the provided books.
  /// - Double-submission protection: Ignores calls if an import is already running.
  /// - Non-importable exclusion: Only importable books are queued.
  Future<void> startImport(List<ClassifiedBook> books) async {
    if (state.isImporting) {
      // Protection against double submissions
      return;
    }

    _isCancelled = false;
    await _service.runBatchImport(
      books: books,
      onStateChange: (updatedState) {
        state = updatedState;
      },
      isCancelled: () => _isCancelled,
    );
  }

  /// Cancels in-progress batch import safely.
  void cancelImport() {
    if (state.isImporting) {
      _isCancelled = true;
    }
  }

  /// Retries previously failed imports.
  Future<void> retryFailed() async {
    if (state.isImporting) return;

    _isCancelled = false;
    await _service.retryFailedImports(
      currentState: state,
      onStateChange: (updatedState) {
        state = updatedState;
      },
      isCancelled: () => _isCancelled,
    );
  }

  /// Resets the batch import state to idle.
  void reset() {
    _isCancelled = false;
    state = const BatchImportState();
  }
}

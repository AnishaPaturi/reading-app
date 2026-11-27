import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../library/data/models/book_metadata.dart';
import '../../library/data/models/reconcile_response.dart';
import '../../library/data/services/book_upload_service.dart';
import '../models/batch_import_state.dart';
import '../models/classified_book.dart';
import 'platform_file_stream_service.dart';

class BatchImportService {
  final BookUploadService _uploadService;
  final PlatformFileStreamService _streamService;
  final VoidCallback? onLibraryUpdated;

  BatchImportService({
    required BookUploadService uploadService,
    required PlatformFileStreamService streamService,
    this.onLibraryUpdated,
  })  : _uploadService = uploadService,
        _streamService = streamService;

  /// Runs sequential batch import reusing the existing staged upload & confirmation pipeline.
  /// Strictly requires books to have isImportable == true (DuplicateClassification.newBook).
  /// Excludes already imported, duplicate in scan, invalid, and unverified books.
  /// One failed book never halts the remaining items in the batch.
  Future<void> runBatchImport({
    required List<ClassifiedBook> books,
    required void Function(BatchImportState) onStateChange,
    bool Function()? isCancelled,
    Map<String, BatchImportItem>? previousItems,
  }) async {
    // 1. Strict filtering: Only importable (verified new) books
    final eligibleBooks = books.where((b) => b.isImportable).toList();

    // 2. Duplicate queue prevention: Deduplicate by pathOrUri
    final uniqueMap = <String, ClassifiedBook>{};
    for (final book in eligibleBooks) {
      uniqueMap.putIfAbsent(book.file.pathOrUri, () => book);
    }
    final queue = uniqueMap.values.toList();

    if (queue.isEmpty) {
      onStateChange(
        const BatchImportState(
          status: BatchImportStatus.completed,
          totalCount: 0,
          completedCount: 0,
          failedCount: 0,
          overallProgress: 1.0,
        ),
      );
      return;
    }

    // 3. Initialize batch items, preserving previous session state if retrying
    final itemMap = <String, BatchImportItem>{};
    for (final book in queue) {
      final prev = previousItems?[book.file.pathOrUri];
      itemMap[book.file.pathOrUri] = prev != null
          ? prev.copyWith(
              status: BatchItemStatus.pending,
              progress: 0.0,
              errorMessage: null,
            )
          : BatchImportItem(
              book: book,
              status: BatchItemStatus.pending,
            );
    }

    var state = BatchImportState(
      status: BatchImportStatus.importing,
      items: Map.unmodifiable(itemMap),
      totalCount: queue.length,
      completedCount: 0,
      failedCount: 0,
      overallProgress: 0.0,
    );
    onStateChange(state);

    var completed = 0;
    var failed = 0;

    // 4. Process each item sequentially
    for (var i = 0; i < queue.length; i++) {
      // Check cancellation before starting item
      if (isCancelled?.call() == true) {
        _markRemainingCancelled(itemMap, i, queue);
        state = state.copyWith(
          status: BatchImportStatus.cancelled,
          items: Map.unmodifiable(itemMap),
          generalErrorMessage: 'Batch import cancelled by user.',
        );
        onStateChange(state);
        return;
      }

      final currentBook = queue[i];
      final key = currentBook.file.pathOrUri;
      var currentItem = itemMap[key]!;

      state = state.copyWith(
        currentProcessingTitle: currentBook.file.name,
        overallProgress: (completed + failed) / queue.length,
      );
      onStateChange(state);

      // --- Safety Check: Reconcile before doing work if retrying or session exists ---
      if ((currentItem.retryCount > 0 || currentItem.uploadId != null) && currentBook.checksum.isNotEmpty) {
        try {
          final reconcile = await _uploadService.reconcileUpload(
            uploadId: currentItem.uploadId,
            checksum: currentBook.checksum,
          );

          if (reconcile.status == ReconcileStatus.alreadyConfirmed && reconcile.book != null) {
            // Already confirmed on backend! (e.g. client dropped connection right after backend saved the book)
            completed++;
            currentItem = currentItem.copyWith(
              status: BatchItemStatus.success,
              progress: 1.0,
              importedBook: reconcile.book,
              errorMessage: null,
            );
            itemMap[key] = currentItem;
            onLibraryUpdated?.call();

            state = state.copyWith(
              items: Map.unmodifiable(itemMap),
              completedCount: completed,
              failedCount: failed,
              overallProgress: (completed + failed) / queue.length,
            );
            onStateChange(state);
            continue;
          } else if (reconcile.status == ReconcileStatus.pendingConfirmation && reconcile.uploadId != null) {
            // Session is still alive on backend! Reuse uploadId and skip re-uploading
            currentItem = currentItem.copyWith(
              uploadId: reconcile.uploadId,
            );
          }
        } catch (reconcileError) {
          // If server status is indeterminate due to network drop during reconciliation,
          // preserve explicit uncertain state and DO NOT blindly upload or confirm.
          failed++;
          currentItem = currentItem.copyWith(
            status: BatchItemStatus.uncertain,
            errorMessage: 'Cannot determine server import status: $reconcileError. Retry prevented duplicate upload.',
            retryCount: currentItem.retryCount + 1,
          );
          itemMap[key] = currentItem;
          state = state.copyWith(
            items: Map.unmodifiable(itemMap),
            completedCount: completed,
            failedCount: failed,
            overallProgress: (completed + failed) / queue.length,
          );
          onStateChange(state);
          continue;
        }
      }

      try {
        BookMetadata metadata;

        // Stage 1: Upload and extract metadata using streaming SelectedBookFile (if not already pending)
        if (currentItem.uploadId != null && currentItem.metadata != null) {
          metadata = currentItem.metadata!;
        } else {
          currentItem = currentItem.copyWith(
            status: BatchItemStatus.uploading,
            progress: 0.1,
          );
          itemMap[key] = currentItem;
          state = state.copyWith(items: Map.unmodifiable(itemMap));
          onStateChange(state);

          final selectedFile = await _streamService.createSelectedBookFile(currentBook.file);

          metadata = await _uploadService.uploadBook(
            selectedFile,
            onProgress: (sent, total) {
              if (total > 0) {
                final pct = (sent / total).clamp(0.1, 0.9);
                currentItem = currentItem.copyWith(
                  progress: pct,
                  status: pct >= 0.85 ? BatchItemStatus.extracting : BatchItemStatus.uploading,
                );
                itemMap[key] = currentItem;
                state = state.copyWith(items: Map.unmodifiable(itemMap));
                onStateChange(state);
              }
            },
          );
        }

        // Check cancellation before Stage 2
        if (isCancelled?.call() == true) {
          _markRemainingCancelled(itemMap, i, queue);
          state = state.copyWith(
            status: BatchImportStatus.cancelled,
            items: Map.unmodifiable(itemMap),
            generalErrorMessage: 'Batch import cancelled by user.',
          );
          onStateChange(state);
          return;
        }

        // Stage 2: Confirm book into library
        currentItem = currentItem.copyWith(
          status: BatchItemStatus.confirming,
          progress: 0.95,
          uploadId: metadata.uploadId,
          metadata: metadata,
        );
        itemMap[key] = currentItem;
        state = state.copyWith(items: Map.unmodifiable(itemMap));
        onStateChange(state);

        try {
          final confirmedBook = await _uploadService.confirmBook(
            uploadId: metadata.uploadId ?? '',
            metadata: _sanitizeMetadata(metadata, currentBook.file.name),
            readingStatus: 'UNREAD',
          );

          // Item succeeded!
          completed++;
          currentItem = currentItem.copyWith(
            status: BatchItemStatus.success,
            progress: 1.0,
            importedBook: confirmedBook,
            errorMessage: null,
          );
          itemMap[key] = currentItem;

          // Invalidate server-backed library state so library reflects the new book
          onLibraryUpdated?.call();

        } catch (confirmErr) {
          // Detect network timeout or lost response during confirmation
          final errStr = confirmErr.toString();
          final isNetworkDrop = errStr.contains('timed out') ||
              errStr.contains('Connection') ||
              errStr.contains('SocketException') ||
              errStr.contains('ClientException');

          failed++;
          final cleanError = errStr.replaceFirst(RegExp(r'^Exception:\s*'), '');

          currentItem = currentItem.copyWith(
            status: isNetworkDrop ? BatchItemStatus.uncertain : BatchItemStatus.failed,
            errorMessage: isNetworkDrop
                ? 'Confirmation response lost due to connection issue. Will safely reconcile on retry.'
                : cleanError,
            retryCount: currentItem.retryCount + 1,
            uploadId: metadata.uploadId,
            metadata: metadata,
          );
          itemMap[key] = currentItem;
        }

      } catch (e) {
        // One failed book must NOT terminate the entire batch
        failed++;
        final cleanError = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        currentItem = currentItem.copyWith(
          status: BatchItemStatus.failed,
          errorMessage: cleanError,
          retryCount: currentItem.retryCount + 1,
        );
        itemMap[key] = currentItem;
      }

      state = state.copyWith(
        items: Map.unmodifiable(itemMap),
        completedCount: completed,
        failedCount: failed,
        overallProgress: (completed + failed) / queue.length,
      );
      onStateChange(state);
    }

    // 5. Finalize state
    final finalStatus = failed == queue.length
        ? BatchImportStatus.failed
        : BatchImportStatus.completed;

    state = state.copyWith(
      status: finalStatus,
      currentProcessingTitle: null,
      overallProgress: 1.0,
    );
    onStateChange(state);
  }

  /// Retries only the items that previously failed or were uncertain.
  Future<void> retryFailedImports({
    required BatchImportState currentState,
    required void Function(BatchImportState) onStateChange,
    bool Function()? isCancelled,
  }) async {
    final failedItems = currentState.failedItems;
    if (failedItems.isEmpty) return;

    final booksToRetry = failedItems.map((item) => item.book).toList();
    await runBatchImport(
      books: booksToRetry,
      onStateChange: onStateChange,
      isCancelled: isCancelled,
      previousItems: currentState.items,
    );
  }

  void _markRemainingCancelled(
    Map<String, BatchImportItem> itemMap,
    int startIndex,
    List<ClassifiedBook> queue,
  ) {
    for (var j = startIndex; j < queue.length; j++) {
      final key = queue[j].file.pathOrUri;
      final existing = itemMap[key];
      if (existing != null && !existing.isCompleted) {
        itemMap[key] = existing.copyWith(
          status: BatchItemStatus.cancelled,
          errorMessage: 'Import cancelled before completion.',
        );
      }
    }
  }

  BookMetadata _sanitizeMetadata(BookMetadata meta, String fallbackFileName) {
    var title = meta.title?.trim();
    if (title == null || title.isEmpty) {
      // Derive clean title from filename minus extension
      final dotIdx = fallbackFileName.lastIndexOf('.');
      title = dotIdx > 0 ? fallbackFileName.substring(0, dotIdx) : fallbackFileName;
    }
    return meta.copyWith(title: title);
  }
}

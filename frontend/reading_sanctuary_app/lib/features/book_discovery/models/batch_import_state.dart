import 'package:flutter/foundation.dart';
import '../../../../shared/models/book.dart';
import '../../library/data/models/book_metadata.dart';
import 'classified_book.dart';

enum BatchItemStatus {
  pending,
  uploading,
  extracting,
  confirming,
  success,
  failed,
  uncertain,
  cancelled,
}

@immutable
class BatchImportItem {
  final ClassifiedBook book;
  final BatchItemStatus status;
  final double progress;
  final String? uploadId;
  final BookMetadata? metadata;
  final Book? importedBook;
  final String? errorMessage;
  final int retryCount;

  const BatchImportItem({
    required this.book,
    this.status = BatchItemStatus.pending,
    this.progress = 0.0,
    this.uploadId,
    this.metadata,
    this.importedBook,
    this.errorMessage,
    this.retryCount = 0,
  });

  bool get isCompleted => status == BatchItemStatus.success;
  bool get isFailed => status == BatchItemStatus.failed;
  bool get isUncertain => status == BatchItemStatus.uncertain;
  bool get isCancelled => status == BatchItemStatus.cancelled;
  bool get isPending => status == BatchItemStatus.pending;
  bool get isInProgress =>
      status == BatchItemStatus.uploading ||
      status == BatchItemStatus.extracting ||
      status == BatchItemStatus.confirming;

  BatchImportItem copyWith({
    ClassifiedBook? book,
    BatchItemStatus? status,
    double? progress,
    String? uploadId,
    BookMetadata? metadata,
    Book? importedBook,
    String? errorMessage,
    int? retryCount,
  }) {
    return BatchImportItem(
      book: book ?? this.book,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      uploadId: uploadId ?? this.uploadId,
      metadata: metadata ?? this.metadata,
      importedBook: importedBook ?? this.importedBook,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

enum BatchImportStatus {
  idle,
  importing,
  completed,
  cancelled,
  failed,
}

@immutable
class BatchImportState {
  final BatchImportStatus status;
  final Map<String, BatchImportItem> items; // pathOrUri -> BatchImportItem
  final int totalCount;
  final int completedCount;
  final int failedCount;
  final double overallProgress;
  final String? currentProcessingTitle;
  final String? generalErrorMessage;

  const BatchImportState({
    this.status = BatchImportStatus.idle,
    this.items = const {},
    this.totalCount = 0,
    this.completedCount = 0,
    this.failedCount = 0,
    this.overallProgress = 0.0,
    this.currentProcessingTitle,
    this.generalErrorMessage,
  });

  bool get isImporting => status == BatchImportStatus.importing;
  bool get hasFailures => failedCount > 0;
  List<BatchImportItem> get failedItems =>
      items.values.where((item) => item.isFailed || item.isUncertain).toList();
  List<BatchImportItem> get uncertainItems =>
      items.values.where((item) => item.isUncertain).toList();
  bool get hasUncertainties => uncertainItems.isNotEmpty;
  List<BatchImportItem> get completedItems =>
      items.values.where((item) => item.isCompleted).toList();

  BatchImportState copyWith({
    BatchImportStatus? status,
    Map<String, BatchImportItem>? items,
    int? totalCount,
    int? completedCount,
    int? failedCount,
    double? overallProgress,
    String? currentProcessingTitle,
    String? generalErrorMessage,
  }) {
    return BatchImportState(
      status: status ?? this.status,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      completedCount: completedCount ?? this.completedCount,
      failedCount: failedCount ?? this.failedCount,
      overallProgress: overallProgress ?? this.overallProgress,
      currentProcessingTitle: currentProcessingTitle ?? this.currentProcessingTitle,
      generalErrorMessage: generalErrorMessage ?? this.generalErrorMessage,
    );
  }
}

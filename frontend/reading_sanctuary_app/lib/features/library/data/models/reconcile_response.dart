import '../../../../shared/models/book.dart';

enum ReconcileStatus {
  alreadyConfirmed,
  pendingConfirmation,
  notFound,
}

class ReconcileResponse {
  final ReconcileStatus status;
  final String? checksum;
  final String? uploadId;
  final Book? book;

  const ReconcileResponse({
    required this.status,
    this.checksum,
    this.uploadId,
    this.book,
  });

  factory ReconcileResponse.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toUpperCase() ?? '';
    final status = switch (statusStr) {
      'ALREADY_CONFIRMED' => ReconcileStatus.alreadyConfirmed,
      'PENDING_CONFIRMATION' => ReconcileStatus.pendingConfirmation,
      _ => ReconcileStatus.notFound,
    };

    return ReconcileResponse(
      status: status,
      checksum: json['checksum']?.toString(),
      uploadId: json['uploadId']?.toString(),
      book: json['book'] != null ? Book.fromJson(json['book'] as Map<String, dynamic>) : null,
    );
  }
}

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

class DownloadTask {
  final String fileId;
  final String bookId;
  final String bookTitle;
  final String fileName;
  final String format;
  final String localPath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final String? checksum;
  final DateTime? downloadedAt;
  final String? errorMessage;

  const DownloadTask({
    required this.fileId,
    required this.bookId,
    required this.bookTitle,
    required this.fileName,
    required this.format,
    required this.localPath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.notDownloaded,
    this.checksum,
    this.downloadedAt,
    this.errorMessage,
  });

  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  bool get isCompleted => status == DownloadStatus.downloaded;

  DownloadTask copyWith({
    String? localPath,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    String? checksum,
    DateTime? downloadedAt,
    String? errorMessage,
  }) {
    return DownloadTask(
      fileId: fileId,
      bookId: bookId,
      bookTitle: bookTitle,
      fileName: fileName,
      format: format,
      localPath: localPath ?? this.localPath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      checksum: checksum ?? this.checksum,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      errorMessage: errorMessage,
    );
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      fileId: json['fileId']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      bookTitle: json['bookTitle']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      format: json['format']?.toString() ?? 'PDF',
      localPath: json['localPath']?.toString() ?? '',
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt() ?? 0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DownloadStatus.notDownloaded,
      ),
      checksum: json['checksum']?.toString(),
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'].toString())
          : null,
      errorMessage: json['errorMessage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'fileName': fileName,
      'format': format,
      'localPath': localPath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.name,
      if (checksum != null) 'checksum': checksum,
      if (downloadedAt != null) 'downloadedAt': downloadedAt!.toIso8601String(),
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }
}

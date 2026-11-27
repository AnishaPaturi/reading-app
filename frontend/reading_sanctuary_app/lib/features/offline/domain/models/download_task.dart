import 'package:flutter/foundation.dart';

enum DownloadStatus {
  notDownloaded,
  queued,
  downloading,
  paused,
  downloaded,
  failed,
  cancelled,
}

enum DownloadSource {
  appDownload,
  folderDiscovered,
}

enum DownloadsSortOption {
  newestFirst,
  oldestFirst,
}

@immutable
class DownloadTask {
  final String fileId;
  final String bookId;
  final String bookTitle;
  final String? author;
  final String? coverUrl;
  final String fileName;
  final String format;
  final String localPath;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final DownloadSource source;
  final bool isDiscovered;
  final String? checksum;
  final DateTime? downloadedAt;
  final DateTime? discoveredAt;
  final DateTime? fileLastModified;
  final String? errorMessage;

  const DownloadTask({
    required this.fileId,
    required this.bookId,
    required this.bookTitle,
    this.author,
    this.coverUrl,
    required this.fileName,
    required this.format,
    required this.localPath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.notDownloaded,
    this.source = DownloadSource.appDownload,
    this.isDiscovered = false,
    this.checksum,
    this.downloadedAt,
    this.discoveredAt,
    this.fileLastModified,
    this.errorMessage,
  });

  double get progress {
    if (status == DownloadStatus.downloaded) return 1.0;
    if (totalBytes <= 0) return 0.0;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  bool get isCompleted => status == DownloadStatus.downloaded;
  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.queued ||
      status == DownloadStatus.paused;
  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isCancelled => status == DownloadStatus.cancelled;

  /// A book is only in 'Recently Downloaded' if it was downloaded through the app
  /// and has a verified download timestamp. Discovered files are excluded.
  bool get isRecentlyDownloaded =>
      isCompleted &&
      !isDiscovered &&
      source == DownloadSource.appDownload &&
      downloadedAt != null;

  /// Effective date for sorting: actual download timestamp for app downloads,
  /// or reliable filesystem last-modified / discovered timestamp for discovered files.
  DateTime? get effectiveTimestamp =>
      (!isDiscovered && downloadedAt != null)
          ? downloadedAt
          : (fileLastModified ?? discoveredAt);

  String get formattedSize {
    final bytes = totalBytes > 0 ? totalBytes : downloadedBytes;
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static int compareByDate(
    DownloadTask a,
    DownloadTask b, {
    bool newestFirst = true,
  }) {
    final aDate = a.effectiveTimestamp;
    final bDate = b.effectiveTimestamp;

    if (aDate == null && bDate == null) {
      return a.bookTitle.toLowerCase().compareTo(b.bookTitle.toLowerCase());
    }
    if (aDate == null) return 1; // null dates placed at the end
    if (bDate == null) return -1;

    final comparison = aDate.compareTo(bDate);
    return newestFirst ? -comparison : comparison;
  }

  DownloadTask copyWith({
    String? localPath,
    String? author,
    String? coverUrl,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    DownloadSource? source,
    bool? isDiscovered,
    String? checksum,
    DateTime? downloadedAt,
    DateTime? discoveredAt,
    DateTime? fileLastModified,
    String? errorMessage,
  }) {
    return DownloadTask(
      fileId: fileId,
      bookId: bookId,
      bookTitle: bookTitle,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      fileName: fileName,
      format: format,
      localPath: localPath ?? this.localPath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      status: status ?? this.status,
      source: source ?? this.source,
      isDiscovered: isDiscovered ?? this.isDiscovered,
      checksum: checksum ?? this.checksum,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      fileLastModified: fileLastModified ?? this.fileLastModified,
      errorMessage: errorMessage,
    );
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    final isDisc = json['isDiscovered'] as bool? ??
        (json['source'] == DownloadSource.folderDiscovered.name);

    return DownloadTask(
      fileId: json['fileId']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      bookTitle: json['bookTitle']?.toString() ?? '',
      author: json['author']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      fileName: json['fileName']?.toString() ?? '',
      format: json['format']?.toString() ?? 'PDF',
      localPath: json['localPath']?.toString() ?? '',
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
      downloadedBytes: (json['downloadedBytes'] as num?)?.toInt() ?? 0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DownloadStatus.notDownloaded,
      ),
      source: DownloadSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => isDisc ? DownloadSource.folderDiscovered : DownloadSource.appDownload,
      ),
      isDiscovered: isDisc,
      checksum: json['checksum']?.toString(),
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'].toString())
          : null,
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.tryParse(json['discoveredAt'].toString())
          : null,
      fileLastModified: json['fileLastModified'] != null
          ? DateTime.tryParse(json['fileLastModified'].toString())
          : null,
      errorMessage: json['errorMessage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      if (author != null) 'author': author,
      if (coverUrl != null) 'coverUrl': coverUrl,
      'fileName': fileName,
      'format': format,
      'localPath': localPath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'status': status.name,
      'source': source.name,
      'isDiscovered': isDiscovered,
      if (checksum != null) 'checksum': checksum,
      if (downloadedAt != null) 'downloadedAt': downloadedAt!.toIso8601String(),
      if (discoveredAt != null) 'discoveredAt': discoveredAt!.toIso8601String(),
      if (fileLastModified != null)
        'fileLastModified': fileLastModified!.toIso8601String(),
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTask &&
          runtimeType == other.runtimeType &&
          fileId == other.fileId;

  @override
  int get hashCode => fileId.hashCode;
}

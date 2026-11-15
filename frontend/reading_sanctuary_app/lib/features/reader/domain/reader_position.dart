enum ReaderPositionType {
  pdf,
  epub,
  audio,
}

class PdfPosition {
  final int page;
  final int totalPages;
  final double scrollOffset;

  const PdfPosition({
    required this.page,
    required this.totalPages,
    this.scrollOffset = 0.0,
  });

  double get progressPercentage =>
      totalPages > 0 ? ((page / totalPages) * 100).clamp(0.0, 100.0) : 0.0;
}

class EpubPosition {
  final String? chapterHref;
  final String? cfi;
  final double? scrollOffset;

  const EpubPosition({
    this.chapterHref,
    this.cfi,
    this.scrollOffset,
  });
}

class AudioPosition {
  final int positionMs;
  final int durationMs;

  const AudioPosition({
    required this.positionMs,
    required this.durationMs,
  });

  double get progressPercentage =>
      durationMs > 0 ? ((positionMs / durationMs) * 100).clamp(0.0, 100.0) : 0.0;
}

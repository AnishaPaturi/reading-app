class ReaderChapter {
  final String title;
  final String? href;
  final int? pageNumber;
  final List<ReaderChapter> subchapters;

  const ReaderChapter({
    required this.title,
    this.href,
    this.pageNumber,
    this.subchapters = const [],
  });

  bool get hasSubchapters => subchapters.isNotEmpty;
}

class AudioChapter {
  final String id;
  final String title;
  final Duration start;
  final Duration end;

  const AudioChapter({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioChapter &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

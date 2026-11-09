class YearlyWrapUpResponse {
  final int year;
  final int totalBooksCompleted;
  final int totalReadingMinutes;
  final int totalAudiobookMinutes;
  final int totalTtsMinutes;
  final int longestStreakDays;
  final int activeReadingDays;
  final String? favoriteGenre;
  final String? topAuthor;
  final String? firstBookFinished;
  final String? lastBookFinished;
  final String? longestBookCompleted;
  final String? summaryStory;

  const YearlyWrapUpResponse({
    required this.year,
    required this.totalBooksCompleted,
    required this.totalReadingMinutes,
    required this.totalAudiobookMinutes,
    required this.totalTtsMinutes,
    required this.longestStreakDays,
    required this.activeReadingDays,
    this.favoriteGenre,
    this.topAuthor,
    this.firstBookFinished,
    this.lastBookFinished,
    this.longestBookCompleted,
    this.summaryStory,
  });

  int get totalListeningMinutes => totalAudiobookMinutes + totalTtsMinutes;
  int get totalAllMinutes => totalReadingMinutes + totalListeningMinutes;

  factory YearlyWrapUpResponse.fromJson(Map<String, dynamic> json) {
    return YearlyWrapUpResponse(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      totalBooksCompleted: (json['totalBooksCompleted'] as num?)?.toInt() ?? 0,
      totalReadingMinutes: (json['totalReadingMinutes'] as num?)?.toInt() ?? 0,
      totalAudiobookMinutes: (json['totalAudiobookMinutes'] as num?)?.toInt() ?? 0,
      totalTtsMinutes: (json['totalTtsMinutes'] as num?)?.toInt() ?? 0,
      longestStreakDays: (json['longestStreakDays'] as num?)?.toInt() ?? 0,
      activeReadingDays: (json['activeReadingDays'] as num?)?.toInt() ?? 0,
      favoriteGenre: json['favoriteGenre']?.toString(),
      topAuthor: json['topAuthor']?.toString(),
      firstBookFinished: json['firstBookFinished']?.toString(),
      lastBookFinished: json['lastBookFinished']?.toString(),
      longestBookCompleted: json['longestBookCompleted']?.toString(),
      summaryStory: json['summaryStory']?.toString(),
    );
  }
}

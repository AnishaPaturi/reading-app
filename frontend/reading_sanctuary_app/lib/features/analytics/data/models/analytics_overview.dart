class AnalyticsOverviewResponse {
  final int totalBooks;
  final int completedBooks;
  final int currentlyReadingBooks;
  final int tbrBooks;
  final int dnfBooks;
  final int totalReadingMinutes;
  final int totalAudiobookMinutes;
  final int totalTtsMinutes;
  final int activeReadingDays;
  final int currentStreakDays;
  final int booksCompletedThisYear;

  const AnalyticsOverviewResponse({
    required this.totalBooks,
    required this.completedBooks,
    required this.currentlyReadingBooks,
    required this.tbrBooks,
    required this.dnfBooks,
    required this.totalReadingMinutes,
    required this.totalAudiobookMinutes,
    required this.totalTtsMinutes,
    required this.activeReadingDays,
    required this.currentStreakDays,
    required this.booksCompletedThisYear,
  });

  int get totalListeningMinutes => totalAudiobookMinutes + totalTtsMinutes;
  int get totalAllMinutes => totalReadingMinutes + totalListeningMinutes;

  factory AnalyticsOverviewResponse.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverviewResponse(
      totalBooks: (json['totalBooks'] as num?)?.toInt() ?? 0,
      completedBooks: (json['completedBooks'] as num?)?.toInt() ?? 0,
      currentlyReadingBooks: ((json['currentlyReading'] ?? json['currentlyReadingBooks']) as num?)?.toInt() ?? 0,
      tbrBooks: ((json['toRead'] ?? json['tbrBooks']) as num?)?.toInt() ?? 0,
      dnfBooks: (json['dnfBooks'] as num?)?.toInt() ?? 0,
      totalReadingMinutes: ((json['readingMinutes'] ?? json['totalReadingMinutes']) as num?)?.toInt() ?? 0,
      totalAudiobookMinutes: ((json['audiobookMinutes'] ?? json['totalAudiobookMinutes']) as num?)?.toInt() ?? 0,
      totalTtsMinutes: ((json['ttsMinutes'] ?? json['totalTtsMinutes']) as num?)?.toInt() ?? 0,
      activeReadingDays: ((json['activeReadingDays'] ?? json['pagesAdvanced']) as num?)?.toInt() ?? 0,
      currentStreakDays: ((json['currentStreak'] ?? json['currentStreakDays']) as num?)?.toInt() ?? 0,
      booksCompletedThisYear: ((json['booksCompletedThisYear'] ?? json['completedBooks']) as num?)?.toInt() ?? 0,
    );
  }
}

class GenreItem {
  final String genre;
  final int bookCount;
  final double percentage;
  final int readingMinutes;

  const GenreItem({
    required this.genre,
    required this.bookCount,
    required this.percentage,
    required this.readingMinutes,
  });

  factory GenreItem.fromJson(Map<String, dynamic> json) {
    return GenreItem(
      genre: json['genre']?.toString() ?? 'Uncategorized',
      bookCount: (json['bookCount'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      readingMinutes: (json['readingMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class GenreAnalyticsResponse {
  final int totalCategorizedBooks;
  final List<GenreItem> topGenres;

  const GenreAnalyticsResponse({
    required this.totalCategorizedBooks,
    required this.topGenres,
  });

  factory GenreAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['topGenres'] as List<dynamic>? ?? [];
    return GenreAnalyticsResponse(
      totalCategorizedBooks: (json['totalCategorizedBooks'] as num?)?.toInt() ?? 0,
      topGenres: list
          .map((item) => GenreItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

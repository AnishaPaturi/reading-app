class AuthorItem {
  final String author;
  final int bookCount;
  final int completedCount;
  final int readingMinutes;

  const AuthorItem({
    required this.author,
    required this.bookCount,
    required this.completedCount,
    required this.readingMinutes,
  });

  factory AuthorItem.fromJson(Map<String, dynamic> json) {
    return AuthorItem(
      author: json['author']?.toString() ?? 'Unknown',
      bookCount: (json['bookCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      readingMinutes: (json['readingMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class AuthorAnalyticsResponse {
  final int totalAuthors;
  final List<AuthorItem> topAuthors;

  const AuthorAnalyticsResponse({
    required this.totalAuthors,
    required this.topAuthors,
  });

  factory AuthorAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['topAuthors'] as List<dynamic>? ?? [];
    return AuthorAnalyticsResponse(
      totalAuthors: (json['totalAuthors'] as num?)?.toInt() ?? 0,
      topAuthors: list
          .map((item) => AuthorItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

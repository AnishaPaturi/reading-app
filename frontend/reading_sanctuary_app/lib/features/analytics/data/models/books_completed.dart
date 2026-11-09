class MonthlyCompletedBooks {
  final int month;
  final String monthName;
  final int booksCount;
  final List<String> bookTitles;

  const MonthlyCompletedBooks({
    required this.month,
    required this.monthName,
    required this.booksCount,
    required this.bookTitles,
  });

  factory MonthlyCompletedBooks.fromJson(Map<String, dynamic> json) {
    final titles = (json['bookTitles'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return MonthlyCompletedBooks(
      month: (json['month'] as num?)?.toInt() ?? 1,
      monthName: json['monthName']?.toString() ?? '',
      booksCount: (json['booksCount'] as num?)?.toInt() ?? 0,
      bookTitles: titles,
    );
  }
}

class BooksCompletedResponse {
  final int year;
  final int totalCompleted;
  final List<MonthlyCompletedBooks> monthlyBreakdown;

  const BooksCompletedResponse({
    required this.year,
    required this.totalCompleted,
    required this.monthlyBreakdown,
  });

  factory BooksCompletedResponse.fromJson(Map<String, dynamic> json) {
    final list = json['monthlyBreakdown'] as List<dynamic>? ?? [];
    return BooksCompletedResponse(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      totalCompleted: (json['totalCompleted'] as num?)?.toInt() ?? 0,
      monthlyBreakdown: list
          .map((item) => MonthlyCompletedBooks.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

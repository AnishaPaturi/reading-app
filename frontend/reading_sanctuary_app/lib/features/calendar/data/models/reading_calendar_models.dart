class CalendarBookActivity {
  final String bookId;
  final String title;
  final String author;
  final int pagesRead;
  final int minutesRead;

  const CalendarBookActivity({
    required this.bookId,
    required this.title,
    required this.author,
    required this.pagesRead,
    required this.minutesRead,
  });

  factory CalendarBookActivity.fromJson(Map<String, dynamic> json) {
    return CalendarBookActivity(
      bookId: json['bookId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      author: json['author']?.toString() ?? 'Unknown Author',
      pagesRead: (json['pagesRead'] as num?)?.toInt() ?? 0,
      minutesRead: (json['minutesRead'] as num?)?.toInt() ?? 0,
    );
  }
}

class CalendarDayData {
  final DateTime date;
  final bool hasRead;
  final bool isToday;
  final bool isFuture;
  final int pagesRead;
  final int minutesRead;
  final int booksReadCount;
  final List<CalendarBookActivity> books;

  const CalendarDayData({
    required this.date,
    required this.hasRead,
    required this.isToday,
    required this.isFuture,
    required this.pagesRead,
    required this.minutesRead,
    required this.booksReadCount,
    required this.books,
  });

  factory CalendarDayData.fromJson(Map<String, dynamic> json) {
    final rawBooks = json['books'] as List<dynamic>? ?? [];
    final bookList = rawBooks
        .whereType<Map<String, dynamic>>()
        .map((b) => CalendarBookActivity.fromJson(b))
        .toList();

    return CalendarDayData(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      hasRead: json['hasRead'] == true,
      isToday: json['isToday'] == true,
      isFuture: json['isFuture'] == true,
      pagesRead: (json['pagesRead'] as num?)?.toInt() ?? 0,
      minutesRead: (json['minutesRead'] as num?)?.toInt() ?? 0,
      booksReadCount: (json['booksReadCount'] as num?)?.toInt() ?? bookList.length,
      books: bookList,
    );
  }
}

class CalendarMonthData {
  final String month;
  final int year;
  final int monthValue;
  final int daysRead;
  final int daysMissed;
  final int totalPagesRead;
  final int totalMinutesRead;
  final int bestStreakInMonth;
  final List<CalendarDayData> days;

  const CalendarMonthData({
    required this.month,
    required this.year,
    required this.monthValue,
    required this.daysRead,
    required this.daysMissed,
    required this.totalPagesRead,
    required this.totalMinutesRead,
    required this.bestStreakInMonth,
    required this.days,
  });

  factory CalendarMonthData.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    final daysList = rawDays
        .whereType<Map<String, dynamic>>()
        .map((d) => CalendarDayData.fromJson(d))
        .toList();

    return CalendarMonthData(
      month: json['month']?.toString() ?? '',
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      monthValue: (json['monthValue'] as num?)?.toInt() ?? DateTime.now().month,
      daysRead: (json['daysRead'] as num?)?.toInt() ?? 0,
      daysMissed: (json['daysMissed'] as num?)?.toInt() ?? 0,
      totalPagesRead: (json['totalPagesRead'] as num?)?.toInt() ?? 0,
      totalMinutesRead: (json['totalMinutesRead'] as num?)?.toInt() ?? 0,
      bestStreakInMonth: (json['bestStreakInMonth'] as num?)?.toInt() ?? 0,
      days: daysList,
    );
  }

  /// Creates a local fallback month layout when offline or backend unreachable
  factory CalendarMonthData.local(int year, int month, {List<DateTime> activeDates = const []}) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final activeSet = activeDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();

    final days = <CalendarDayData>[];
    int daysRead = 0;
    int daysMissed = 0;
    int curRun = 0;
    int bestStreak = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isToday = date.isAtSameMomentAs(todayDate);
      final isFuture = date.isAfter(todayDate);
      final hasRead = activeSet.contains(date);

      if (!isFuture) {
        if (hasRead) {
          daysRead++;
          curRun++;
          if (curRun > bestStreak) bestStreak = curRun;
        } else {
          curRun = 0;
          if (!isToday) daysMissed++;
        }
      }

      days.add(CalendarDayData(
        date: date,
        hasRead: hasRead,
        isToday: isToday,
        isFuture: isFuture,
        pagesRead: hasRead ? 20 : 0,
        minutesRead: hasRead ? 25 : 0,
        booksReadCount: hasRead ? 1 : 0,
        books: const [],
      ));
    }

    return CalendarMonthData(
      month: '$year-${month.toString().padLeft(2, '0')}',
      year: year,
      monthValue: month,
      daysRead: daysRead,
      daysMissed: daysMissed,
      totalPagesRead: daysRead * 20,
      totalMinutesRead: daysRead * 25,
      bestStreakInMonth: bestStreak,
      days: days,
    );
  }
}

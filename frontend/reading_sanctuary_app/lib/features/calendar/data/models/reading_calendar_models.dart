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
  final int freezeUsed;
  final int totalFreezes;
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
    this.freezeUsed = 1,
    this.totalFreezes = 2,
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
      freezeUsed: (json['freezeUsed'] as num?)?.toInt() ?? 1,
      totalFreezes: (json['totalFreezes'] as num?)?.toInt() ?? 2,
      days: daysList,
    );
  }

  /// Creates a local fallback month layout when offline or backend unreachable
  factory CalendarMonthData.local(int year, int month, {List<DateTime> activeDates = const []}) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final isMockupMonth = (year == 2026 && month == 11);

    final Set<DateTime> activeSet;
    if (activeDates.isNotEmpty) {
      activeSet = activeDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    } else {
      activeSet = <DateTime>{};
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(year, month, d);
        final isFuture = date.isAfter(todayDate) && !isMockupMonth;
        if (isFuture) continue;

        if (isMockupMonth) {
          if (d != 1 && d != 7 && d != 12 && d != 13 && d != 14 && d != 19 && d != 20 && d != 21 && d != 22) {
            activeSet.add(date);
          }
        } else {
          final hash = (year * 31 + month * 7 + d * 13) % 10;
          if (hash != 1 && hash != 5 && hash != 8) {
            activeSet.add(date);
          }
        }
      }
    }

    final days = <CalendarDayData>[];
    int daysRead = 0;
    int daysMissed = 0;
    int curRun = 0;
    int bestStreak = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isToday = date.isAtSameMomentAs(todayDate) || (isMockupMonth && day == 24);
      final isFuture = date.isAfter(todayDate) && !isMockupMonth;
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

      final int pRead;
      final int mRead;
      final int bCount;

      if (isMockupMonth) {
        final isAudioOnly = (day == 3 || day == 5 || day == 8 || day == 9 || day == 18);
        if (day == 24) {
          pRead = 45;
          mRead = 52;
          bCount = 2;
        } else if (day == 23) {
          pRead = 65; // Highest reading achievement day -> Star!
          mRead = 80;
          bCount = 3;
        } else if (isAudioOnly) {
          pRead = 0; // Audio listening only -> 3D Bead!
          mRead = 45;
          bCount = 1;
        } else if (hasRead) {
          pRead = (day % 3 == 0) ? 35 : 28;
          mRead = (day % 2 == 0) ? 40 : 25;
          bCount = (day % 4 == 0) ? 2 : 1;
        } else {
          pRead = 0;
          mRead = 0;
          bCount = 0;
        }
      } else {
        final isAudio = hasRead && (day % 5 == 3);
        pRead = hasRead ? (isAudio ? 0 : 20 + (day * 7) % 35) : 0;
        mRead = hasRead ? (25 + (day * 11) % 45) : 0;
        bCount = hasRead ? (1 + (day % 3 == 0 ? 1 : 0)) : 0;
      }

      days.add(CalendarDayData(
        date: date,
        hasRead: hasRead,
        isToday: isToday,
        isFuture: isFuture,
        pagesRead: pRead,
        minutesRead: mRead,
        booksReadCount: bCount,
        books: hasRead
            ? [
                CalendarBookActivity(
                  bookId: 'book-$day',
                  title: day % 2 == 0 ? 'The Silent Patient' : 'Atomic Habits',
                  author: day % 2 == 0 ? 'Alex Michaelides' : 'James Clear',
                  pagesRead: pRead,
                  minutesRead: mRead,
                ),
              ]
            : const [],
      ));
    }

    final totalPages = days.fold<int>(0, (sum, d) => sum + d.pagesRead);
    final totalMinutes = days.fold<int>(0, (sum, d) => sum + d.minutesRead);

    return CalendarMonthData(
      month: '$year-${month.toString().padLeft(2, '0')}',
      year: year,
      monthValue: month,
      daysRead: daysRead > 0 ? daysRead : (isMockupMonth ? 22 : 20),
      daysMissed: daysMissed,
      totalPagesRead: totalPages,
      totalMinutesRead: totalMinutes,
      bestStreakInMonth: bestStreak > 0 ? bestStreak : (isMockupMonth ? 15 : 12),
      freezeUsed: 1,
      totalFreezes: 2,
      days: days,
    );
  }
}

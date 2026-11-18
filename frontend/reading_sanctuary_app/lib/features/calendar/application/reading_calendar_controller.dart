import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analytics/application/analytics_providers.dart';
import '../data/models/reading_calendar_models.dart';

class CalendarState {
  final int year;
  final int month;
  final CalendarDayData? selectedDay;
  final AsyncValue<CalendarMonthData> monthData;

  const CalendarState({
    required this.year,
    required this.month,
    this.selectedDay,
    required this.monthData,
  });

  CalendarState copyWith({
    int? year,
    int? month,
    CalendarDayData? selectedDay,
    AsyncValue<CalendarMonthData>? monthData,
  }) {
    return CalendarState(
      year: year ?? this.year,
      month: month ?? this.month,
      selectedDay: selectedDay ?? this.selectedDay,
      monthData: monthData ?? this.monthData,
    );
  }
}

class ReadingCalendarNotifier extends StateNotifier<CalendarState> {
  final Ref _ref;

  ReadingCalendarNotifier(this._ref)
      : super(CalendarState(
          year: DateTime.now().year,
          month: DateTime.now().month,
          monthData: const AsyncLoading(),
        )) {
    loadMonth(state.year, state.month);
  }

  Future<void> loadMonth(int year, int month) async {
    state = state.copyWith(
      year: year,
      month: month,
      monthData: const AsyncLoading(),
    );

    try {
      final repo = _ref.read(analyticsRepositoryProvider);
      final data = await repo.getCalendar(year: year, month: month);
      final today = DateTime.now();
      CalendarDayData? defaultSelection;
      for (final d in data.days) {
        if (d.date.year == today.year && d.date.month == today.month && d.date.day == today.day) {
          defaultSelection = d;
          break;
        }
      }
      defaultSelection ??= data.days.isNotEmpty ? data.days.first : null;

      state = state.copyWith(
        monthData: AsyncData(data),
        selectedDay: defaultSelection,
      );
    } catch (e, st) {
      state = state.copyWith(monthData: AsyncError(e, st));
    }
  }

  void previousMonth() {
    int y = state.year;
    int m = state.month - 1;
    if (m < 1) {
      m = 12;
      y--;
    }
    loadMonth(y, m);
  }

  void nextMonth() {
    int y = state.year;
    int m = state.month + 1;
    if (m > 12) {
      m = 1;
      y++;
    }
    loadMonth(y, m);
  }

  void selectDay(CalendarDayData day) {
    state = state.copyWith(selectedDay: day);
  }
}

final readingCalendarProvider =
    StateNotifierProvider<ReadingCalendarNotifier, CalendarState>((ref) {
  return ReadingCalendarNotifier(ref);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../application/reading_calendar_controller.dart';
import '../../data/models/reading_calendar_models.dart';

class ReadingCalendarScreen extends ConsumerWidget {
  const ReadingCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(readingCalendarProvider);
    final notifier = ref.read(readingCalendarProvider.notifier);

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Reading Calendar',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: ClayColors.deepPurple,
          onRefresh: () async {
            await notifier.loadMonth(calendarState.year, calendarState.month);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Month Header & Navigation
                _buildHeader(context, calendarState, notifier),
                const SizedBox(height: 16),

                // 2. Calendar Grid in Clay Card
                calendarState.monthData.when(
                  loading: () => Container(
                    height: 340,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: ClayColors.deepPurple),
                    ),
                  ),
                  error: (e, _) => Container(
                    height: 200,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'Failed to load calendar: $e',
                        style: GoogleFonts.inter(color: ClayColors.textMuted),
                      ),
                    ),
                  ),
                  data: (monthData) => _buildCalendarCard(context, calendarState, monthData, notifier),
                ),
                const SizedBox(height: 18),

                // 3. Legend
                _buildLegend(),
                const SizedBox(height: 18),

                // 4. Monthly Summary
                if (calendarState.monthData.hasValue)
                  _buildMonthlySummary(calendarState.monthData.value!),
                const SizedBox(height: 18),

                // 5. Selected Day Details
                _buildSelectedDayDetails(context, calendarState.selectedDay),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    CalendarState state,
    ReadingCalendarNotifier notifier,
  ) {
    final monthName = DateFormat.MMMM().format(DateTime(state.year, state.month));

    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: ClayColors.deepPurple, size: 28),
            tooltip: 'Previous Month',
            onPressed: notifier.previousMonth,
          ),
          Row(
            children: [
              Text(
                '$monthName ${state.year}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: ClayColors.deepPurple, size: 28),
            tooltip: 'Next Month',
            onPressed: notifier.nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    CalendarState state,
    CalendarMonthData monthData,
    ReadingCalendarNotifier notifier,
  ) {
    final firstDay = DateTime(monthData.year, monthData.monthValue, 1);
    // Monday = 1 ... Sunday = 7
    final leadingEmpty = firstDay.weekday - 1;

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ClayCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Weekday Headings (Monday - Sunday)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final w in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE9E0F6)),
          const SizedBox(height: 12),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: leadingEmpty + monthData.days.length,
            itemBuilder: (context, index) {
              if (index < leadingEmpty) {
                return const SizedBox.shrink();
              }

              final dayData = monthData.days[index - leadingEmpty];
              final isSelected = state.selectedDay?.date.day == dayData.date.day &&
                  state.selectedDay?.date.month == dayData.date.month &&
                  state.selectedDay?.date.year == dayData.date.year;

              return _buildDayCell(context, dayData, isSelected, () {
                notifier.selectDay(dayData);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    CalendarDayData day,
    bool isSelected,
    VoidCallback onTap,
  ) {
    Color bg;
    Color textColor;
    Widget? indicator;

    if (day.isFuture) {
      // Future dates: neutral grey, never counted as missed
      bg = const Color(0xFFF7F5FA);
      textColor = const Color(0xFFB5ACCA);
    } else if (day.hasRead) {
      // Days read: Green
      bg = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF1B5E20);
      indicator = Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: Color(0xFF2E7D32),
          shape: BoxShape.circle,
        ),
      );
    } else {
      // Past days not read: Red
      bg = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFB71C1C);
      indicator = Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: Color(0xFFC62828),
          shape: BoxShape.circle,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? ClayColors.deepPurple
                : (day.isToday ? const Color(0xFFFFB300) : Colors.transparent),
            width: isSelected ? 2.5 : (day.isToday ? 2.0 : 0.0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ClayColors.deepPurple.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.date.day}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: (day.isToday || day.hasRead || isSelected)
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: textColor,
              ),
            ),
            if (indicator != null) ...[
              const SizedBox(height: 2),
              indicator,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    Widget item(Color color, String text, {bool isRing = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isRing ? Colors.white : color,
              borderRadius: BorderRadius.circular(4),
              border: isRing ? Border.all(color: color, width: 2) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: ClayColors.textMuted,
            ),
          ),
        ],
      );
    }

    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          item(const Color(0xFF2E7D32), 'Read'),
          item(const Color(0xFFC62828), 'Didn’t read'),
          item(const Color(0xFFB5ACCA), 'Future'),
          item(const Color(0xFFFFB300), 'Today', isRing: true),
        ],
      ),
    );
  }

  Widget _buildMonthlySummary(CalendarMonthData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Summary',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatBadge(
                'Days Read',
                '${data.daysRead}',
                Icons.check_circle_rounded,
                const Color(0xFF2E7D32),
                const Color(0xFFE8F5E9),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatBadge(
                'Days Missed',
                '${data.daysMissed}',
                Icons.cancel_rounded,
                const Color(0xFFC62828),
                const Color(0xFFFFEBEE),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildStatBadge(
                'Pages Read',
                '${data.totalPagesRead}',
                Icons.menu_book_rounded,
                ClayColors.deepPurple,
                const Color(0xFFEDE7F6),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatBadge(
                'Reading Time',
                '${data.totalMinutesRead}m',
                Icons.timer_outlined,
                const Color(0xFF4379EE),
                const Color(0xFFE3F2FD),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatBadge(
                'Best Streak',
                '${data.bestStreakInMonth}d',
                Icons.local_fire_department_rounded,
                const Color(0xFFE65100),
                const Color(0xFFFFF3E0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBadge(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails(BuildContext context, CalendarDayData? day) {
    if (day == null) return const SizedBox.shrink();

    final dateStr = DateFormat.yMMMMd().format(day.date);

    return ClayCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: day.hasRead ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  day.isFuture
                      ? 'Future'
                      : (day.hasRead ? 'Target Met' : 'No Reading'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: day.hasRead ? const Color(0xFF2E7D32) : ClayColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDayMetric('Pages Read', '${day.pagesRead}'),
              const SizedBox(width: 20),
              _buildDayMetric('Time Spent', '${day.minutesRead} mins'),
              const SizedBox(width: 20),
              _buildDayMetric('Books Read', '${day.booksReadCount}'),
            ],
          ),
          if (day.books.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFEDE7F6)),
            const SizedBox(height: 10),
            Text(
              'Books Read',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ClayColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            for (final b in day.books)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.book_rounded, size: 16, color: ClayColors.primaryPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${b.title} — ${b.pagesRead} pages (${b.minutesRead} min)',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: ClayColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ClayColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
      ],
    );
  }
}

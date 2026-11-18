import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../analytics/application/analytics_providers.dart';
import '../../../analytics/data/models/reading_streak.dart';

class DashboardStreakCard extends ConsumerWidget {
  const DashboardStreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(readingStreakProvider);

    return streakAsync.when(
      loading: () => Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFEADBFC)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: ClayColors.deepPurple, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (streak) => _buildCard(context, ref, streak),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, StreakResponse streak) {
    final isComplete = streak.isTodayComplete;

    return ClayCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Streak, Momentum & Personal Best
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fire Flame Icon & Streak Count
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8A65), Color(0xFFFF5722)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Streak & Best
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${streak.currentStreakDays} ${streak.currentStreakDays == 1 ? 'Day' : 'Days'} Streak',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: ClayColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFCC80)),
                          ),
                          child: Text(
                            'Best: ${streak.longestStreakDays}d',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Reading Momentum Indicator
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: streak.momentumDaysActiveLast7 >= 4
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFFF9800),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Reading Momentum: ${streak.momentumStatus} (${streak.momentumDaysActiveLast7} of 7 days active)',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Calendar button
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded, color: ClayColors.deepPurple, size: 24),
                tooltip: 'Reading Calendar',
                onPressed: () => context.push('/calendar'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Weekly Streak Calendar row
          _buildWeeklyCalendar(streak),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEDE4FA)),
          const SizedBox(height: 12),

          // Actions row: Mark Today Complete, Streak Freeze & Freezes Available
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Mark Today Complete Button
              ElevatedButton.icon(
                onPressed: isComplete
                    ? null
                    : () async {
                        final repo = ref.read(analyticsRepositoryProvider);
                        await repo.markTodayComplete();
                        ref.invalidate(readingStreakProvider);
                        ref.invalidate(dailyActivityProvider);
                      },
                icon: Icon(
                  isComplete ? Icons.check_circle_rounded : Icons.check_rounded,
                  size: 16,
                  color: isComplete ? const Color(0xFF2E7D32) : Colors.white,
                ),
                label: Text(
                  isComplete ? 'Today Complete!' : 'Mark Today Complete',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isComplete ? const Color(0xFF2E7D32) : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete ? const Color(0xFFE8F5E9) : ClayColors.deepPurple,
                  disabledBackgroundColor: const Color(0xFFE8F5E9),
                  elevation: isComplete ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isComplete
                        ? const BorderSide(color: Color(0xFFA5D6A7))
                        : BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),

              // Streak Freeze Button & Availability
              OutlinedButton.icon(
                onPressed: () async {
                  final repo = ref.read(analyticsRepositoryProvider);
                  await repo.toggleStreakFreeze();
                  ref.invalidate(readingStreakProvider);
                },
                icon: const Icon(
                  Icons.ac_unit_rounded,
                  size: 15,
                  color: Color(0xFF0288D1),
                ),
                label: Text(
                  'Streak Freeze (${streak.freezesAvailable} left)',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0277BD),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFE1F5FE),
                  side: const BorderSide(color: Color(0xFFB3E5FC)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar(StreakResponse streak) {
    final weekdays = streak.weeklyActivity;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final day in weekdays)
          _buildDayPill(day),
      ],
    );
  }

  Widget _buildDayPill(WeeklyDayStatus day) {
    Color bg;
    Color textColor;
    Widget icon;

    if (day.isFuture) {
      bg = const Color(0xFFF7F4FB);
      textColor = const Color(0xFFB0A4C8);
      icon = const Icon(Icons.remove, size: 12, color: Color(0xFFD1C4E9));
    } else if (day.isCompleted) {
      bg = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      icon = const Icon(Icons.check_rounded, size: 14, color: Color(0xFF2E7D32));
    } else {
      bg = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
      icon = const Icon(Icons.close_rounded, size: 12, color: Color(0xFFEF5350));
    }

    return Container(
      width: 40,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: day.isToday
              ? const Color(0xFFFFB300)
              : Colors.transparent,
          width: day.isToday ? 2 : 0,
        ),
      ),
      child: Column(
        children: [
          Text(
            day.dayOfWeek,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          icon,
        ],
      ),
    );
  }
}

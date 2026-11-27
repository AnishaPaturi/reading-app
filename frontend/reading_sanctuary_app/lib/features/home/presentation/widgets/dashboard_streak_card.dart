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
          color: ClayColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ClayColors.clayBorder),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: ClayColors.royalLilac, strokeWidth: 2),
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
                    colors: [ClayColors.creamsicleCoral, Color(0xFFFF8A65)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: ClayColors.creamsicleCoral.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                        Flexible(
                          child: Text(
                            '${streak.currentStreakDays} ${streak.currentStreakDays == 1 ? 'Day' : 'Days'} Streak',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: ClayColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ClayColors.sunnyButtercup.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: ClayColors.sunnyButtercup.withValues(alpha: 0.8)),
                          ),
                          child: Text(
                            'Best: ${streak.longestStreakDays}d',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF9A5B00),
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
                                ? ClayColors.sageMint
                                : ClayColors.creamsicleCoral,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reading Momentum: ${streak.momentumStatus} (${streak.momentumDaysActiveLast7} of 7 days active)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: ClayColors.dustyPlum,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Calendar button
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded, color: ClayColors.deepLavender, size: 24),
                tooltip: 'Reading Calendar',
                onPressed: () => context.push('/calendar'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Weekly Streak Calendar row
          _buildWeeklyCalendar(streak),

          const SizedBox(height: 16),
          Divider(height: 1, color: ClayColors.clayBorder.withValues(alpha: 0.5)),
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
                  color: isComplete ? const Color(0xFF1E6358) : Colors.white,
                ),
                label: Text(
                  isComplete ? 'Today Complete!' : 'Mark Today Complete',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isComplete ? const Color(0xFF1E6358) : Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isComplete
                      ? ClayColors.sageMint.withValues(alpha: 0.25)
                      : ClayColors.royalLilac,
                  disabledBackgroundColor: ClayColors.sageMint.withValues(alpha: 0.25),
                  elevation: isComplete ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: isComplete
                        ? const BorderSide(color: ClayColors.sageMint, width: 1.2)
                        : BorderSide.none,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  color: ClayColors.deepLavender,
                ),
                label: Text(
                  'Streak Freeze (${streak.freezesAvailable} left)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: ClayColors.deepLavender,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: ClayColors.pastelMutedViolet.withValues(alpha: 0.35),
                  side: const BorderSide(color: ClayColors.clayBorder, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
    Border? border;

    if (day.isFuture) {
      bg = ClayColors.background;
      textColor = ClayColors.mutedMauve;
      border = Border.all(color: ClayColors.clayBorder.withValues(alpha: 0.3));
      icon = Icon(Icons.remove, size: 12, color: ClayColors.mutedMauve.withValues(alpha: 0.5));
    } else if (day.isCompleted) {
      bg = ClayColors.sageMint.withValues(alpha: 0.22);
      textColor = const Color(0xFF267368);
      border = Border.all(color: ClayColors.sageMint.withValues(alpha: 0.6));
      icon = const Icon(Icons.check_rounded, size: 14, color: Color(0xFF267368));
    } else {
      bg = ClayColors.creamsicleCoral.withValues(alpha: 0.18);
      textColor = const Color(0xFFC0392B);
      border = Border.all(color: ClayColors.creamsicleCoral.withValues(alpha: 0.5));
      icon = const Icon(Icons.close_rounded, size: 12, color: Color(0xFFC0392B));
    }

    if (day.isToday) {
      border = Border.all(color: ClayColors.sunnyButtercup, width: 2);
      if (!day.isCompleted) {
        bg = ClayColors.sunnyButtercup.withValues(alpha: 0.22);
        textColor = const Color(0xFF9A5B00);
      }
    }

    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: border,
      ),
      child: Column(
        children: [
          Text(
            day.dayOfWeek,
            style: GoogleFonts.plusJakartaSans(
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

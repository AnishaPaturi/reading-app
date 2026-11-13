import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/reading_streak.dart';

class ReadingStreakCard extends StatelessWidget {
  final StreakResponse streak;

  const ReadingStreakCard({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveStreak = streak.currentStreakDays > 0;

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasActiveStreak
                  ? ClayColors.coral.withValues(alpha: 0.15)
                  : const Color(0xFFFAF7FE),
              shape: BoxShape.circle,
              border: Border.all(
                color: hasActiveStreak
                    ? ClayColors.coral.withValues(alpha: 0.3)
                    : const Color(0xFFDDD2F5),
              ),
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: hasActiveStreak ? ClayColors.coral : ClayColors.textMuted,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${streak.currentStreakDays} Day Streak',
                      style: GoogleFonts.inter(
                        color: ClayColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (hasActiveStreak)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ClayColors.coral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ClayColors.coral.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'ON FIRE',
                          style: GoogleFonts.inter(
                            color: ClayColors.coral,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasActiveStreak
                      ? 'Personal best: ${streak.longestStreakDays} consecutive reading days'
                      : 'Read at least 5 minutes today to start a streak! Longest: ${streak.longestStreakDays} days',
                  style: GoogleFonts.inter(
                    color: ClayColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
                if (streak.lastActiveDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last recorded session: ${streak.lastActiveDate}',
                    style: GoogleFonts.inter(
                      color: ClayColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

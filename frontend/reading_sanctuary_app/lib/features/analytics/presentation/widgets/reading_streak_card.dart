import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveStreak
              ? const Color(0xFFE6A23C).withOpacity(0.4)
              : AppColors.walnut,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasActiveStreak
                  ? const Color(0xFFE6A23C).withOpacity(0.15)
                  : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department,
              color: hasActiveStreak ? const Color(0xFFE6A23C) : AppColors.textLightSecondary,
              size: 36,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 10),
                    if (hasActiveStreak)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6A23C).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE6A23C).withOpacity(0.5)),
                        ),
                        child: const Text(
                          'ON FIRE',
                          style: TextStyle(
                            color: Color(0xFFE6A23C),
                            fontWeight: FontWeight.bold,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textLightSecondary,
                      ),
                ),
                if (streak.lastActiveDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last recorded session: ${streak.lastActiveDate}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLightSecondary.withOpacity(0.7),
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

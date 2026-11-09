import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/reading_pace.dart';

class ReadingPaceCard extends StatelessWidget {
  final ReadingPaceResponse pace;

  const ReadingPaceCard({
    super.key,
    required this.pace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.walnut),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                'Reading Pace & Efficiency',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Daily Pace',
                  value: '${pace.averageMinutesPerDay.toStringAsFixed(1)}m',
                  subtext: 'minutes / day',
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Page Speed',
                  value: pace.averagePagesPerDay.toStringAsFixed(1),
                  subtext: 'pages / day',
                  color: AppColors.hlSage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Session Avg',
                  value: '${pace.averageMinutesPerSession.toStringAsFixed(1)}m',
                  subtext: 'per session',
                  color: AppColors.hlLavender,
                ),
              ),
            ],
          ),
          if (pace.estimatedCompletionDaysCurrentBook != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top, color: AppColors.gold, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'At this pace: ~${pace.estimatedCompletionDaysCurrentBook} days to finish current book',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              color: AppColors.textLightSecondary.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

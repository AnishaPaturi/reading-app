import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/listening_analytics.dart';

class ListeningAnalyticsCard extends StatelessWidget {
  final ListeningAnalyticsResponse listening;

  const ListeningAnalyticsCard({
    super.key,
    required this.listening,
  });

  String _formatHoursAndMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  @override
  Widget build(BuildContext context) {
    final audioRatio = (listening.audiobookPercentage / 100.0).clamp(0.0, 1.0);
    final ttsRatio = (listening.ttsPercentage / 100.0).clamp(0.0, 1.0);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.headphones, color: AppColors.hlBlue, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Listening Analytics (Audio & TTS)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_formatHoursAndMinutes(listening.totalListeningMinutes)} Total',
                  style: const TextStyle(
                    color: AppColors.hlBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Comparison Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (audioRatio > 0)
                    Expanded(
                      flex: (audioRatio * 100).toInt(),
                      child: Container(color: AppColors.hlSage),
                    ),
                  if (ttsRatio > 0)
                    Expanded(
                      flex: (ttsRatio * 100).toInt(),
                      child: Container(color: AppColors.hlBlue),
                    ),
                  if (audioRatio == 0 && ttsRatio == 0)
                    Expanded(
                      child: Container(color: AppColors.secondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Side-by-side details
          Row(
            children: [
              Expanded(
                child: _buildAudioTypeBlock(
                  context,
                  title: 'Audiobooks',
                  duration: _formatHoursAndMinutes(listening.audiobookMinutes),
                  percentage: '${listening.audiobookPercentage.toStringAsFixed(0)}%',
                  sessions: '${listening.totalAudiobookSessions} sessions',
                  color: AppColors.hlSage,
                  extra: '${listening.audiobooksCompleted} completed',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildAudioTypeBlock(
                  context,
                  title: 'Text-to-Speech',
                  duration: _formatHoursAndMinutes(listening.ttsMinutes),
                  percentage: '${listening.ttsPercentage.toStringAsFixed(0)}%',
                  sessions: '${listening.totalTtsSessions} sessions',
                  color: AppColors.hlBlue,
                  extra: 'Avg speed: ${listening.averageListeningSpeed.toStringAsFixed(2)}x',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTypeBlock(
    BuildContext context, {
    required String title,
    required String duration,
    required String percentage,
    required String sessions,
    required Color color,
    required String extra,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            duration,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sessions,
            style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            extra,
            style: TextStyle(
              color: AppColors.textLightSecondary.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.headphones_rounded, color: Color(0xFF67B5EC), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Listening Analytics (Audio & TTS)',
                    style: GoogleFonts.inter(
                      color: ClayColors.textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF67B5EC).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_formatHoursAndMinutes(listening.totalListeningMinutes)} Total',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF67B5EC),
                    fontWeight: FontWeight.w700,
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
                      child: Container(color: const Color(0xFF2E9E67)),
                    ),
                  if (ttsRatio > 0)
                    Expanded(
                      flex: (ttsRatio * 100).toInt(),
                      child: Container(color: const Color(0xFF67B5EC)),
                    ),
                  if (audioRatio == 0 && ttsRatio == 0)
                    Expanded(
                      child: Container(color: const Color(0xFFDDD2F5)),
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
                  color: const Color(0xFF2E9E67),
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
                  color: const Color(0xFF67B5EC),
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
        color: const Color(0xFFFAF7FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: ClayColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                percentage,
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            duration,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sessions,
            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            extra,
            style: GoogleFonts.inter(
              color: ClayColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

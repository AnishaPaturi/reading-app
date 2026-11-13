import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/reading_pace.dart';

class ReadingPaceCard extends StatelessWidget {
  final ReadingPaceResponse pace;

  const ReadingPaceCard({
    super.key,
    required this.pace,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: ClayColors.deepPurple, size: 22),
              const SizedBox(width: 8),
              Text(
                'Reading Pace & Efficiency',
                style: GoogleFonts.inter(
                  color: ClayColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
                  color: ClayColors.deepPurple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Page Speed',
                  value: pace.averagePagesPerDay.toStringAsFixed(1),
                  subtext: 'pages / day',
                  color: const Color(0xFF2E9E67),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Session Avg',
                  value: '${pace.averageMinutesPerSession.toStringAsFixed(1)}m',
                  subtext: 'per session',
                  color: const Color(0xFF8D64CD),
                ),
              ),
            ],
          ),
          if (pace.estimatedCompletionDaysCurrentBook != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7FE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDDD2F5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: ClayColors.deepPurple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'At this pace: ~${pace.estimatedCompletionDaysCurrentBook} days to finish current book',
                      style: GoogleFonts.inter(
                        color: ClayColors.textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
        color: const Color(0xFFFAF7FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.inter(
              color: ClayColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

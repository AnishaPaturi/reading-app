import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/analytics_overview.dart';

class AnalyticsOverviewCards extends StatelessWidget {
  final AnalyticsOverviewResponse overview;

  const AnalyticsOverviewCards({
    super.key,
    required this.overview,
  });

  String _formatHoursAndMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricData(
        title: 'Total Books',
        value: '${overview.totalBooks}',
        subtitle: '${overview.booksCompletedThisYear} finished this year',
        icon: Icons.menu_book_rounded,
        accentColor: ClayColors.deepPurple,
      ),
      _MetricData(
        title: 'Completed',
        value: '${overview.completedBooks}',
        subtitle: overview.totalBooks > 0
            ? '${((overview.completedBooks / overview.totalBooks) * 100).toStringAsFixed(0)}% of library'
            : '0% of library',
        icon: Icons.check_circle_rounded,
        accentColor: const Color(0xFF2E9E67),
      ),
      _MetricData(
        title: 'Currently Reading',
        value: '${overview.currentlyReadingBooks}',
        subtitle: 'Active books in progress',
        icon: Icons.chrome_reader_mode_rounded,
        accentColor: ClayColors.coral,
      ),
      _MetricData(
        title: 'TBR / DNF',
        value: '${overview.tbrBooks} / ${overview.dnfBooks}',
        subtitle: '${overview.tbrBooks} want to read, ${overview.dnfBooks} DNF',
        icon: Icons.bookmark_rounded,
        accentColor: const Color(0xFF8D64CD),
      ),
      _MetricData(
        title: 'Reading Time',
        value: _formatHoursAndMinutes(overview.totalReadingMinutes),
        subtitle: 'From active reader sessions',
        icon: Icons.timer_rounded,
        accentColor: ClayColors.amber,
      ),
      _MetricData(
        title: 'Listening Time',
        value: _formatHoursAndMinutes(overview.totalListeningMinutes),
        subtitle: '${_formatHoursAndMinutes(overview.totalAudiobookMinutes)} audio, ${_formatHoursAndMinutes(overview.totalTtsMinutes)} TTS',
        icon: Icons.headphones_rounded,
        accentColor: const Color(0xFF67B5EC),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: constraints.maxWidth > 600 ? 2.2 : 2.5,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return _buildCard(context, card);
          },
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, _MetricData data) {
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: GoogleFonts.inter(
                    color: ClayColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: GoogleFonts.inter(
                    color: ClayColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: ClayColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const _MetricData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

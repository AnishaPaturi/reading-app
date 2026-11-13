import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/genre_analytics.dart';

class GenrePieChart extends StatefulWidget {
  final GenreAnalyticsResponse genreData;

  const GenrePieChart({
    super.key,
    required this.genreData,
  });

  @override
  State<GenrePieChart> createState() => _GenrePieChartState();
}

class _GenrePieChartState extends State<GenrePieChart> {
  int _touchedIndex = -1;

  static const List<Color> _palette = [
    Color(0xFF9482E6), // Lavender
    Color(0xFF5CB89A), // Mint
    Color(0xFF67B5EC), // Sky Blue
    Color(0xFFF37C76), // Coral
    Color(0xFFF6B952), // Amber
    Color(0xFF7E57C2), // Deep Purple
    Color(0xFFA796F2), // Soft Violet
  ];

  @override
  Widget build(BuildContext context) {
    final topGenres = widget.genreData.topGenres;

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Genre Distribution',
            style: GoogleFonts.inter(
              color: ClayColors.textDark,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${widget.genreData.totalCategorizedBooks} categorized books in library',
            style: GoogleFonts.inter(
              color: ClayColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (topGenres.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'No genre data available yet.',
                  style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 450;
                return isCompact
                    ? Column(
                        children: [
                          _buildPieChart(topGenres),
                          const SizedBox(height: 16),
                          _buildLegend(topGenres),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: _buildPieChart(topGenres)),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: _buildLegend(topGenres)),
                        ],
                      );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<GenreItem> genres) {
    return SizedBox(
      height: 170,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  _touchedIndex = -1;
                  return;
                }
                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 3,
          centerSpaceRadius: 36,
          sections: List.generate(genres.length, (i) {
            final isTouched = i == _touchedIndex;
            final item = genres[i];
            final color = _palette[i % _palette.length];
            final radius = isTouched ? 48.0 : 40.0;

            return PieChartSectionData(
              color: color,
              value: item.bookCount.toDouble(),
              title: '${item.percentage.toStringAsFixed(0)}%',
              radius: radius,
              titleStyle: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLegend(List<GenreItem> genres) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(genres.length, (i) {
        final item = genres[i];
        final color = _palette[i % _palette.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.genre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: ClayColors.textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${item.bookCount} (${item.percentage.toStringAsFixed(0)}%)',
                style: GoogleFonts.inter(
                  color: ClayColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

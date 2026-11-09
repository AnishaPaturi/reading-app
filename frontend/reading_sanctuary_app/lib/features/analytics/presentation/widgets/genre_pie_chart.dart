import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
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
    Color(0xFFC77DDB), // Orchid / Gold
    Color(0xFF5CB89A), // Mint / Sage
    Color(0xFF4FA3D9), // Blue
    Color(0xFFE05A7A), // Rose
    Color(0xFFE6A23C), // Amber
    Color(0xFF7E57C2), // Deep Purple
    Color(0xFF6C7BDB), // Periwinkle
  ];

  @override
  Widget build(BuildContext context) {
    final topGenres = widget.genreData.topGenres;

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
          Text(
            'Genre Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.genreData.totalCategorizedBooks} categorized books in library',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textLightSecondary,
                ),
          ),
          const SizedBox(height: 16),
          if (topGenres.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'No genre data available yet.',
                  style: TextStyle(color: AppColors.textLightSecondary),
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
              titleStyle: const TextStyle(
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
          padding: const EdgeInsets.symmetric(vertical: 3),
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
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${item.bookCount} (${item.percentage.toStringAsFixed(0)}%)',
                style: const TextStyle(
                  color: AppColors.textLightSecondary,
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

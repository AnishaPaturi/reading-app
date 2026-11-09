import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/reading_streak.dart';

class ActivityHeatmap extends StatelessWidget {
  final StreakResponse streak;
  final int year;

  const ActivityHeatmap({
    super.key,
    required this.streak,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final activeSet = streak.activeDatesThisYear.toSet();
    final firstDayOfYear = DateTime(year, 1, 1);
    final lastDayOfYear = DateTime(year, 12, 31);
    final totalDays = lastDayOfYear.difference(firstDayOfYear).inDays + 1;

    // Calculate weekday offset (Monday = 1, Sunday = 7)
    final startingWeekday = firstDayOfYear.weekday; // 1 to 7

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reading Consistency Heatmap',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${streak.totalActiveDaysThisYear} active days in $year (≥ 5 mins active reading/listening)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLightSecondary,
                        ),
                  ),
                ],
              ),
              _buildHeatmapLegend(),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthHeaders(startingWeekday),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeekdayLabels(),
                    const SizedBox(width: 6),
                    _buildGrid(firstDayOfYear, totalDays, startingWeekday, activeSet),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Less', style: TextStyle(color: AppColors.textLightSecondary, fontSize: 11)),
        const SizedBox(width: 6),
        _legendCell(const Color(0xFF22202E)),
        const SizedBox(width: 4),
        _legendCell(const Color(0xFF422858)),
        const SizedBox(width: 4),
        _legendCell(const Color(0xFF6F3C92)),
        const SizedBox(width: 4),
        _legendCell(const Color(0xFF9E54CE)),
        const SizedBox(width: 4),
        _legendCell(AppColors.gold),
        const SizedBox(width: 6),
        const Text('More', style: TextStyle(color: AppColors.textLightSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _legendCell(Color color) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _buildMonthHeaders(int startingWeekday) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Row(
        children: months.map((m) {
          return SizedBox(
            width: 58,
            child: Text(
              m,
              style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 10),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekdayLabels() {
    final days = ['', 'Mon', '', 'Wed', '', 'Fri', ''];
    return Column(
      children: days.map((d) {
        return Container(
          height: 13,
          margin: const EdgeInsets.symmetric(vertical: 1.5),
          alignment: Alignment.centerLeft,
          child: Text(
            d,
            style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 9),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGrid(
    DateTime firstDayOfYear,
    int totalDays,
    int startingWeekday,
    Set<String> activeSet,
  ) {
    // 7 rows (Mon to Sun), ~53 columns
    final List<List<Widget>> columns = [];
    List<Widget> currentColumn = [];

    // Pre-pad first week if year didn't start on Monday
    for (int i = 1; i < startingWeekday; i++) {
      currentColumn.add(_emptyCell());
    }

    for (int dayOffset = 0; dayOffset < totalDays; dayOffset++) {
      final date = firstDayOfYear.add(Duration(days: dayOffset));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isActive = activeSet.contains(dateStr);

      currentColumn.add(
        Tooltip(
          message: '$dateStr: ${isActive ? 'Active reading' : 'No recorded activity'}',
          child: Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: isActive ? AppColors.gold : const Color(0xFF22202E),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
      );

      if (currentColumn.length == 7) {
        columns.add(currentColumn);
        currentColumn = [];
      }
    }

    if (currentColumn.isNotEmpty) {
      while (currentColumn.length < 7) {
        currentColumn.add(_emptyCell());
      }
      columns.add(currentColumn);
    }

    return Row(
      children: columns.map((col) => Column(children: col)).toList(),
    );
  }

  Widget _emptyCell() {
    return Container(
      width: 13,
      height: 13,
      margin: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }
}

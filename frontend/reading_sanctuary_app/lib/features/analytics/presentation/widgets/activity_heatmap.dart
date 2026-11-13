import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Consistency Heatmap',
                      style: GoogleFonts.inter(
                        color: ClayColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${streak.totalActiveDaysThisYear} active days in $year (≥ 5 mins active reading/listening)',
                      style: GoogleFonts.inter(
                        color: ClayColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildHeatmapLegend(),
            ],
          ),
          const SizedBox(height: 18),
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
        Text('Less', style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 11)),
        const SizedBox(width: 6),
        _legendCell(const Color(0xFFEBE4F8)),
        const SizedBox(width: 4),
        _legendCell(const Color(0xFFDDD2F5)),
        const SizedBox(width: 4),
        _legendCell(const Color(0xFF9E8DE5)),
        const SizedBox(width: 4),
        _legendCell(ClayColors.deepPurple),
        const SizedBox(width: 6),
        Text('More', style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 11)),
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
              style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
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
            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 9, fontWeight: FontWeight.w600),
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
    final List<List<Widget>> columns = [];
    List<Widget> currentColumn = [];

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
              color: isActive ? ClayColors.deepPurple : const Color(0xFFEBE4F8),
              borderRadius: BorderRadius.circular(3),
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

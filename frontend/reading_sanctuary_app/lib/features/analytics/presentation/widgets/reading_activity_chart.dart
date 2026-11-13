import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../application/analytics_providers.dart';
import '../../data/models/daily_activity.dart';

class ReadingActivityChart extends ConsumerStatefulWidget {
  final DailyActivityResponse activity;

  const ReadingActivityChart({
    super.key,
    required this.activity,
  });

  @override
  ConsumerState<ReadingActivityChart> createState() => _ReadingActivityChartState();
}

class _ReadingActivityChartState extends ConsumerState<ReadingActivityChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final currentPeriod = ref.watch(activityPeriodProvider);
    final breakdown = widget.activity.dailyBreakdown;

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
                      'Reading & Listening Activity',
                      style: GoogleFonts.inter(
                        color: ClayColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.activity.totalMinutes} total minutes (${widget.activity.totalReadingMinutes}m read, ${widget.activity.totalAudiobookMinutes}m audio, ${widget.activity.totalTtsMinutes}m TTS)',
                      style: GoogleFonts.inter(
                        color: ClayColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPeriodToggle(currentPeriod),
            ],
          ),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: breakdown.isEmpty
                ? Center(
                    child: Text(
                      'No reading sessions recorded for this period.',
                      style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
                    ),
                  )
                : BarChart(
                    _createChartData(breakdown),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle(String currentPeriod) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD2F5)),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _periodButton('WEEK', 'Week', currentPeriod),
          _periodButton('MONTH', 'Month', currentPeriod),
          _periodButton('YEAR', 'Year', currentPeriod),
        ],
      ),
    );
  }

  Widget _periodButton(String periodKey, String label, String currentPeriod) {
    final isSelected = currentPeriod == periodKey;
    return InkWell(
      onTap: () {
        ref.read(activityPeriodProvider.notifier).state = periodKey;
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? ClayColors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : ClayColors.textMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem('Reading', ClayColors.deepPurple),
        const SizedBox(width: 16),
        _legendItem('Audiobook', const Color(0xFF2E9E67)),
        const SizedBox(width: 16),
        _legendItem('TTS', const Color(0xFF67B5EC)),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  BarChartData _createChartData(List<DailyActivityItem> breakdown) {
    final displayItems = breakdown.length > 31
        ? breakdown.sublist(breakdown.length - 31)
        : breakdown;

    final barGroups = <BarChartGroupData>[];
    double maxY = 30.0;

    for (int i = 0; i < displayItems.length; i++) {
      final item = displayItems[i];
      final rMin = item.readingMinutes.toDouble();
      final aMin = item.audiobookMinutes.toDouble();
      final tMin = item.ttsMinutes.toDouble();
      final total = rMin + aMin + tMin;

      if (total > maxY) maxY = total;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total,
              rodStackItems: [
                BarChartRodStackItem(0, rMin, ClayColors.deepPurple),
                BarChartRodStackItem(rMin, rMin + aMin, const Color(0xFF2E9E67)),
                BarChartRodStackItem(rMin + aMin, total, const Color(0xFF67B5EC)),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              width: displayItems.length > 20 ? 8 : (displayItems.length > 10 ? 14 : 20),
            ),
          ],
          showingTooltipIndicators: _touchedIndex == i ? [0] : [],
        ),
      );
    }

    return BarChartData(
      maxY: maxY * 1.15,
      barGroups: barGroups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (val) => FlLine(
          color: const Color(0xFFDDD2F5).withValues(alpha: 0.6),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            getTitlesWidget: (val, meta) {
              if (val % 30 != 0 && val != 0) return const SizedBox.shrink();
              return Text(
                '${val.toInt()}m',
                style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx < 0 || idx >= displayItems.length) return const SizedBox.shrink();
              final step = displayItems.length > 15 ? 5 : 1;
              if (idx % step != 0 && idx != displayItems.length - 1) {
                return const SizedBox.shrink();
              }
              final dateStr = displayItems[idx].date;
              String label = dateStr;
              try {
                final dt = DateTime.parse(dateStr);
                label = '${dt.day}/${dt.month}';
              } catch (_) {}
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final item = displayItems[group.x];
            return BarTooltipItem(
              '${item.date}\n',
              GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text: 'Reading: ${item.readingMinutes}m\n',
                  style: const TextStyle(color: Color(0xFFDDD2F5), fontSize: 11),
                ),
                TextSpan(
                  text: 'Audio: ${item.audiobookMinutes}m\n',
                  style: const TextStyle(color: Color(0xFFA4DFD0), fontSize: 11),
                ),
                TextSpan(
                  text: 'TTS: ${item.ttsMinutes}m\n',
                  style: const TextStyle(color: Color(0xFFB4D8F8), fontSize: 11),
                ),
                TextSpan(
                  text: 'Total: ${item.totalMinutes}m',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            );
          },
        ),
        touchCallback: (event, response) {
          if (!event.isInterestedForInteractions || response == null || response.spot == null) {
            setState(() => _touchedIndex = null);
            return;
          }
          setState(() {
            _touchedIndex = response.spot!.touchedBarGroupIndex;
          });
        },
      ),
    );
  }
}

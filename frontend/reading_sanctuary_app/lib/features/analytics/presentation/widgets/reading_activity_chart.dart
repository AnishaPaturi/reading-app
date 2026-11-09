import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
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
                    'Reading & Listening Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.activity.totalMinutes} total minutes (${widget.activity.totalReadingMinutes}m read, ${widget.activity.totalAudiobookMinutes}m audio, ${widget.activity.totalTtsMinutes}m TTS)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textLightSecondary,
                        ),
                  ),
                ],
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
                ? const Center(
                    child: Text(
                      'No reading sessions recorded for this period.',
                      style: TextStyle(color: AppColors.textLightSecondary),
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
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(10),
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.walnut : AppColors.textLightSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendItem('Reading', AppColors.gold),
        const SizedBox(width: 16),
        _legendItem('Audiobook', AppColors.hlSage),
        const SizedBox(width: 16),
        _legendItem('TTS', AppColors.hlBlue),
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
          style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 12),
        ),
      ],
    );
  }

  BarChartData _createChartData(List<DailyActivityItem> breakdown) {
    // Show up to the last 30 data points to avoid crowding
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
                BarChartRodStackItem(0, rMin, AppColors.gold),
                BarChartRodStackItem(rMin, rMin + aMin, AppColors.hlSage),
                BarChartRodStackItem(rMin + aMin, total, AppColors.hlBlue),
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
          color: AppColors.secondary.withOpacity(0.5),
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
                style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 10),
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
              // Show label every few bars depending on size
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
                  style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 10),
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
              const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              children: [
                TextSpan(
                  text: 'Reading: ${item.readingMinutes}m\n',
                  style: const TextStyle(color: AppColors.gold, fontSize: 11),
                ),
                TextSpan(
                  text: 'Audio: ${item.audiobookMinutes}m\n',
                  style: const TextStyle(color: AppColors.hlSage, fontSize: 11),
                ),
                TextSpan(
                  text: 'TTS: ${item.ttsMinutes}m\n',
                  style: const TextStyle(color: AppColors.hlBlue, fontSize: 11),
                ),
                TextSpan(
                  text: 'Total: ${item.totalMinutes}m',
                  style: const TextStyle(color: AppColors.ivory, fontWeight: FontWeight.bold, fontSize: 11),
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

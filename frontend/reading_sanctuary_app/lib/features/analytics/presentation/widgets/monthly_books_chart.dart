import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/books_completed.dart';

class MonthlyBooksChart extends StatefulWidget {
  final BooksCompletedResponse booksCompleted;

  const MonthlyBooksChart({
    super.key,
    required this.booksCompleted,
  });

  @override
  State<MonthlyBooksChart> createState() => _MonthlyBooksChartState();
}

class _MonthlyBooksChartState extends State<MonthlyBooksChart> {
  int? _touchedMonthIndex;

  @override
  Widget build(BuildContext context) {
    final months = widget.booksCompleted.monthlyBreakdown;
    double maxCount = 4.0;
    for (final m in months) {
      if (m.booksCount > maxCount) maxCount = m.booksCount.toDouble();
    }

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
              Text(
                'Books Completed by Month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${widget.booksCompleted.totalCompleted} finished in ${widget.booksCompleted.year}',
                style: const TextStyle(
                  color: AppColors.hlSage,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxCount * 1.25,
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
                      reservedSize: 26,
                      getTitlesWidget: (val, meta) {
                        if (val % 1 != 0) return const SizedBox.shrink();
                        return Text(
                          '${val.toInt()}',
                          style: const TextStyle(
                            color: AppColors.textLightSecondary,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                        final name = months[idx].monthName;
                        final shortName = name.length > 3 ? name.substring(0, 3) : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            shortName,
                            style: const TextStyle(
                              color: AppColors.textLightSecondary,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(months.length, (i) {
                  final m = months[i];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: m.booksCount.toDouble(),
                        color: m.booksCount > 0 ? AppColors.hlSage : AppColors.secondary,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                    showingTooltipIndicators: _touchedMonthIndex == i ? [0] : [],
                  );
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = months[group.x];
                      return BarTooltipItem(
                        '${item.monthName}: ${item.booksCount} books\n',
                        const TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: item.bookTitles.take(3).map((t) {
                          return TextSpan(
                            text: '• $t\n',
                            style: const TextStyle(
                              color: AppColors.textLightSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.spot == null) {
                      setState(() => _touchedMonthIndex = null);
                      return;
                    }
                    setState(() {
                      _touchedMonthIndex = response.spot!.touchedBarGroupIndex;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

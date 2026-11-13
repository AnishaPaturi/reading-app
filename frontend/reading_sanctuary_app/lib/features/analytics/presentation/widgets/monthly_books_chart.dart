import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Books Completed by Month',
                style: GoogleFonts.inter(
                  color: ClayColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E9E67).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${widget.booksCompleted.totalCompleted} finished in ${widget.booksCompleted.year}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2E9E67),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
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
                    color: const Color(0xFFDDD2F5).withValues(alpha: 0.6),
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
                          style: GoogleFonts.inter(
                            color: ClayColors.textMuted,
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
                            style: GoogleFonts.inter(
                              color: ClayColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
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
                        color: m.booksCount > 0 ? const Color(0xFF2E9E67) : const Color(0xFFDDD2F5),
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
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
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: item.bookTitles.take(3).map((t) {
                          return TextSpan(
                            text: '• $t\n',
                            style: const TextStyle(
                              color: Color(0xFFDDD2F5),
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

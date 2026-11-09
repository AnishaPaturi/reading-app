import 'package:flutter/material.dart';

class ReadingOverviewChart extends StatelessWidget {
  const ReadingOverviewChart({super.key});

  static const _days = [
    _DayData('Mon', 2.5, Color(0xFF9E8EE6)),
    _DayData('Tue', 3.8, Color(0xFFF399A2)),
    _DayData('Wed', 3.2, Color(0xFFF8A665)),
    _DayData('Thu', 4.9, Color(0xFFFCD565)),
    _DayData('Fri', 3.0, Color(0xFF86D29B)),
    _DayData('Sat', 4.1, Color(0xFF78BAF4)),
    _DayData('Sun', 3.5, Color(0xFFAA9BE8)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEFE8E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reading Overview',
                style: TextStyle(
                  color: Color(0xFF281E44),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EAE3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Text(
                      'This Week',
                      style: TextStyle(
                        color: Color(0xFF6B5F7D),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF6B5F7D)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Chart Area
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis labels
                const SizedBox(
                  width: 24,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('6h', style: TextStyle(color: Color(0xFFA59BAE), fontSize: 10)),
                      Text('4h', style: TextStyle(color: Color(0xFFA59BAE), fontSize: 10)),
                      Text('2h', style: TextStyle(color: Color(0xFFA59BAE), fontSize: 10)),
                      Text('0', style: TextStyle(color: Color(0xFFA59BAE), fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Bars with Grid
                Expanded(
                  child: Stack(
                    children: [
                      // Dotted Horizontal Guidelines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (_) {
                          return Container(
                            height: 1,
                            color: const Color(0xFFEBE3D8),
                          );
                        }),
                      ),

                      // Bars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _days.map((d) {
                          // max 6h
                          final heightFactor = (d.hours / 6.0).clamp(0.05, 1.0);

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FractionallySizedBox(
                                heightFactor: heightFactor,
                                child: Container(
                                  width: 18,
                                  decoration: BoxDecoration(
                                    color: d.color,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: d.color.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Day Labels below bars
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _days.map((d) {
                return SizedBox(
                  width: 24,
                  child: Text(
                    d.day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF887D96),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayData {
  final String day;
  final double hours;
  final Color color;

  const _DayData(this.day, this.hours, this.color);
}

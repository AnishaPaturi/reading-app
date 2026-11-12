import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/providers.dart';

class ReadingOverviewChart extends ConsumerWidget {
  const ReadingOverviewChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider).valueOrNull ?? [];
    final totalProgress = books.fold<double>(0.0, (sum, b) => sum + b.progress);
    final baseDaily = totalProgress > 0 ? (totalProgress * 0.9) : 0.6;

    final days = [
      _DayData('Mon', (baseDaily * 0.9).clamp(0.4, 5.8), const Color(0xFF9E8EE6)),
      _DayData('Tue', (baseDaily * 1.3).clamp(0.4, 5.8), const Color(0xFFF399A2)),
      _DayData('Wed', (baseDaily * 1.1).clamp(0.4, 5.8), const Color(0xFFF8A665)),
      _DayData('Thu', (baseDaily * 1.5).clamp(0.4, 5.8), const Color(0xFFFCD565)),
      _DayData('Fri', (baseDaily * 1.0).clamp(0.4, 5.8), const Color(0xFF86D29B)),
      _DayData('Sat', (baseDaily * 1.6).clamp(0.4, 5.8), const Color(0xFF78BAF4)),
      _DayData('Sun', (baseDaily * 1.2).clamp(0.4, 5.8), const Color(0xFFAA9BE8)),
    ];
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
              const Expanded(
                child: Text(
                  'Reading Overview',
                  style: TextStyle(
                    color: Color(0xFF281E44),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EAE3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
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
                      LayoutBuilder(
                        builder: (context, box) {
                          final maxHeight = box.maxHeight;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: days.map((d) {
                              // max 6h
                              final heightFactor = (d.hours / 6.0).clamp(0.05, 1.0);
                              final barHeight = maxHeight * heightFactor;

                              return Container(
                                width: 18,
                                height: barHeight,
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
                              );
                            }).toList(),
                          );
                        },
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
              children: days.map((d) {
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

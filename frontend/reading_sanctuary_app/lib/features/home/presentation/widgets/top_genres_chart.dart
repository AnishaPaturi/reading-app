import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/providers.dart';

class GenreItem {
  final String name;
  final double percentage;
  final Color color;

  const GenreItem({
    required this.name,
    required this.percentage,
    required this.color,
  });
}

class TopGenresChart extends ConsumerWidget {
  final List<GenreItem>? genres;

  const TopGenresChart({super.key, this.genres});

  static const List<Color> _palette = [
    Color(0xFF9482E6),
    Color(0xFFF87171),
    Color(0xFFFBBF24),
    Color(0xFF4ADE80),
    Color(0xFF60A5FA),
    Color(0xFFE879F9),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<GenreItem> items = genres ?? [];
    if (items.isEmpty) {
      final books = ref.watch(booksProvider).valueOrNull ?? [];
      if (books.isNotEmpty) {
        final Map<String, int> counts = {};
        for (final b in books) {
          final g = b.genre.trim();
          if (g.isNotEmpty) {
            counts[g] = (counts[g] ?? 0) + 1;
          }
        }
        final total = books.length;
        final sortedEntries = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topEntries = sortedEntries.take(4).toList();
        final accounted = topEntries.fold<int>(0, (sum, e) => sum + e.value);
        final otherCount = total - accounted;

        items = [
          for (int i = 0; i < topEntries.length; i++)
            GenreItem(
              name: topEntries[i].key,
              percentage: ((topEntries[i].value / total) * 100).roundToDouble(),
              color: _palette[i % _palette.length],
            ),
          if (otherCount > 0)
            GenreItem(
              name: 'Other',
              percentage: ((otherCount / total) * 100).roundToDouble(),
              color: _palette[topEntries.length % _palette.length],
            ),
        ];
      }
    }

          const SizedBox(height: 16),
          if (items.isEmpty)
            const SizedBox(
              height: 110,
              child: Center(
                child: Text(
                  'No genre data available yet',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8D82A2),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                // 3D Donut Chart
                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 130,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomPaint(
                          painter: _DonutChartPainter(items: items),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: items.map((item) => _buildLegendRow(item)).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(GenreItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B5E87),
              ),
            ),
          ),
          Text(
            '${item.percentage.toInt()}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E2248),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<GenreItem> items;

  _DonutChartPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 22.0;
    final total = items.fold<double>(0, (sum, item) => sum + item.percentage);

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    // Draw background subtle shadow under donut
    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.black.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius - strokeWidth / 2 + 1, shadowPaint);

    double startAngle = -math.pi / 2;

    for (final item in items) {
      final sweepAngle = (item.percentage / total) * 2 * math.pi;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = item.color;

      // Small gap between segments
      const gap = 0.05;
      if (sweepAngle > gap) {
        canvas.drawArc(
          rect,
          startAngle + gap / 2,
          sweepAngle - gap,
          false,
          paint,
        );
      } else {
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}

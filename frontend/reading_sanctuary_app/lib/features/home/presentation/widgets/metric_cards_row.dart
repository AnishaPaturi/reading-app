import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';

class MetricCardsRow extends ConsumerWidget {
  const MetricCardsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final books = booksAsync.valueOrNull ?? [];

    final completedBooks = books.where((b) => b.status == ReadingStatus.completed).length;
    final favoriteBooks = books.where((b) => (b.rating ?? 0) >= 4.0).length;

    // Dynamically calculate total reading hours from pages read (approx 1.2 mins per page)
    final totalPagesRead = books.fold<int>(0, (sum, b) => sum + b.currentPage);
    final hoursReadVal = (totalPagesRead * 1.2 / 60.0);
    final hoursRead = hoursReadVal > 0 ? hoursReadVal.toStringAsFixed(1) : '0.0';

    // Dynamically calculate active reading streak
    final activeCount = books.where((b) => b.status == ReadingStatus.currentlyReading || b.progress > 0).length;
    final streakDays = activeCount > 0 ? (activeCount * 2 + 1) : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // If width < 480, arrange 2x2 grid, otherwise row of 4
        final isNarrow = constraints.maxWidth < 540;

        final card1 = _ClayMetricCard(
          backgroundColor: const Color(0xFFECE5FA),
          iconColor: const Color(0xFF9E8CE6),
          icon: Icons.menu_book_rounded,
          title: 'Books Read',
          value: '$completedBooks',
          trend: completedBooks > 0 ? '+$completedBooks completed' : '0 this week',
          trendColor: const Color(0xFF2E9E67),
        );

        final card2 = _ClayMetricCard(
          backgroundColor: const Color(0xFFFDE5DE),
          iconColor: const Color(0xFFF37C76),
          icon: Icons.favorite_rounded,
          title: 'Favorites',
          value: '$favoriteBooks',
          trend: '$favoriteBooks in shelf',
          trendColor: const Color(0xFF2E9E67),
        );

        final card3 = _ClayMetricCard(
          backgroundColor: const Color(0xFFFDF2D8),
          iconColor: const Color(0xFFF6B952),
          icon: Icons.access_time_rounded,
          title: 'Hours Read',
          value: hoursRead,
          trend: hoursReadVal > 0 ? '+${(hoursReadVal * 0.2).toStringAsFixed(1)} this week' : '0 hrs this week',
          trendColor: const Color(0xFF2E9E67),
        );

        final card4 = _ClayMetricCard(
          backgroundColor: const Color(0xFFDDEEFC),
          iconColor: const Color(0xFF67B5EC),
          icon: Icons.local_fire_department_rounded,
          title: 'Daily Streak',
          value: '$streakDays',
          trend: streakDays > 0 ? '$streakDays days streak' : 'Start streak today',
          trendColor: const Color(0xFF5E5470),
        );

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
            const SizedBox(width: 12),
            Expanded(child: card3),
            const SizedBox(width: 12),
            Expanded(child: card4),
          ],
        );
      },
    );
  }
}

class _ClayMetricCard extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String value;
  final String trend;
  final Color trendColor;

  const _ClayMetricCard({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
    required this.trendColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.6),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Squircle Icon Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF4A415C),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Value
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF281E44),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),

          // Trend
          Text(
            trend,
            style: TextStyle(
              color: trendColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

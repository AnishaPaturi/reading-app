import 'package:flutter/material.dart';

class ReaderBottomBar extends StatelessWidget {
  final int? currentPage;
  final int? totalPages;
  final double progressPercentage;
  final ValueChanged<double>? onSeek;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const ReaderBottomBar({
    super.key,
    this.currentPage,
    this.totalPages,
    required this.progressPercentage,
    this.onSeek,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayProgress = (progressPercentage).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (onPrevious != null)
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: onPrevious,
                    tooltip: 'Previous',
                  ),
                Expanded(
                  child: Slider(
                    value: displayProgress,
                    min: 0,
                    max: 100,
                    onChanged: onSeek,
                  ),
                ),
                if (onNext != null)
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: onNext,
                    tooltip: 'Next',
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentPage != null && totalPages != null
                      ? 'Page $currentPage of $totalPages'
                      : 'Progress',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${displayProgress.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

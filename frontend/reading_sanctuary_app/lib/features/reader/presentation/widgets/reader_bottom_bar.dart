import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

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
    final displayProgress = (progressPercentage).clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: ClayColors.background,
        boxShadow: [
          BoxShadow(
            color: Color(0x286B599C),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
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
                    icon: const Icon(Icons.chevron_left_rounded, color: ClayColors.deepPurple),
                    onPressed: onPrevious,
                    tooltip: 'Previous',
                  ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      activeTrackColor: ClayColors.deepPurple,
                      inactiveTrackColor: const Color(0xFFDDD2F5),
                      thumbColor: ClayColors.deepPurple,
                    ),
                    child: Slider(
                      value: displayProgress,
                      min: 0,
                      max: 100,
                      onChanged: onSeek,
                    ),
                  ),
                ),
                if (onNext != null)
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: ClayColors.deepPurple),
                    onPressed: onNext,
                    tooltip: 'Next',
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentPage != null && totalPages != null
                        ? 'Page $currentPage of $totalPages'
                        : 'Progress',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ClayColors.textMuted),
                  ),
                  Text(
                    '${displayProgress.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ClayColors.deepPurple),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

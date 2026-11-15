import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class PageNavigationSlider extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int>? onPagePreview;
  final ValueChanged<int> onPageSelected;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? textColor;

  const PageNavigationSlider({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPagePreview,
    required this.onPageSelected,
    this.activeColor,
    this.inactiveColor,
    this.textColor,
  });

  @override
  State<PageNavigationSlider> createState() => _PageNavigationSliderState();
}

class _PageNavigationSliderState extends State<PageNavigationSlider> {
  int? _previewPage;

  @override
  Widget build(BuildContext context) {
    final safeTotal = widget.totalPages < 1 ? 1 : widget.totalPages;
    final displayedPage = (_previewPage ?? widget.currentPage).clamp(1, safeTotal);

    final percentage = safeTotal == 1
        ? 100.0
        : (displayedPage / safeTotal * 100).clamp(0.0, 100.0);

    final active = widget.activeColor ?? ClayColors.deepPurple;
    final inactive = widget.inactiveColor ?? const Color(0xFFDDD2F5);
    final text = widget.textColor ?? ClayColors.deepPurple;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Page $displayedPage of $safeTotal',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textMuted,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            activeTrackColor: active,
            inactiveTrackColor: inactive,
            thumbColor: active,
            overlayColor: active.withAlpha(50),
          ),
          child: Slider(
            min: 1.0,
            max: safeTotal.toDouble(),
            divisions: (safeTotal > 1 && safeTotal <= 500) ? (safeTotal - 1) : null,
            value: displayedPage.toDouble(),
            onChanged: (value) {
              final newPage = value.round().clamp(1, safeTotal);
              setState(() {
                _previewPage = newPage;
              });
              widget.onPagePreview?.call(newPage);
            },
            onChangeEnd: (value) {
              final newPage = value.round().clamp(1, safeTotal);
              setState(() {
                _previewPage = null;
              });
              widget.onPageSelected(newPage);
            },
          ),
        ),
      ],
    );
  }
}

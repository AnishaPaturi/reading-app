import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../core/widgets/clay_components.dart';

class ReaderBottomBar extends StatefulWidget {
  final int? currentPage;
  final int? totalPages;
  final double progressPercentage;
  final ValueChanged<double>? onSeek;
  final ValueChanged<int>? onPageSelected;
  final ValueChanged<int>? onPagePreview;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const ReaderBottomBar({
    super.key,
    this.currentPage,
    this.totalPages,
    required this.progressPercentage,
    this.onSeek,
    this.onPageSelected,
    this.onPagePreview,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<ReaderBottomBar> createState() => _ReaderBottomBarState();
}

class _ReaderBottomBarState extends State<ReaderBottomBar> {
  int? _previewPage;
  double? _previewProgress;

  @override
  Widget build(BuildContext context) {
    final hasPages = widget.currentPage != null && widget.totalPages != null && widget.totalPages! > 0;
    final safeTotal = hasPages ? widget.totalPages! : 1;
    final activePage = (_previewPage ?? widget.currentPage ?? 1).clamp(1, safeTotal);

    final double displayProgress;
    if (_previewPage != null && hasPages) {
      displayProgress = (safeTotal == 1 ? 100.0 : (_previewPage! / safeTotal * 100)).clamp(0.0, 100.0);
    } else if (_previewProgress != null) {
      displayProgress = _previewProgress!.clamp(0.0, 100.0);
    } else {
      displayProgress = widget.progressPercentage.clamp(0.0, 100.0);
    }

    return PointerInterceptor(
      child: Container(
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
                  if (widget.onPrevious != null)
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: ClayColors.deepPurple),
                      onPressed: widget.onPrevious,
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
                      child: hasPages
                          ? Slider(
                              value: activePage.toDouble(),
                              min: 1.0,
                              max: safeTotal.toDouble(),
                              divisions: (safeTotal > 1 && safeTotal <= 500) ? (safeTotal - 1) : null,
                              onChanged: (value) {
                                final page = value.round().clamp(1, safeTotal);
                                setState(() {
                                  _previewPage = page;
                                });
                                widget.onPagePreview?.call(page);
                                widget.onSeek?.call((page / safeTotal * 100).clamp(0.0, 100.0));
                              },
                              onChangeEnd: (value) {
                                final page = value.round().clamp(1, safeTotal);
                                setState(() {
                                  _previewPage = null;
                                });
                                widget.onPageSelected?.call(page);
                              },
                            )
                          : Slider(
                              value: displayProgress,
                              min: 0,
                              max: 100,
                              onChanged: (value) {
                                setState(() {
                                  _previewProgress = value;
                                });
                              },
                              onChangeEnd: (value) {
                                setState(() {
                                  _previewProgress = null;
                                });
                                widget.onSeek?.call(value);
                              },
                            ),
                    ),
                  ),
                  if (widget.onNext != null)
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: ClayColors.deepPurple),
                      onPressed: widget.onNext,
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
                      hasPages
                          ? 'Page $activePage of $safeTotal'
                          : 'Progress',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    Text(
                      '${displayProgress.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

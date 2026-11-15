import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../utils/audiobook_duration_utils.dart';

class AudiobookProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;

  const AudiobookProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
  });

  @override
  State<AudiobookProgressBar> createState() => _AudiobookProgressBarState();
}

class _AudiobookProgressBarState extends State<AudiobookProgressBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = widget.activeColor ?? (isDark ? AppColors.gold : AppColors.brown);
    final background = widget.inactiveColor ??
        (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12));
    final thumb = widget.thumbColor ?? primary;

    final totalMs = widget.duration.inMilliseconds;
    final currentMs = _dragValue != null
        ? _dragValue!.toInt()
        : widget.position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);

    final progressRatio = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

    final displayedPosition = _dragValue != null
        ? Duration(milliseconds: _dragValue!.toInt())
        : widget.position;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: primary,
            inactiveTrackColor: background,
            thumbColor: thumb,
            overlayColor: primary.withOpacity(0.2),
          ),
          child: Slider(
            min: 0,
            max: totalMs > 0 ? totalMs.toDouble() : 1.0,
            value: totalMs > 0 ? currentMs.toDouble().clamp(0, totalMs.toDouble()) : 0.0,
            onChanged: (val) {
              setState(() {
                _dragValue = val;
              });
            },
            onChangeEnd: (val) {
              final target = Duration(milliseconds: val.toInt());
              _dragValue = null;
              widget.onSeek(target);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AudiobookDurationUtils.formatDuration(displayedPosition),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppColors.ivory.withOpacity(0.7) : AppColors.textDark.withOpacity(0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                AudiobookDurationUtils.formatDuration(widget.duration),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? AppColors.ivory.withOpacity(0.7) : AppColors.textDark.withOpacity(0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

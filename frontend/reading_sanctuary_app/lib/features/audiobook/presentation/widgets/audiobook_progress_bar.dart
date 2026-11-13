import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class AudiobookProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const AudiobookProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<AudiobookProgressBar> createState() => _AudiobookProgressBarState();
}

class _AudiobookProgressBarState extends State<AudiobookProgressBar> {
  double? _dragValue;

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds.toDouble();
    final currentMs = _dragValue ?? widget.position.inMilliseconds.toDouble();
    final clampedMs = totalMs > 0 ? currentMs.clamp(0.0, totalMs) : 0.0;

    final remaining = (widget.duration - widget.position);
    final remainingFormatted = remaining > Duration.zero
        ? '-${_formatDuration(remaining)}'
        : _formatDuration(Duration.zero);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: ClayColors.deepPurple,
            inactiveTrackColor: const Color(0xFFDDD2F5),
            thumbColor: ClayColors.deepPurple,
          ),
          child: Slider(
            min: 0.0,
            max: totalMs > 0 ? totalMs : 1.0,
            value: clampedMs,
            onChanged: totalMs > 0
                ? (value) {
                    setState(() {
                      _dragValue = value;
                    });
                  }
                : null,
            onChangeEnd: totalMs > 0
                ? (value) {
                    widget.onSeek(Duration(milliseconds: value.toInt()));
                    setState(() {
                      _dragValue = null;
                    });
                  }
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(
                  Duration(milliseconds: clampedMs.toInt()),
                ),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textMuted,
                ),
              ),
              Text(
                totalMs > 0 ? remainingFormatted : '--:--',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

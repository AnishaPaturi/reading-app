import 'package:flutter/material.dart';

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
    final theme = Theme.of(context);

    final remaining = (widget.duration - widget.position);
    final remainingFormatted = remaining > Duration.zero
        ? '-${_formatDuration(remaining)}'
        : _formatDuration(Duration.zero);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            thumbColor: theme.colorScheme.primary,
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(
                  Duration(milliseconds: clampedMs.toInt()),
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                totalMs > 0 ? remainingFormatted : '--:--',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

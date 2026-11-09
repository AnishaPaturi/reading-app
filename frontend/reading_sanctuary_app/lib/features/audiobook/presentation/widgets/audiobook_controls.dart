import 'package:flutter/material.dart';

class AudiobookControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipBackward;
  final VoidCallback onSkipForward;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;

  const AudiobookControls({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPause,
    required this.onSkipBackward,
    required this.onSkipForward,
    this.onPreviousChapter,
    this.onNextChapter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous chapter
        IconButton(
          iconSize: 28,
          icon: const Icon(Icons.skip_previous_rounded),
          tooltip: 'Previous Chapter',
          onPressed: onPreviousChapter,
        ),
        const SizedBox(width: 8),

        // Skip backward 15s
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.replay_10_rounded),
          tooltip: 'Rewind 15 seconds',
          onPressed: onSkipBackward,
        ),
        const SizedBox(width: 16),

        // Play / Pause / Loading
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
            boxShadow: [
              BoxShadow(
                color: primary.withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : IconButton(
                  iconSize: 40,
                  color: theme.colorScheme.onPrimary,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: onPlayPause,
                ),
        ),
        const SizedBox(width: 16),

        // Skip forward 30s
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.forward_30_rounded),
          tooltip: 'Fast Forward 30 seconds',
          onPressed: onSkipForward,
        ),
        const SizedBox(width: 8),

        // Next chapter
        IconButton(
          iconSize: 28,
          icon: const Icon(Icons.skip_next_rounded),
          tooltip: 'Next Chapter',
          onPressed: onNextChapter,
        ),
      ],
    );
  }
}

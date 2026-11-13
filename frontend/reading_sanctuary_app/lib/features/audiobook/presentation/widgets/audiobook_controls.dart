import 'package:flutter/material.dart';
import '../../../../core/widgets/clay_components.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous chapter
        IconButton(
          iconSize: 28,
          color: onPreviousChapter != null ? ClayColors.deepPurple : ClayColors.textMuted.withValues(alpha: 0.4),
          icon: const Icon(Icons.skip_previous_rounded),
          tooltip: 'Previous Chapter',
          onPressed: onPreviousChapter,
        ),
        const SizedBox(width: 8),

        // Skip backward 15s
        IconButton(
          iconSize: 32,
          color: ClayColors.deepPurple,
          icon: const Icon(Icons.replay_10_rounded),
          tooltip: 'Rewind 15 seconds',
          onPressed: onSkipBackward,
        ),
        const SizedBox(width: 16),

        // Play / Pause / Loading
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8873DA), Color(0xFF6550C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.white,
                offset: Offset(-4, -4),
                blurRadius: 10,
              ),
              BoxShadow(
                color: Color(0x4D432D56),
                offset: Offset(5, 7),
                blurRadius: 14,
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : IconButton(
                  iconSize: 40,
                  color: Colors.white,
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
          color: ClayColors.deepPurple,
          icon: const Icon(Icons.forward_30_rounded),
          tooltip: 'Fast Forward 30 seconds',
          onPressed: onSkipForward,
        ),
        const SizedBox(width: 8),

        // Next chapter
        IconButton(
          iconSize: 28,
          color: onNextChapter != null ? ClayColors.deepPurple : ClayColors.textMuted.withValues(alpha: 0.4),
          icon: const Icon(Icons.skip_next_rounded),
          tooltip: 'Next Chapter',
          onPressed: onNextChapter,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class TtsControls extends StatelessWidget {
  final bool isSpeaking;
  final bool isPaused;
  final bool isLoading;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;
  final VoidCallback onPreviousChunk;
  final VoidCallback onNextChunk;

  const TtsControls({
    super.key,
    required this.isSpeaking,
    required this.isPaused,
    required this.isLoading,
    required this.onPlayPause,
    required this.onStop,
    required this.onPreviousChunk,
    required this.onNextChunk,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop
        IconButton(
          iconSize: 26,
          icon: const Icon(Icons.stop_rounded),
          tooltip: 'Stop',
          onPressed: onStop,
        ),
        const SizedBox(width: 12),

        // Previous paragraph/chunk
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_previous_rounded),
          tooltip: 'Previous Paragraph',
          onPressed: onPreviousChunk,
        ),
        const SizedBox(width: 16),

        // Play/Pause circular button
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
            boxShadow: [
              BoxShadow(
                color: primary.withAlpha(80),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : IconButton(
                  iconSize: 38,
                  color: theme.colorScheme.onPrimary,
                  icon: Icon(
                    isSpeaking
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  tooltip: isSpeaking ? 'Pause' : 'Listen',
                  onPressed: onPlayPause,
                ),
        ),
        const SizedBox(width: 16),

        // Next paragraph/chunk
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_next_rounded),
          tooltip: 'Next Paragraph',
          onPressed: onNextChunk,
        ),
        const SizedBox(width: 12),

        // Placeholder for symmetry
        const SizedBox(width: 48),
      ],
    );
  }
}

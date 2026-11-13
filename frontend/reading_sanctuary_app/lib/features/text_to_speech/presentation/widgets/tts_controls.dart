import 'package:flutter/material.dart';
import '../../../../core/widgets/clay_components.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop
        IconButton(
          iconSize: 26,
          color: ClayColors.deepPurple,
          icon: const Icon(Icons.stop_rounded),
          tooltip: 'Stop',
          onPressed: onStop,
        ),
        const SizedBox(width: 12),

        // Previous paragraph/chunk
        IconButton(
          iconSize: 32,
          color: ClayColors.deepPurple,
          icon: const Icon(Icons.skip_previous_rounded),
          tooltip: 'Previous Paragraph',
          onPressed: onPreviousChunk,
        ),
        const SizedBox(width: 16),

        // Play/Pause circular button
        Container(
          width: 68,
          height: 68,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF8873DA), Color(0xFF6550C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white,
                offset: Offset(-3, -3),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Color(0x4D432D56),
                offset: Offset(4, 6),
                blurRadius: 14,
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
                  color: Colors.white,
                  icon: Icon(
                    isSpeaking
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  tooltip: isSpeaking ? 'Pause' : 'Play',
                  onPressed: onPlayPause,
                ),
        ),
        const SizedBox(width: 16),

        // Next paragraph/chunk
        IconButton(
          iconSize: 32,
          color: ClayColors.deepPurple,
          icon: const Icon(Icons.skip_next_rounded),
          tooltip: 'Next Paragraph',
          onPressed: onNextChunk,
        ),
      ],
    );
  }
}

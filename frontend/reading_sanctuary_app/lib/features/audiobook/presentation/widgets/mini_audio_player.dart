import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/audiobook_provider.dart';
import '../../../text_to_speech/presentation/providers/tts_provider.dart';

class MiniAudioPlayer extends ConsumerWidget {
  const MiniAudioPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audiobookProvider);
    final ttsState = ref.watch(ttsProvider);
    final theme = Theme.of(context);

    final bool isAudioActive = audioState.currentTrack != null;
    final bool isTtsActive = ttsState.document != null;

    if (!isAudioActive && !isTtsActive) {
      return const SizedBox.shrink();
    }

    final bool isAudio = isAudioActive;
    final String title = isAudio
        ? (audioState.currentTrack?.title ?? 'Audiobook')
        : (ttsState.bookTitle ?? 'Text-to-Speech');
    final String subtitle = isAudio ? 'Audiobook' : 'TTS Chapter ${ttsState.currentChapter}';
    final bool isPlaying = isAudio ? audioState.isPlaying : ttsState.isSpeaking;

    final double progress = isAudio
        ? (audioState.duration.inMilliseconds > 0
            ? (audioState.position.inMilliseconds /
                    audioState.duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0)
        : (ttsState.progressPercentage / 100.0).clamp(0.0, 1.0);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: InkWell(
        onTap: () {
          if (isAudio && audioState.currentTrack != null) {
            final track = audioState.currentTrack!;
            context.push('/listen/${track.bookId}/${track.fileId}');
          } else if (!isAudio && ttsState.bookId != null && ttsState.fileId != null) {
            context.push('/listen/${ttsState.bookId}/${ttsState.fileId}?mode=tts');
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linear Progress Indicator
            LinearProgressIndicator(
              value: progress,
              minHeight: 2.5,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isAudio ? Icons.headphones_rounded : Icons.record_voice_over_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      size: 34,
                      color: theme.colorScheme.primary,
                    ),
                    onPressed: () {
                      if (isAudio) {
                        ref.read(audiobookProvider.notifier).togglePlayPause();
                      } else {
                        if (isPlaying) {
                          ref.read(ttsProvider.notifier).pause();
                        } else {
                          ref.read(ttsProvider.notifier).play();
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      if (isAudio) {
                        ref.read(audiobookProvider.notifier).stop();
                      } else {
                        ref.read(ttsProvider.notifier).stop();
                      }
                    },
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

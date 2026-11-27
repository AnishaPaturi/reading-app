import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/audiobook_providers.dart';
import 'audiobook_cover.dart';

class MiniAudiobookPlayer extends ConsumerWidget {
  const MiniAudiobookPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackService = ref.watch(audiobookPlaybackServiceProvider);
    final currentBook = playbackService.currentBook;
    final handler = playbackService.handler;

    if (currentBook == null || handler == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    return StreamBuilder<bool>(
      stream: handler.player.playingStream,
      initialData: handler.player.playing,
      builder: (context, playingSnap) {
        final isPlaying = playingSnap.data ?? false;

        return StreamBuilder<Duration>(
          stream: handler.player.positionStream,
          initialData: handler.player.position,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = handler.player.duration ?? Duration.zero;
            final totalMs = duration.inMilliseconds;
            final progress = totalMs > 0
                ? (position.inMilliseconds / totalMs).clamp(0.0, 1.0)
                : 0.0;

            final currentTrack = playbackService.currentTrack;

            return Material(
              elevation: 8,
              color: isDark ? const Color(0xFF1E140F) : AppColors.parchment,
              child: InkWell(
                onTap: () {
                  context.push('/audiobooks/${currentBook.id}/player');
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 2.5,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          AudiobookCover(
                            coverPath: currentBook.coverPath,
                            title: currentBook.title,
                            author: currentBook.author,
                            width: 42,
                            height: 42,
                            borderRadius: 6,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentBook.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.ivory : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  currentTrack?.chapterTitle ?? currentBook.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: isDark ? AppColors.gold.withValues(alpha: 0.8) : AppColors.brown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, size: 22),
                            tooltip: 'Rewind 15s',
                            color: isDark ? AppColors.ivory : AppColors.textDark,
                            onPressed: () => playbackService.skipBackward(),
                          ),
                          IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                              size: 34,
                              color: primary,
                            ),
                            tooltip: isPlaying ? 'Pause' : 'Play',
                            onPressed: () {
                              if (isPlaying) {
                                playbackService.pause();
                              } else {
                                playbackService.play();
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
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/audio_chapter.dart';
import '../../data/models/audio_track.dart';
import '../providers/audiobook_provider.dart';
import '../widgets/audiobook_chapter_list.dart';
import '../widgets/audiobook_controls.dart';
import '../widgets/audiobook_progress_bar.dart';
import '../widgets/audiobook_sleep_timer.dart';
import '../widgets/audiobook_speed_selector.dart';
import '../../../text_to_speech/presentation/screens/tts_screen.dart';

class AudiobookScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String fileId;
  final String? bookTitle;
  final String? author;
  final String? format;
  final bool isTtsMode;

  const AudiobookScreen({
    super.key,
    required this.bookId,
    required this.fileId,
    this.bookTitle,
    this.author,
    this.format,
    this.isTtsMode = false,
  });

  @override
  ConsumerState<AudiobookScreen> createState() => _AudiobookScreenState();
}

class _AudiobookScreenState extends ConsumerState<AudiobookScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.isTtsMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAudioTrack();
      });
    }
  }

  void _loadAudioTrack() {
    final track = AudioTrack(
      id: widget.fileId,
      bookId: widget.bookId,
      fileId: widget.fileId,
      title: widget.bookTitle ?? 'Audiobook',
      format: widget.format ?? 'MP3',
      fileSizeBytes: 0,
      author: widget.author,
    );

    ref.read(audiobookProvider.notifier).loadAudio(
          track: track,
          autoPlay: false,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isTtsMode) {
      return TtsScreen(
        bookId: widget.bookId,
        fileId: widget.fileId,
        bookTitle: widget.bookTitle,
      );
    }

    final audioState = ref.watch(audiobookProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          tooltip: 'Minimize Player',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.bookTitle ?? audioState.currentTrack?.title ?? 'Audiobook',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: audioState.sleepTimerRemaining != null ||
                  audioState.sleepTimerEndOfChapter,
              child: const Icon(Icons.bedtime_outlined),
            ),
            tooltip: 'Sleep Timer',
            onPressed: () {
              AudiobookSleepTimerSheet.show(
                context,
                remainingTime: audioState.sleepTimerRemaining,
                endOfChapter: audioState.sleepTimerEndOfChapter,
                onTimerSelected: (duration, {endOfChapter = false}) {
                  ref
                      .read(audiobookProvider.notifier)
                      .setSleepTimer(duration, endOfChapter: endOfChapter);
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return audioState.errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            audioState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.tonal(
                            onPressed: _loadAudioTrack,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(),

                        // Artwork / Cover card
                        _buildArtworkCard(context, isLandscape ? 160 : 260),

                        const SizedBox(height: 24),

                        // Title and Author
                        Text(
                          widget.bookTitle ??
                              audioState.currentTrack?.title ??
                              'Audiobook Track',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.author ??
                              audioState.currentTrack?.author ??
                              'Reading Sanctuary',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),

                        // Current Chapter title if present
                        if (audioState.currentChapter != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            audioState.currentChapter!.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Progress Bar
                        AudiobookProgressBar(
                          position: audioState.position,
                          duration: audioState.duration,
                          onSeek: (pos) {
                            ref.read(audiobookProvider.notifier).seek(pos);
                          },
                        ),

                        const SizedBox(height: 12),

                        // Controls
                        AudiobookControls(
                          isPlaying: audioState.isPlaying,
                          isLoading: audioState.isLoading,
                          onPlayPause: () {
                            ref
                                .read(audiobookProvider.notifier)
                                .togglePlayPause();
                          },
                          onSkipBackward: () {
                            ref.read(audiobookProvider.notifier).skipBackward();
                          },
                          onSkipForward: () {
                            ref.read(audiobookProvider.notifier).skipForward();
                          },
                          onPreviousChapter: audioState.chapters.isNotEmpty
                              ? () {
                                  ref
                                      .read(audiobookProvider.notifier)
                                      .playPreviousChapter();
                                }
                              : null,
                          onNextChapter: audioState.chapters.isNotEmpty
                              ? () {
                                  ref
                                      .read(audiobookProvider.notifier)
                                      .playNextChapter();
                                }
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // Bottom Actions: Speed & Chapters
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Playback Speed
                            TextButton.icon(
                              icon: const Icon(Icons.speed_rounded, size: 20),
                              label: Text('${audioState.playbackSpeed}x'),
                              onPressed: () {
                                AudiobookSpeedSelector.show(
                                  context,
                                  currentSpeed: audioState.playbackSpeed,
                                  onSpeedSelected: (spd) {
                                    ref
                                        .read(audiobookProvider.notifier)
                                        .setSpeed(spd);
                                  },
                                );
                              },
                            ),

                            // Chapter selector (if chapters available)
                            TextButton.icon(
                              icon: const Icon(Icons.list_rounded, size: 20),
                              label: Text(
                                audioState.chapters.isNotEmpty
                                    ? 'Chapters (${audioState.chapters.length})'
                                    : 'Chapters',
                              ),
                              onPressed: () {
                                AudiobookChapterListSheet.show(
                                  context,
                                  chapters: audioState.chapters,
                                  currentChapterIndex:
                                      audioState.currentChapterIndex,
                                  onChapterSelected: (idx) {
                                    ref
                                        .read(audiobookProvider.notifier)
                                        .playChapter(idx);
                                  },
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _buildArtworkCard(BuildContext context, double size) {
    final theme = Theme.of(context);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.headphones_rounded,
              size: size * 0.35,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withAlpha(160),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.format?.toUpperCase() ?? 'AUDIO',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

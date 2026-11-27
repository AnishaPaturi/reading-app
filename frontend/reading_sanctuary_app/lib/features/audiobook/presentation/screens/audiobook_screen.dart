import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/audio_track.dart';
import '../providers/audiobook_provider.dart';
import '../widgets/audiobook_chapter_list.dart';
import '../widgets/audiobook_sleep_timer.dart';
import '../widgets/audiobook_speed_selector.dart';
import '../widgets/clay_audio_player_view.dart';
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

    if (audioState.errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFDDD7F7),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: ClayColors.coral,
                ),
                const SizedBox(height: 16),
                Text(
                  audioState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: ClayColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadAudioTrack,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClayColors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentTitle = widget.bookTitle ??
        audioState.currentTrack?.title ??
        'The Silent Patient';
    final currentAuthor = widget.author ??
        audioState.currentTrack?.author ??
        'Alex Michaelides';
    final chapterTitle = audioState.currentChapter?.title ??
        (audioState.chapters.isNotEmpty
            ? 'Chapter ${(audioState.currentChapterIndex + 1).toString().padLeft(2, '0')}'
            : 'Chapter 08');

    return Scaffold(
      body: ClayAudioPlayerView(
        title: currentTitle,
        author: currentAuthor,
        chapterTitle: chapterTitle,
        position: audioState.position,
        duration: audioState.duration,
        isPlaying: audioState.isPlaying,
        isLoading: audioState.isLoading,
        playbackSpeed: audioState.playbackSpeed,
        silenceSkipping: false,
        isSleepTimerActive: audioState.sleepTimerRemaining != null ||
            audioState.sleepTimerEndOfChapter,
        sleepTimerRemaining: audioState.sleepTimerRemaining,
        onBack: () => Navigator.of(context).maybePop(),
        onOptions: () => _showMoreOptionsSheet(context),
        onPlayPause: () {
          ref.read(audiobookProvider.notifier).togglePlayPause();
        },
        onRewind15: () {
          ref.read(audiobookProvider.notifier).skipBackward();
        },
        onForward30: () {
          ref.read(audiobookProvider.notifier).skipForward();
        },
        onSeek: (pos) {
          ref.read(audiobookProvider.notifier).seek(pos);
        },
        onChapters: () {
          AudiobookChapterListSheet.show(
            context,
            chapters: audioState.chapters,
            currentChapterIndex: audioState.currentChapterIndex,
            onChapterSelected: (idx) {
              ref.read(audiobookProvider.notifier).playChapter(idx);
            },
          );
        },
        onSleepTimer: () {
          AudiobookSleepTimerSheet.show(
            context,
            remainingTime: audioState.sleepTimerRemaining,
            endOfChapter: audioState.sleepTimerEndOfChapter,
            onTimerSelected: (duration, {endOfChapter = false}) {
              ref.read(audiobookProvider.notifier).setSleepTimer(
                    duration,
                    endOfChapter: endOfChapter,
                  );
            },
          );
        },
        onBookmark: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Position bookmarked')),
          );
        },
        onSpeed: () {
          AudiobookSpeedSelector.show(
            context,
            currentSpeed: audioState.playbackSpeed,
            onSpeedSelected: (spd) {
              ref.read(audiobookProvider.notifier).setSpeed(spd);
            },
          );
        },
        onToggleSilence: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Silence skipping: ON')),
          );
        },
      ),
    );
  }

  void _showMoreOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Track Details'),
              subtitle: Text(widget.bookTitle ?? 'Audiobook'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border_rounded),
              title: const Text('Bookmark current position'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Position bookmarked')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

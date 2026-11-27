import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/audiobook.dart';
import '../providers/audiobook_providers.dart';
import '../widgets/chapter_list.dart';
import '../widgets/sleep_timer_sheet.dart';
import '../widgets/bookmark_dialog.dart';
import '../widgets/clay_audio_player_view.dart';
import '../../services/audiobook_playback_service.dart';

class AudiobookPlayerPage extends ConsumerStatefulWidget {
  final String audiobookId;

  const AudiobookPlayerPage({
    super.key,
    required this.audiobookId,
  });

  @override
  ConsumerState<AudiobookPlayerPage> createState() => _AudiobookPlayerPageState();
}

class _AudiobookPlayerPageState extends ConsumerState<AudiobookPlayerPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureBookLoaded();
    });
  }

  Future<void> _ensureBookLoaded() async {
    final playbackService = ref.read(audiobookPlaybackServiceProvider);
    if (playbackService.currentBook?.id != widget.audiobookId) {
      final localDb = ref.read(audiobookLocalDatasourceProvider);
      await localDb.init();
      final book = localDb.getAudiobook(widget.audiobookId);
      if (book != null) {
        await playbackService.loadAudiobook(book: book, autoPlay: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playbackService = ref.watch(audiobookPlaybackServiceProvider);
    final book = playbackService.currentBook;
    final handler = playbackService.handler;

    if (book == null || handler == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFDDD7F7),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4C2DB8),
          ),
        ),
      );
    }

    final currentTrack = playbackService.currentTrack;
    final tracks = playbackService.tracks;
    final chapters = playbackService.chapters;

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
            final duration = handler.player.duration ??
                Duration(milliseconds: currentTrack?.durationMs ?? 0);

            final chapterTitle = currentTrack?.chapterTitle ??
                (tracks.length > 1
                    ? 'Chapter ${(playbackService.currentTrackIndex + 1).toString().padLeft(2, '0')}'
                    : (book.title.isNotEmpty ? book.title : 'Chapter 08'));

            return Scaffold(
              body: ClayAudioPlayerView(
                title: book.title,
                author: book.author,
                coverPath: book.coverPath,
                chapterTitle: chapterTitle,
                position: position,
                duration: duration,
                isPlaying: isPlaying,
                playbackSpeed: playbackService.settings.playbackSpeed,
                silenceSkipping: playbackService.settings.silenceSkipping,
                isSleepTimerActive: playbackService.sleepTimer.isActive,
                sleepTimerRemaining: playbackService.sleepTimer.remaining,
                onBack: () => Navigator.pop(context),
                onOptions: () => _showMoreOptions(context, book),
                onPlayPause: () {
                  if (isPlaying) {
                    playbackService.pause();
                  } else {
                    playbackService.play();
                  }
                },
                onRewind15: () => playbackService.skipBackward(),
                onForward30: () => playbackService.skipForward(),
                onSeek: (target) => playbackService.seek(target),
                onChapters: () => _showChaptersSheet(context, playbackService, chapters),
                onSleepTimer: () => _showSleepTimerSheet(context, playbackService),
                onBookmark: () => _showBookmarkDialog(context, book, currentTrack, position),
                onSpeed: () => _showSpeedSelector(context, playbackService),
                onToggleSilence: () {
                  final cur = playbackService.settings.silenceSkipping;
                  playbackService.setSilenceSkipping(!cur);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showSpeedSelector(BuildContext context, AudiobookPlaybackService playback) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Playback Speed',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              ...speeds.map((s) => ListTile(
                    title: Text('${s}x', textAlign: TextAlign.center),
                    selected: playback.settings.playbackSpeed == s,
                    onTap: () {
                      playback.setSpeed(s);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showChaptersSheet(
    BuildContext context,
    AudiobookPlaybackService playback,
    List<dynamic> chapters,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChapterListSheet(
        chapters: playback.chapters,
        activeChapterIndex: playback.currentTrackIndex,
        stopAtChapterEnd: playback.settings.stopAtChapterEnd,
        onSelectChapter: (idx) => playback.skipToTrack(idx),
        onToggleStopAtChapterEnd: (val) => playback.setStopAtChapterEnd(val),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, AudiobookPlaybackService playback) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SleepTimerSheet(
        sleepTimer: playback.sleepTimer,
        onTimerStarted: () => setState(() {}),
      ),
    );
  }

  void _showBookmarkDialog(
    BuildContext context,
    Audiobook book,
    dynamic currentTrack,
    Duration position,
  ) {
    showDialog(
      context: context,
      builder: (context) => BookmarkDialog(
        position: position,
        chapterTitle: currentTrack?.chapterTitle ?? currentTrack?.fileName,
        onSave: (title, note, category, isFav) {
          final bookmarkService = ref.read(audiobookBookmarkServiceProvider);
          bookmarkService.createBookmark(
            audiobookId: book.id,
            trackId: currentTrack?.id,
            trackIndex: ref.read(audiobookPlaybackServiceProvider).currentTrackIndex,
            positionMs: position.inMilliseconds,
            title: title,
            note: note,
            category: category,
            isFavorite: isFav,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bookmark saved!')),
          );
        },
      ),
    );
  }

  void _showMoreOptions(BuildContext context, Audiobook book) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Audiobook Details'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/audiobooks/${book.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border_rounded),
                title: const Text('Saved Bookmarks'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/audiobooks/bookmarks');
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Listening History'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/audiobooks/history');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/audiobook.dart';
import '../providers/audiobook_providers.dart';
import '../widgets/audiobook_cover.dart';
import '../widgets/audiobook_progress_bar.dart';
import '../widgets/audiobook_player_controls.dart';
import '../widgets/chapter_list.dart';
import '../widgets/sleep_timer_sheet.dart';
import '../widgets/bookmark_dialog.dart';
import '../../services/audiobook_artwork_service.dart';

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

    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    // Check night appearance mode (from sleep timer)
    final isNightMode = ref.watch(audiobookNightAppearanceProvider).valueOrNull ??
        playbackService.settings.nightAppearance;

    // Extract dynamic palette from cover
    final paletteAsync = ref.watch(audiobookPaletteProvider(book?.coverPath));
    final palette = paletteAsync.valueOrNull ?? ArtworkPalette.defaultPalette;

    // Pick accent color (Dynamic cover accent or custom setting or default gold/brown)
    final accent = isNightMode
        ? const Color(0xFFD4AF37)
        : (playbackService.settings.customAccentColor != null
            ? Color(playbackService.settings.customAccentColor!)
            : palette.vibrantColor);

    final bgColor = isNightMode
        ? const Color(0xFF0A0705)
        : (isDarkTheme ? AppColors.espresso : AppColors.ivory);

    final textPrimary = isNightMode
        ? const Color(0xFFEDE8D0)
        : (isDarkTheme ? AppColors.ivory : AppColors.textDark);

    if (book == null || handler == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentTrack = playbackService.currentTrack;
    final tracks = playbackService.tracks;
    final chapters = playbackService.chapters;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 30, color: textPrimary),
          tooltip: 'Minimize',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NOW PLAYING',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: accent,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isNightMode ? Icons.light_mode_outlined : Icons.nightlight_outlined,
              color: textPrimary,
            ),
            tooltip: 'Night appearance',
            onPressed: () {
              final newMode = !playbackService.settings.nightAppearance;
              playbackService.sleepTimer.startDurationTimer(
                const Duration(minutes: 30),
                enableNightAppearance: newMode,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: textPrimary),
            tooltip: 'Options',
            onPressed: () => _showMoreOptions(context, book),
          ),
        ],
      ),
      body: StreamBuilder<bool>(
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

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      const Spacer(),

                      // Animated Cover with Dynamic Ambient Glow
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isNightMode
                                ? []
                                : [
                                    BoxShadow(
                                      color: accent.withOpacity(0.35),
                                      blurRadius: 32,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: AudiobookCover(
                            coverPath: book.coverPath,
                            title: book.title,
                            author: book.author,
                            width: MediaQuery.of(context).size.width * 0.65,
                            height: MediaQuery.of(context).size.width * 0.65,
                            borderRadius: 16,
                            showShadow: false,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Book Title & Author
                      Text(
                        book.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.author,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: accent.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      // Chapter Indicator
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkTheme ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          currentTrack?.chapterTitle ?? 'Track ${playbackService.currentTrackIndex + 1} of ${tracks.length}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary.withOpacity(0.8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Progress Bar
                      AudiobookProgressBar(
                        position: position,
                        duration: duration,
                        activeColor: accent,
                        thumbColor: accent,
                        onSeek: (target) => playbackService.seek(target),
                      ),

                      const SizedBox(height: 14),

                      // Player Controls
                      AudiobookPlayerControls(
                        isPlaying: isPlaying,
                        hasPrevious: playbackService.currentTrackIndex > 0 || handler.player.hasPrevious,
                        hasNext: playbackService.currentTrackIndex < tracks.length - 1 || handler.player.hasNext,
                        playbackSpeed: playbackService.settings.playbackSpeed,
                        silenceSkipping: playbackService.settings.silenceSkipping,
                        volumeBoost: playbackService.settings.volumeBoost,
                        isSleepTimerActive: playbackService.sleepTimer.isActive,
                        sleepTimerRemaining: playbackService.sleepTimer.remaining,
                        accentColor: accent,
                        onPlayPause: () {
                          if (isPlaying) {
                            playbackService.pause();
                          } else {
                            playbackService.play();
                          }
                        },
                        onRewind: () => playbackService.skipBackward(),
                        onFastForward: () => playbackService.skipForward(),
                        onPreviousTrack: () => playbackService.skipToPreviousTrack(),
                        onNextTrack: () => playbackService.skipToNextTrack(),
                        onSpeedPressed: () => _showSpeedSelector(context, playbackService),
                        onChaptersPressed: () => _showChaptersSheet(context, playbackService, chapters),
                        onSleepTimerPressed: () => _showSleepTimerSheet(context, playbackService),
                        onBookmarkPressed: () => _showBookmarkDialog(context, book, currentTrack, position),
                        onSilenceSkippingToggled: (val) => playbackService.setSilenceSkipping(val),
                        onVolumeBoostToggled: (val) => playbackService.setVolumeBoost(val),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
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
                  style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700),
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

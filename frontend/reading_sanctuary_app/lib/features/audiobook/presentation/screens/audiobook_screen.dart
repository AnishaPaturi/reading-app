import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32, color: ClayColors.deepPurple),
          tooltip: 'Minimize Player',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.bookTitle ?? audioState.currentTrack?.title ?? 'Audiobook',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: ClayColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: audioState.sleepTimerRemaining != null ||
                  audioState.sleepTimerEndOfChapter,
              backgroundColor: ClayColors.coral,
              child: const Icon(Icons.bedtime_outlined, color: ClayColors.deepPurple),
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

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: audioState.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 48, color: ClayColors.coral),
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const Spacer(),

                              // Artwork / Cover card
                              _buildArtworkCard(
                                  context, isLandscape ? 160 : 250),

                              const SizedBox(height: 24),

                              // Title and Author
                              Text(
                                widget.bookTitle ??
                                    audioState.currentTrack?.title ??
                                    'Audiobook Track',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: ClayColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.author ??
                                    audioState.currentTrack?.author ??
                                    'Reading Sanctuary',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: ClayColors.textMuted,
                                ),
                              ),

                              // Current Chapter title if present
                              if (audioState.currentChapter != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF7FE),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFDDD2F5)),
                                  ),
                                  child: Text(
                                    audioState.currentChapter!.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: ClayColors.deepPurple,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                    ),
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
                                  ref
                                      .read(audiobookProvider.notifier)
                                      .skipBackward();
                                },
                                onSkipForward: () {
                                  ref
                                      .read(audiobookProvider.notifier)
                                      .skipForward();
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

                              const SizedBox(height: 20),

                              // Bottom Actions: Speed & Chapters
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Playback Speed
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.speed_rounded, size: 18, color: ClayColors.deepPurple),
                                    label: Text(
                                      '${audioState.playbackSpeed}x',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: ClayColors.textDark,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: const BorderSide(color: Color(0xFFDDD2F5)),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    ),
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
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.list_rounded, size: 18, color: ClayColors.deepPurple),
                                    label: Text(
                                      audioState.chapters.isNotEmpty
                                          ? 'Chapters (${audioState.chapters.length})'
                                          : 'Chapters',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: ClayColors.textDark,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: const BorderSide(color: Color(0xFFDDD2F5)),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildArtworkCard(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-8, -8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0x336B599C),
            offset: Offset(8, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size * 0.44,
              height: size * 0.44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFB5A7F2), Color(0xFF9482E6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x286550C7),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.headphones_rounded,
                size: size * 0.25,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDD2F5)),
              ),
              child: Text(
                widget.format?.toUpperCase() ?? 'AUDIO',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: ClayColors.deepPurple,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

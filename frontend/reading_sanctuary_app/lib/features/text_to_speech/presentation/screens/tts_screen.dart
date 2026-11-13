import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../providers/tts_provider.dart';
import '../widgets/tts_controls.dart';
import '../widgets/tts_settings_panel.dart';
import '../widgets/tts_text_display.dart';

class TtsScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String fileId;
  final String? bookTitle;
  final int initialChapter;

  const TtsScreen({
    super.key,
    required this.bookId,
    required this.fileId,
    this.bookTitle,
    this.initialChapter = 1,
  });

  @override
  ConsumerState<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends ConsumerState<TtsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ttsProvider.notifier).loadDocument(
            bookId: widget.bookId,
            fileId: widget.fileId,
            bookTitle: widget.bookTitle,
            initialChapter: widget.initialChapter,
            autoPlay: false,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ttsState = ref.watch(ttsProvider);

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.deepPurple),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          widget.bookTitle ?? ttsState.bookTitle ?? 'Text-to-Speech',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: ClayColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: ClayColors.deepPurple),
            tooltip: 'TTS Settings',
            onPressed: () {
              TtsSettingsPanel.show(
                context,
                speechRate: ttsState.speechRate,
                pitch: ttsState.pitch,
                selectedVoice: ttsState.selectedVoice,
                availableVoices: ttsState.availableVoices,
                onSpeechRateChanged: (rate) {
                  ref.read(ttsProvider.notifier).setSpeechRate(rate);
                },
                onPitchChanged: (pitch) {
                  ref.read(ttsProvider.notifier).setPitch(pitch);
                },
                onVoiceChanged: (voice) {
                  ref.read(ttsProvider.notifier).setVoice(voice);
                },
              );
            },
          ),
        ],
      ),
      body: ttsState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ClayColors.deepPurple),
            )
          : ttsState.errorMessage != null
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
                          ttsState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: ClayColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(ttsProvider.notifier).loadDocument(
                                  bookId: widget.bookId,
                                  fileId: widget.fileId,
                                  bookTitle: widget.bookTitle,
                                  initialChapter: widget.initialChapter,
                                );
                          },
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
              : SafeArea(
                  child: Column(
                    children: [
                      // Linear progress across document
                      LinearProgressIndicator(
                        value: (ttsState.progressPercentage / 100.0)
                            .clamp(0.0, 1.0),
                        backgroundColor: const Color(0xFFDDD2F5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            ClayColors.deepPurple),
                      ),
                      const SizedBox(height: 16),

                      // Text Display
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TtsTextDisplay(
                            text: ttsState.currentChunkText,
                            spokenWord: ttsState.currentSpokenWord,
                            currentChunk: ttsState.currentChunk,
                            totalChunks: ttsState.totalChunks,
                            currentChapter: ttsState.currentChapter,
                          ),
                        ),
                      ),

                      // Controls
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 24, horizontal: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x286B599C),
                              blurRadius: 16,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TtsControls(
                              isSpeaking: ttsState.isSpeaking,
                              isPaused: ttsState.isPaused,
                              isLoading: ttsState.isLoading,
                              onPlayPause: () {
                                if (ttsState.isSpeaking) {
                                  ref.read(ttsProvider.notifier).pause();
                                } else {
                                  ref.read(ttsProvider.notifier).play();
                                }
                              },
                              onStop: () {
                                ref.read(ttsProvider.notifier).stop();
                              },
                              onPreviousChunk: () {
                                ref.read(ttsProvider.notifier).previousChunk();
                              },
                              onNextChunk: () {
                                ref.read(ttsProvider.notifier).nextChunk();
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

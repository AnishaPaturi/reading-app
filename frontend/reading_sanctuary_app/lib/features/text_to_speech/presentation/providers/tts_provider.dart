import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tts_document.dart';
import '../../data/repositories/tts_repository.dart';
import '../../data/services/tts_service.dart';
import '../../../reader/presentation/providers/reader_provider.dart';
import '../../../analytics/application/analytics_providers.dart';
import '../../../analytics/data/models/activity_session.dart';

final ttsRepositoryProvider = Provider<TtsRepository>((ref) {
  return HttpTtsRepository(
    tokenProvider: () => ref.read(authTokenProvider),
  );
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

class TtsState {
  final String? bookId;
  final String? fileId;
  final String? bookTitle;
  final TtsDocument? document;
  final bool isSpeaking;
  final bool isPaused;
  final bool isLoading;
  final int currentChapter;
  final int currentChunk;
  final int characterOffset;
  final int totalChunks;
  final double progressPercentage;
  final Map<String, String>? selectedVoice;
  final List<Map<String, String>> availableVoices;
  final double speechRate;
  final double pitch;
  final String? currentSpokenWord;
  final String? errorMessage;

  const TtsState({
    this.bookId,
    this.fileId,
    this.bookTitle,
    this.document,
    this.isSpeaking = false,
    this.isPaused = false,
    this.isLoading = false,
    this.currentChapter = 1,
    this.currentChunk = 0,
    this.characterOffset = 0,
    this.totalChunks = 0,
    this.progressPercentage = 0.0,
    this.selectedVoice,
    this.availableVoices = const [],
    this.speechRate = 1.0,
    this.pitch = 1.0,
    this.currentSpokenWord,
    this.errorMessage,
  });

  String get currentChunkText {
    if (document != null &&
        currentChunk >= 0 &&
        currentChunk < document!.chunks.length) {
      return document!.chunks[currentChunk].text;
    }
    return '';
  }

  TtsState copyWith({
    String? bookId,
    String? fileId,
    String? bookTitle,
    TtsDocument? document,
    bool? isSpeaking,
    bool? isPaused,
    bool? isLoading,
    int? currentChapter,
    int? currentChunk,
    int? characterOffset,
    int? totalChunks,
    double? progressPercentage,
    Map<String, String>? selectedVoice,
    List<Map<String, String>>? availableVoices,
    double? speechRate,
    double? pitch,
    String? currentSpokenWord,
    bool clearSpokenWord = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TtsState(
      bookId: bookId ?? this.bookId,
      fileId: fileId ?? this.fileId,
      bookTitle: bookTitle ?? this.bookTitle,
      document: document ?? this.document,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isPaused: isPaused ?? this.isPaused,
      isLoading: isLoading ?? this.isLoading,
      currentChapter: currentChapter ?? this.currentChapter,
      currentChunk: currentChunk ?? this.currentChunk,
      characterOffset: characterOffset ?? this.characterOffset,
      totalChunks: totalChunks ?? this.totalChunks,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      selectedVoice: selectedVoice ?? this.selectedVoice,
      availableVoices: availableVoices ?? this.availableVoices,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      currentSpokenWord: clearSpokenWord
          ? null
          : (currentSpokenWord ?? this.currentSpokenWord),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TtsNotifier extends StateNotifier<TtsState> {
  final TtsService _ttsService;
  final TtsRepository _repository;
  final Ref? _ref;
  Timer? _debounceSaveTimer;

  TtsNotifier({
    required TtsService ttsService,
    required TtsRepository repository,
    Ref? ref,
  })  : _ttsService = ttsService,
        _repository = repository,
        _ref = ref,
        super(const TtsState()) {
    _initTts();
  }

  Future<void> _initTts() async {
    await _ttsService.initialize();

    _ttsService.onStart = () {
      state = state.copyWith(isSpeaking: true, isPaused: false);
    };

    _ttsService.onComplete = () {
      _handleChunkComplete();
    };

    _ttsService.onProgress = (progress) {
      state = state.copyWith(
        characterOffset: progress.start,
        currentSpokenWord: progress.word,
      );
    };

    _ttsService.onError = (message) {
      debugPrint('TTS runtime error: $message');
      state = state.copyWith(
        isSpeaking: false,
        isPaused: true,
        errorMessage: message,
      );
    };

    final voices = await _ttsService.getVoices();
    state = state.copyWith(availableVoices: voices);
  }

  Future<void> loadDocument({
    required String bookId,
    required String fileId,
    String? bookTitle,
    int? initialChapter,
    bool autoPlay = false,
  }) async {
    state = state.copyWith(
      bookId: bookId,
      fileId: fileId,
      bookTitle: bookTitle,
      isLoading: true,
      clearError: true,
    );

    try {
      // Restore saved position
      final savedPos = await _repository.getPosition(
        bookId: bookId,
        fileId: fileId,
      );

      final chapterToLoad = initialChapter ??
          (savedPos != null ? savedPos.chapterIndex : 1);
      final chunkToRestore = savedPos != null ? savedPos.chunkIndex : 0;
      final offsetToRestore = savedPos != null ? savedPos.characterOffset : 0;
      final progressToRestore =
          savedPos != null ? savedPos.progressPercentage : 0.0;

      final doc = await _repository.extractText(
        bookId: bookId,
        fileId: fileId,
        chapter: chapterToLoad,
      );

      state = state.copyWith(
        document: doc,
        isLoading: false,
        currentChapter: chapterToLoad,
        currentChunk: (chunkToRestore < doc.chunks.length) ? chunkToRestore : 0,
        characterOffset: offsetToRestore,
        totalChunks: doc.chunks.length,
        progressPercentage: progressToRestore,
      );

      if (autoPlay && doc.chunks.isNotEmpty) {
        await play();
      }
    } catch (e) {
      debugPrint('Error loading document for TTS: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load document text: $e',
      );
    }
  }

  Future<void> play() async {
    final text = state.currentChunkText;
    if (text.trim().isEmpty) return;

    state = state.copyWith(isSpeaking: true, isPaused: false);
    _ref?.read(activityTrackingServiceProvider).startSession(
          activityType: ActivityType.TTS,
          bookId: state.bookId,
          bookFileId: state.fileId,
          startingLocation: 'chapter=${state.currentChapter},chunk=${state.currentChunk}',
          playbackSpeed: state.speechRate,
        );
    await _ttsService.speak(text);
  }

  Future<void> pause() async {
    await _ttsService.pause();
    state = state.copyWith(isSpeaking: false, isPaused: true);
    _ref?.read(activityTrackingServiceProvider).closeSession();
    await savePosition();
  }

  Future<void> resume() async {
    if (state.isPaused) {
      await play();
    }
  }

  Future<void> stop() async {
    await _ttsService.stop();
    state = state.copyWith(
      isSpeaking: false,
      isPaused: false,
      clearSpokenWord: true,
    );
    _ref?.read(activityTrackingServiceProvider).closeSession();
    await savePosition();
  }
    );
    await savePosition();
  }

  Future<void> nextChunk() async {
    await _ttsService.stop();
    final doc = state.document;
    if (doc == null) return;

    if (state.currentChunk + 1 < doc.chunks.length) {
      final next = state.currentChunk + 1;
      _updateChunkProgress(next, doc.chunks.length);
      state = state.copyWith(currentChunk: next, characterOffset: 0);
      if (state.isSpeaking) {
        await play();
      }
      await savePosition();
    } else if (doc.hasNextChapter) {
      // Advance to next chapter
      await _loadChapter(state.currentChapter + 1, autoStart: state.isSpeaking);
    } else {
      // Finished document
      state = state.copyWith(
        isSpeaking: false,
        isPaused: false,
        progressPercentage: 100.0,
      );
      await savePosition();
    }
  }

  Future<void> previousChunk() async {
    await _ttsService.stop();
    if (state.currentChunk > 0) {
      final prev = state.currentChunk - 1;
      final total = state.totalChunks;
      _updateChunkProgress(prev, total);
      state = state.copyWith(currentChunk: prev, characterOffset: 0);
      if (state.isSpeaking) {
        await play();
      }
      await savePosition();
    } else if (state.currentChapter > 1) {
      // Previous chapter
      await _loadChapter(state.currentChapter - 1, autoStart: state.isSpeaking);
    }
  }

  Future<void> _handleChunkComplete() async {
    final doc = state.document;
    if (doc == null) return;

    if (state.currentChunk + 1 < doc.chunks.length) {
      final next = state.currentChunk + 1;
      _updateChunkProgress(next, doc.chunks.length);
      state = state.copyWith(currentChunk: next, characterOffset: 0);
      await play();
      _scheduleSavePosition();
    } else if (doc.hasNextChapter) {
      await _loadChapter(state.currentChapter + 1, autoStart: true);
    } else {
      state = state.copyWith(
        isSpeaking: false,
        isPaused: false,
        progressPercentage: 100.0,
      );
      await savePosition();
    }
  }

  Future<void> _loadChapter(int chapter, {bool autoStart = false}) async {
    final bookId = state.bookId;
    final fileId = state.fileId;
    if (bookId == null || fileId == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final doc = await _repository.extractText(
        bookId: bookId,
        fileId: fileId,
        chapter: chapter,
      );
      state = state.copyWith(
        document: doc,
        isLoading: false,
        currentChapter: chapter,
        currentChunk: 0,
        characterOffset: 0,
        totalChunks: doc.chunks.length,
      );
      if (autoStart && doc.chunks.isNotEmpty) {
        await play();
      }
      await savePosition();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load chapter: $e',
      );
    }
  }

  void _updateChunkProgress(int chunkIndex, int totalChunks) {
    if (totalChunks <= 0) return;
    final progress = (chunkIndex / totalChunks) * 100.0;
    state = state.copyWith(progressPercentage: progress.clamp(0.0, 100.0));
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _ttsService.setVoice(voice);
    state = state.copyWith(selectedVoice: voice);
  }

  Future<void> setSpeechRate(double rate) async {
    await _ttsService.setSpeechRate(rate);
    state = state.copyWith(speechRate: rate);
  }

  Future<void> setPitch(double pitch) async {
    await _ttsService.setPitch(pitch);
    state = state.copyWith(pitch: pitch);
  }

  void _scheduleSavePosition() {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(const Duration(seconds: 5), () async {
      await savePosition();
    });
  }

  Future<void> savePosition() async {
    final bookId = state.bookId;
    final fileId = state.fileId;
    if (bookId == null || fileId == null) return;

    final pos = TtsPosition(
      chapterIndex: state.currentChapter,
      chunkIndex: state.currentChunk,
      characterOffset: state.characterOffset,
      progressPercentage: state.progressPercentage,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.savePosition(
        bookId: bookId,
        fileId: fileId,
        position: pos,
      );
    } catch (e) {
      debugPrint('Error saving TTS position: $e');
    }
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    super.dispose();
  }
}

final ttsProvider = StateNotifierProvider<TtsNotifier, TtsState>((ref) {
  final ttsService = ref.watch(ttsServiceProvider);
  final repo = ref.watch(ttsRepositoryProvider);
  return TtsNotifier(ttsService: ttsService, repository: repo);
});

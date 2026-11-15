import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/reading_progress_api.dart';
import '../../data/reading_progress_repository.dart';
import '../../domain/reading_progress.dart';

final readingProgressApiProvider = Provider<ReadingProgressApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReadingProgressApi(apiClient: apiClient);
});

final readingProgressRepositoryProvider = Provider<ReadingProgressRepository>((ref) {
  final api = ref.watch(readingProgressApiProvider);
  return DefaultReadingProgressRepository(api: api);
});

class ReadingProgressState {
  final String? bookFileId;
  final String format;

  final int currentPage;
  final int totalPages;

  final String? chapterHref;
  final String? epubCfi;

  final int? audioPositionMs;
  final int? audioDurationMs;

  final double progressPercentage;

  final bool isLoading;
  final bool isRestoring;
  final bool isSaving;
  final bool hasPendingSync;

  final DateTime? lastSavedAt;

  const ReadingProgressState({
    this.bookFileId,
    this.format = 'PDF',
    this.currentPage = 1,
    this.totalPages = 1,
    this.chapterHref,
    this.epubCfi,
    this.audioPositionMs,
    this.audioDurationMs,
    this.progressPercentage = 0,
    this.isLoading = false,
    this.isRestoring = false,
    this.isSaving = false,
    this.hasPendingSync = false,
    this.lastSavedAt,
  });

  ReadingProgressState copyWith({
    String? bookFileId,
    String? format,
    int? currentPage,
    int? totalPages,
    String? chapterHref,
    String? epubCfi,
    int? audioPositionMs,
    int? audioDurationMs,
    double? progressPercentage,
    bool? isLoading,
    bool? isRestoring,
    bool? isSaving,
    bool? hasPendingSync,
    DateTime? lastSavedAt,
  }) {
    return ReadingProgressState(
      bookFileId: bookFileId ?? this.bookFileId,
      format: format ?? this.format,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      chapterHref: chapterHref ?? this.chapterHref,
      epubCfi: epubCfi ?? this.epubCfi,
      audioPositionMs: audioPositionMs ?? this.audioPositionMs,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isLoading: isLoading ?? this.isLoading,
      isRestoring: isRestoring ?? this.isRestoring,
      isSaving: isSaving ?? this.isSaving,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  ReadingProgress toReadingProgress() {
    return ReadingProgress(
      bookFileId: bookFileId ?? '',
      format: format,
      currentPage: currentPage,
      totalPages: totalPages,
      chapterHref: chapterHref,
      epubCfi: epubCfi,
      audioPositionMs: audioPositionMs,
      audioDurationMs: audioDurationMs,
      progressPercentage: progressPercentage,
      lastOpenedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class ReadingProgressNotifier extends StateNotifier<ReadingProgressState> {
  final ReadingProgressRepository _repository;
  final String bookFileId;
  final String format;

  Timer? _saveDebounce;

  ReadingProgressNotifier({
    required ReadingProgressRepository repository,
    required this.bookFileId,
    required this.format,
  })  : _repository = repository,
        super(ReadingProgressState(
          bookFileId: bookFileId,
          format: format,
          isRestoring: true,
          isLoading: true,
        )) {
    restoreProgress();
  }

  Future<void> restoreProgress() async {
    state = state.copyWith(isLoading: true, isRestoring: true);

    try {
      final saved = await _repository.getProgress(bookFileId);
      if (saved != null) {
        state = state.copyWith(
          currentPage: saved.currentPage ?? 1,
          totalPages: saved.totalPages ?? 1,
          chapterHref: saved.chapterHref,
          epubCfi: saved.epubCfi,
          audioPositionMs: saved.audioPositionMs,
          audioDurationMs: saved.audioDurationMs,
          progressPercentage: saved.progressPercentage,
          lastSavedAt: saved.updatedAt,
          isLoading: false,
          isRestoring: false,
        );
        return;
      }
    } catch (_) {}

    state = state.copyWith(
      isLoading: false,
      isRestoring: false,
    );
  }

  void updatePdfPage({
    required int page,
    required int totalPages,
    double scrollOffset = 0.0,
  }) {
    if (state.isRestoring) return;

    final safeTotal = totalPages < 1 ? 1 : totalPages;
    final safePage = page.clamp(1, safeTotal);
    final percentage = safeTotal == 1 ? 100.0 : ((safePage / safeTotal) * 100).clamp(0.0, 100.0);

    state = state.copyWith(
      currentPage: safePage,
      totalPages: safeTotal,
      progressPercentage: percentage,
      format: 'PDF',
    );

    // Save locally immediately
    _repository.saveProgress(
      bookFileId,
      state.toReadingProgress(),
      syncRemote: false,
    );

    scheduleSave();
  }

  void updateEpubPosition({
    required String? chapterHref,
    required String? cfi,
    double? progressPercentage,
    int? pageNumber,
    int? totalPages,
  }) {
    if (state.isRestoring) return;

    state = state.copyWith(
      chapterHref: chapterHref ?? state.chapterHref,
      epubCfi: cfi ?? state.epubCfi,
      progressPercentage: progressPercentage ?? state.progressPercentage,
      currentPage: pageNumber ?? state.currentPage,
      totalPages: totalPages ?? state.totalPages,
      format: 'EPUB',
    );

    _repository.saveProgress(
      bookFileId,
      state.toReadingProgress(),
      syncRemote: false,
    );

    scheduleSave();
  }

  void updateAudioPosition({
    required int positionMs,
    required int durationMs,
  }) {
    if (state.isRestoring) return;

    final percentage = durationMs > 0
        ? ((positionMs / durationMs) * 100).clamp(0.0, 100.0)
        : 0.0;

    state = state.copyWith(
      audioPositionMs: positionMs,
      audioDurationMs: durationMs,
      progressPercentage: percentage,
      format: format.isNotEmpty ? format : 'MP3',
    );

    _repository.saveProgress(
      bookFileId,
      state.toReadingProgress(),
      syncRemote: false,
    );

    scheduleSave();
  }

  void scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), () {
      saveImmediately();
    });
  }

  Future<void> saveImmediately() async {
    _saveDebounce?.cancel();
    if (state.isRestoring) return;

    state = state.copyWith(isSaving: true);
    try {
      final saved = await _repository.saveProgress(
        bookFileId,
        state.toReadingProgress(),
        syncRemote: true,
      );
      state = state.copyWith(
        isSaving: false,
        lastSavedAt: saved.updatedAt ?? DateTime.now(),
        hasPendingSync: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        hasPendingSync: true,
      );
    }
  }

  Future<void> resetProgress() async {
    _saveDebounce?.cancel();
    state = state.copyWith(
      currentPage: 1,
      chapterHref: null,
      epubCfi: null,
      audioPositionMs: 0,
      progressPercentage: 0.0,
      isSaving: true,
    );

    await _repository.resetProgress(bookFileId);

    state = state.copyWith(
      isSaving: false,
      hasPendingSync: false,
      lastSavedAt: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    if (!state.isRestoring) {
      // Save synchronous/immediate local flush on dispose
      _repository.saveProgress(
        bookFileId,
        state.toReadingProgress(),
        syncRemote: true,
      );
    }
    super.dispose();
  }
}

class ReadingProgressParams {
  final String bookFileId;
  final String format;

  const ReadingProgressParams({
    required this.bookFileId,
    required this.format,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingProgressParams &&
          runtimeType == other.runtimeType &&
          bookFileId == other.bookFileId &&
          format == other.format;

  @override
  int get hashCode => bookFileId.hashCode ^ format.hashCode;
}

final readingProgressNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReadingProgressNotifier, ReadingProgressState, ReadingProgressParams>(
        (ref, params) {
  final repo = ref.watch(readingProgressRepositoryProvider);
  return ReadingProgressNotifier(
    repository: repo,
    bookFileId: params.bookFileId,
    format: params.format,
  );
});

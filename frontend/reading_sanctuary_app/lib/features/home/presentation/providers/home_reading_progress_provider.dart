import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../reader/domain/reading_progress.dart';
import '../../../reader/presentation/providers/reading_progress_provider.dart';

/// Fetches all persisted reading-progress records (remote and offline local cache).
final homeReadingProgressProvider =
    FutureProvider<List<ReadingProgress>>((ref) async {
  final repo = ref.watch(readingProgressRepositoryProvider);
  return repo.getAllProgress();
});

/// Provides a map of bookFileId -> ReadingProgress for O(1) card lookups.
final homeProgressByFileIdProvider =
    Provider<Map<String, ReadingProgress>>((ref) {
  final asyncProgress = ref.watch(homeReadingProgressProvider);
  final list = asyncProgress.value ?? [];
  return {
    for (final p in list)
      if (p.bookFileId.isNotEmpty) p.bookFileId: p,
  };
});

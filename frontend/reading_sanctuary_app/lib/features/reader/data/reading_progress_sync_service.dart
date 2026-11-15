import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reading_progress_repository.dart';
import '../presentation/providers/reading_progress_provider.dart';

class ReadingProgressSyncService {
  final ReadingProgressRepository _repository;
  Timer? _periodicSyncTimer;

  ReadingProgressSyncService({required ReadingProgressRepository repository})
      : _repository = repository {
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    // Synchronize pending records every 30 seconds when app is active
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncPending();
    });
  }

  Future<void> syncPending() async {
    try {
      await _repository.syncPendingRecords();
    } catch (e) {
      debugPrint('ReadingProgressSyncService: syncPending error: $e');
    }
  }

  void dispose() {
    _periodicSyncTimer?.cancel();
  }
}

final readingProgressSyncServiceProvider = Provider<ReadingProgressSyncService>((ref) {
  final repo = ref.watch(readingProgressRepositoryProvider);
  final service = ReadingProgressSyncService(repository: repo);
  ref.onDispose(service.dispose);
  return service;
});

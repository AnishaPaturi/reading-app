import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/classified_book.dart';
import '../models/duplicate_status.dart';
import 'book_scanner_service.dart';
import 'duplicate_detection_service.dart';

enum DiscoveryEnginePhase {
  idle,
  scanning,
  processingAndHashing,
  checkingDuplicates,
  complete,
  error,
}

class DiscoveryEngineProgress {
  final DiscoveryEnginePhase phase;
  final String statusMessage;
  final int totalFiles;
  final int processedFiles;
  final double progressPercent;

  const DiscoveryEngineProgress({
    required this.phase,
    required this.statusMessage,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.progressPercent = 0.0,
  });
}

class DiscoveryEngine extends ChangeNotifier {
  final BookScannerService scannerService;
  final DuplicateDetectionService duplicateDetectionService;

  DiscoveryEngineProgress _progress = const DiscoveryEngineProgress(
    phase: DiscoveryEnginePhase.idle,
    statusMessage: 'Ready to discover books',
  );

  List<ClassifiedBook> _classifiedBooks = [];

  DiscoveryEngine({
    required this.scannerService,
    required this.duplicateDetectionService,
  });

  DiscoveryEngineProgress get progress => _progress;
  List<ClassifiedBook> get classifiedBooks => List.unmodifiable(_classifiedBooks);

  List<ClassifiedBook> get newBooks =>
      _classifiedBooks.where((b) => b.classification == DuplicateClassification.newBook).toList();

  List<ClassifiedBook> get alreadyImportedBooks =>
      _classifiedBooks.where((b) => b.classification == DuplicateClassification.alreadyImported).toList();

  List<ClassifiedBook> get duplicateInScanBooks =>
      _classifiedBooks.where((b) => b.classification == DuplicateClassification.duplicateInScan).toList();

  List<ClassifiedBook> get unverifiedBooks =>
      _classifiedBooks.where((b) => b.classification == DuplicateClassification.verificationFailed).toList();

  List<ClassifiedBook> get invalidOrErrorBooks =>
      _classifiedBooks.where((b) => b.hasError).toList();

  /// Runs the full end-to-end discovery and classification pipeline.
  /// IMPORTANT: No files are uploaded or imported during discovery.
  Future<List<ClassifiedBook>> runDiscovery() async {
    try {
      // 0. Start a new discovery session to invalidate any stale session-scoped caches
      duplicateDetectionService.checksumService.startNewSession();

      // 1. Scanning phase
      _updateProgress(
        phase: DiscoveryEnginePhase.scanning,
        message: 'Scanning registered folders for books and audiobooks...',
        percent: 0.1,
      );

      final discovered = await scannerService.scanAllFolders();

      if (discovered.isEmpty) {
        _classifiedBooks = [];
        _updateProgress(
          phase: DiscoveryEnginePhase.complete,
          message: 'Scan finished. No book files found.',
          total: 0,
          processed: 0,
          percent: 1.0,
        );
        return [];
      }

      // 2. Hashing and duplicate classification phase
      _updateProgress(
        phase: DiscoveryEnginePhase.processingAndHashing,
        message: 'Validating signatures and calculating SHA-256 checksums...',
        total: discovered.length,
        processed: 0,
        percent: 0.3,
      );

      final classified = await duplicateDetectionService.classifyFiles(
        discovered,
        onProgress: (processed, total, currentName) {
          final pct = 0.3 + (processed / total) * 0.6;
          _updateProgress(
            phase: DiscoveryEnginePhase.processingAndHashing,
            message: 'Processing $currentName ($processed of $total)...',
            total: total,
            processed: processed,
            percent: pct,
          );
        },
      );

      _classifiedBooks = classified;

      _updateProgress(
        phase: DiscoveryEnginePhase.complete,
        message: 'Discovery complete! Discovered ${classified.length} files (${newBooks.length} new, ${alreadyImportedBooks.length} already in library, ${unverifiedBooks.length} unverified).',
        total: classified.length,
        processed: classified.length,
        percent: 1.0,
      );

      return _classifiedBooks;

    } catch (e) {
      _updateProgress(
        phase: DiscoveryEnginePhase.error,
        message: 'Discovery failed: $e',
        percent: 1.0,
      );
      return [];
    }
  }

  /// Retries backend duplicate verification for any unverified books (e.g. after network reconnection)
  /// without re-scanning or re-computing unchanged file checksums.
  Future<List<ClassifiedBook>> retryVerification() async {
    final unverified = unverifiedBooks;
    if (unverified.isEmpty) return _classifiedBooks;

    try {
      _updateProgress(
        phase: DiscoveryEnginePhase.checkingDuplicates,
        message: 'Retrying backend duplicate verification for ${unverified.length} unverified books...',
        total: unverified.length,
        processed: 0,
        percent: 0.5,
      );

      final updated = await duplicateDetectionService.retryVerification(
        _classifiedBooks,
      );

      _classifiedBooks = updated;

      _updateProgress(
        phase: DiscoveryEnginePhase.complete,
        message: 'Verification retry complete! Discovered ${_classifiedBooks.length} files (${newBooks.length} new, ${alreadyImportedBooks.length} already in library, ${unverifiedBooks.length} unverified).',
        total: _classifiedBooks.length,
        processed: _classifiedBooks.length,
        percent: 1.0,
      );

      return _classifiedBooks;
    } catch (e) {
      _updateProgress(
        phase: DiscoveryEnginePhase.error,
        message: 'Verification retry failed: $e',
        percent: 1.0,
      );
      return _classifiedBooks;
    }
  }

  void _updateProgress({
    required DiscoveryEnginePhase phase,
    required String message,
    int? total,
    int? processed,
    double? percent,
  }) {
    _progress = DiscoveryEngineProgress(
      phase: phase,
      statusMessage: message,
      totalFiles: total ?? _progress.totalFiles,
      processedFiles: processed ?? _progress.processedFiles,
      progressPercent: percent ?? _progress.progressPercent,
    );
    notifyListeners();
  }

  void reset() {
    _classifiedBooks.clear();
    _progress = const DiscoveryEngineProgress(
      phase: DiscoveryEnginePhase.idle,
      statusMessage: 'Ready to discover books',
    );
    notifyListeners();
  }
}

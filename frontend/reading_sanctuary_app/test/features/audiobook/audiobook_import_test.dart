import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_import_service.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_scanner_service.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_metadata_service.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/pages/audiobook_import_page.dart';

class _FakeImportMetadataService extends AudiobookMetadataService {
  @override
  Future<AudioMetadataResult> readMetadata(String filePath) async {
    return const AudioMetadataResult(
      title: 'Imported Chapter',
      album: 'Imported Book',
      artist: 'Imported Author',
      durationMs: 60000,
    );
  }
}

void main() {
  group('Milestone 2A — File Selection and Import Tests', () {
    test('AudioFilePickResult correctly tracks valid, unsupported, and cancelled state', () {
      const emptyCancelled = AudioFilePickResult(wasCancelled: true);
      expect(emptyCancelled.wasCancelled, isTrue);
      expect(emptyCancelled.isEmpty, isTrue);
      expect(emptyCancelled.hasIssues, isFalse);

      final withIssues = AudioFilePickResult(
        validFiles: [File('track1.mp3')],
        unsupportedFiles: ['notes.txt'],
        inaccessibleFiles: ['missing.m4a'],
        wasCancelled: false,
      );
      expect(withIssues.wasCancelled, isFalse);
      expect(withIssues.isEmpty, isFalse);
      expect(withIssues.hasIssues, isTrue);
      expect(withIssues.validFiles.length, 1);
      expect(withIssues.unsupportedFiles.length, 1);
      expect(withIssues.inaccessibleFiles.length, 1);
    });

    testWidgets('AudiobookImportPage renders Scan Folder and Pick Files buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AudiobookImportPage(),
          ),
        ),
      );

      expect(find.text('Import Audiobooks'), findsOneWidget);
      expect(find.text('Select Audio Source'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Scan Folder'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Pick Files'), findsOneWidget);
    });
  });

  group('Milestone 2D.1 — Import Service and UI Rejected File Reporting', () {
    test('previewFolderScan returns AudiobookScanResult with rejected files', () async {
      final tempDir = await Directory.systemTemp.createTemp('rs_import_test_');
      try {
        final audioFile = File('${tempDir.path}/track.mp3');
        final pdfFile = File('${tempDir.path}/manual.pdf');
        await audioFile.writeAsString('audio');
        await pdfFile.writeAsString('pdf');

        final importService = AudiobookImportService(
          scannerService: AudiobookScannerService(metadataService: _FakeImportMetadataService()),
        );
        final scanResult = await importService.previewFolderScan(tempDir.path);

        expect(scanResult.books.length, 1);
        expect(scanResult.hasRejectedFiles, isTrue);
        expect(scanResult.rejectedFiles.any((r) => r.fileName == 'manual.pdf'), isTrue);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('previewPickedFiles returns AudiobookScanResult with empty and invalid files', () async {
      final tempDir = await Directory.systemTemp.createTemp('rs_import_picked_test_');
      try {
        final validFile = File('${tempDir.path}/track.mp3');
        final emptyFile = File('${tempDir.path}/empty.mp3');
        await validFile.writeAsString('audio');
        await emptyFile.writeAsBytes([]);

        final importService = AudiobookImportService(
          scannerService: AudiobookScannerService(metadataService: _FakeImportMetadataService()),
        );
        final scanResult = await importService.previewPickedFiles([validFile, emptyFile]);

        expect(scanResult.books.length, 1);
        expect(scanResult.hasRejectedFiles, isTrue);
        expect(scanResult.rejectedFiles.first.fileName, 'empty.mp3');
        expect(scanResult.rejectedFiles.first.reason, RejectedFileReason.emptyFile);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}

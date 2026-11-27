import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/file_checksum_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FileChecksumService checksumService;
  late Directory tempDir;
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    const channel = MethodChannel('reading_sanctuary/saf');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      methodCalls.add(call);
      if (call.method == 'computeDocumentSha256') {
        final uri = call.arguments['uri'] as String?;
        if (uri != null && uri.contains('error')) {
          throw PlatformException(code: 'IO_ERROR', message: 'Stream interrupted');
        }
        return 'android_native_sha256_hash_12345';
      }
      return null;
    });

    checksumService = FileChecksumService(channel: channel);
    tempDir = Directory.systemTemp.createTempSync('checksum_test_');
  });

  tearDown(() {
    const channel = MethodChannel('reading_sanctuary/saf');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);

    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('computeChecksum correctly hashes file content matching standard SHA-256', () async {
    final file = File('${tempDir.path}/test_book.epub');
    const content = 'Reading Sanctuary Test Content for SHA-256 Verification';
    file.writeAsStringSync(content);

    final expectedHash = sha256.convert(content.codeUnits).toString();

    final discovered = DiscoveredFile(
      id: 'f1',
      name: 'test_book.epub',
      pathOrUri: file.path,
      extension: 'epub',
      sizeBytes: file.lengthSync(),
      lastModified: file.lastModifiedSync(),
      parentFolderIdentifier: tempDir.path,
    );

    final actualHash = await checksumService.computeChecksum(discovered);
    expect(actualHash, equals(expectedHash));
  });

  test('computeChecksum streams chunked data for large files without loading into RAM', () async {
    final largeFile = File('${tempDir.path}/large_audiobook.m4b');
    // Write 2 MB synthetic chunked payload
    final chunk = List<int>.filled(65536, 0x41); // 64 KB of 'A'
    final sink = largeFile.openWrite();
    for (var i = 0; i < 32; i++) {
      sink.add(chunk);
    }
    await sink.close();

    final discovered = DiscoveredFile(
      id: 'large-1',
      name: 'large_audiobook.m4b',
      pathOrUri: largeFile.path,
      extension: 'm4b',
      sizeBytes: largeFile.lengthSync(),
      lastModified: largeFile.lastModifiedSync(),
      parentFolderIdentifier: tempDir.path,
    );

    final hash = await checksumService.computeChecksum(discovered);
    expect(hash, isNotNull);
    expect(hash!.length, 64); // Valid SHA-256 hex string length
  });

  test('computeChecksum uses Android native channel for content:// URIs', () async {
    final androidFile = DiscoveredFile(
      id: 'android-1',
      name: 'android_book.pdf',
      pathOrUri: 'content://com.android.providers/tree/primary/doc/book.pdf',
      extension: 'pdf',
      sizeBytes: 50000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: 'content://tree',
    );

    final hash = await checksumService.computeChecksum(androidFile);

    expect(hash, equals('android_native_sha256_hash_12345'));
    expect(methodCalls.any((c) => c.method == 'computeDocumentSha256'), isTrue);
  });

  test('computeChecksum handles unreadable and error files gracefully without throwing', () async {
    final missingFile = DiscoveredFile(
      id: 'missing-1',
      name: 'missing.pdf',
      pathOrUri: '${tempDir.path}/non_existent_file.pdf',
      extension: 'pdf',
      sizeBytes: 1000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: tempDir.path,
    );

    final hash = await checksumService.computeChecksum(missingFile);
    expect(hash, isNull);
  });

  // REGRESSION TEST 7
  test('Regression 7: Same path, changed file size: checksum recalculated', () async {
    final file = File('${tempDir.path}/evolving_book.epub');
    file.writeAsStringSync('Version 1 small content');

    final v1 = DiscoveredFile(
      id: 'evo-1',
      name: 'evolving_book.epub',
      pathOrUri: file.path,
      extension: 'epub',
      sizeBytes: file.lengthSync(),
      lastModified: DateTime(2026, 1, 1),
      parentFolderIdentifier: tempDir.path,
    );

    final hash1 = await checksumService.computeChecksum(v1);

    // Overwrite with larger content
    file.writeAsStringSync('Version 2 much larger content has been written to the same path');

    final v2 = DiscoveredFile(
      id: 'evo-1',
      name: 'evolving_book.epub',
      pathOrUri: file.path,
      extension: 'epub',
      sizeBytes: file.lengthSync(), // different size
      lastModified: DateTime(2026, 1, 1), // same timestamp
      parentFolderIdentifier: tempDir.path,
    );

    final hash2 = await checksumService.computeChecksum(v2);

    expect(hash1, isNotNull);
    expect(hash2, isNotNull);
    expect(hash2, isNot(equals(hash1))); // Recalculated due to size difference
  });

  // REGRESSION TEST 8
  test('Regression 8: Same path, changed modification timestamp: checksum recalculated', () async {
    final file = File('${tempDir.path}/timestamp_book.epub');
    file.writeAsStringSync('Fixed length content A');

    final t1 = DateTime(2026, 1, 1, 10, 0, 0);
    final v1 = DiscoveredFile(
      id: 'time-1',
      name: 'timestamp_book.epub',
      pathOrUri: file.path,
      extension: 'epub',
      sizeBytes: file.lengthSync(),
      lastModified: t1,
      parentFolderIdentifier: tempDir.path,
    );

    final hash1 = await checksumService.computeChecksum(v1);

    // Overwrite with same byte length but different text
    file.writeAsStringSync('Fixed length content B'); // exactly same byte length

    final t2 = DateTime(2026, 1, 2, 12, 0, 0); // newer timestamp
    final v2 = DiscoveredFile(
      id: 'time-1',
      name: 'timestamp_book.epub',
      pathOrUri: file.path,
      extension: 'epub',
      sizeBytes: file.lengthSync(),
      lastModified: t2,
      parentFolderIdentifier: tempDir.path,
    );

    final hash2 = await checksumService.computeChecksum(v2);

    expect(hash1, isNotNull);
    expect(hash2, isNotNull);
    expect(hash2, isNot(equals(hash1))); // Recalculated due to timestamp change
  });

  // REGRESSION TEST 9
  test('Regression 9: Same path and unchanged metadata: cache reused where safe', () async {
    final file = File('${tempDir.path}/stable_book.epub');
    file.writeAsStringSync('Stable book content');

    final fixedTimestamp = DateTime(2026, 1, 1, 12, 0, 0);
    final discovered = DiscoveredFile(
      id: 'stable-1',
      name: 'stable_book.epub',
      pathOrUri: file.path,
      extension: 'epub',
      sizeBytes: file.lengthSync(),
      lastModified: fixedTimestamp,
      parentFolderIdentifier: tempDir.path,
    );

    final firstHash = await checksumService.computeChecksum(discovered);

    // Delete the file from filesystem to prove disk I/O is bypassed on cache hit
    file.deleteSync();

    final secondHash = await checksumService.computeChecksum(discovered);

    expect(firstHash, isNotNull);
    expect(secondHash, equals(firstHash)); // Cache hit: served without accessing disk
  });

  // REGRESSION TEST 10
  test('Regression 10: Android content URI with unreliable modification metadata: stale cache is not reused across discovery sessions', () async {
    const androidUri = 'content://com.android.providers.downloads.documents/document/raw%3Abook.pdf';

    var nativeChannelInvocations = 0;
    const channel = MethodChannel('reading_sanctuary/saf');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      if (call.method == 'computeDocumentSha256') {
        nativeChannelInvocations++;
        return 'hash_run_$nativeChannelInvocations';
      }
      return null;
    });

    final fileWithUnreliableMetadata = DiscoveredFile(
      id: 'saf-unreliable',
      name: 'book.pdf',
      pathOrUri: androidUri,
      extension: 'pdf',
      sizeBytes: 50000,
      lastModified: DateTime(2026, 1, 1),
      parentFolderIdentifier: 'content://tree',
      hasReliableMetadata: false, // Flagged as unreliable SAF provider metadata
    );

    // SESSION 1
    checksumService.startNewSession('session-1');
    final hash1 = await checksumService.computeChecksum(fileWithUnreliableMetadata);
    expect(hash1, equals('hash_run_1'));
    expect(nativeChannelInvocations, 1);

    // Within same session 1: cache must be reused
    final hash1Again = await checksumService.computeChecksum(fileWithUnreliableMetadata);
    expect(hash1Again, equals('hash_run_1'));
    expect(nativeChannelInvocations, 1); // No new call in same session

    // SESSION 2: Start new discovery session
    checksumService.startNewSession('session-2');

    // Across sessions: stale cache must NOT be reused for unreliable metadata
    final hash2 = await checksumService.computeChecksum(fileWithUnreliableMetadata);
    expect(hash2, equals('hash_run_2'));
    expect(nativeChannelInvocations, 2); // Recalculated for new session!
  });
}

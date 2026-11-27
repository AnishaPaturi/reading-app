import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform_file_stream_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlatformFileStreamService streamService;
  late Directory tempDir;
  final List<MethodCall> channelCalls = [];

  setUp(() {
    channelCalls.clear();
    const channel = MethodChannel('reading_sanctuary/saf');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      channelCalls.add(call);
      if (call.method == 'openDocumentStream') {
        return 'session-test-123';
      }
      if (call.method == 'readDocumentStreamChunk') {
        return List<int>.generate(10, (i) => i);
      }
      if (call.method == 'closeDocumentStream') {
        return true;
      }
      if (call.method == 'readDocumentBytes') {
        final offset = call.arguments['offset'] as int? ?? 0;
        return List<int>.generate(10, (i) => offset + i);
      }
      return null;
    });

    streamService = PlatformFileStreamService(channel: channel);
    tempDir = Directory.systemTemp.createTempSync('stream_test_');
  });

  tearDown(() {
    const channel = MethodChannel('reading_sanctuary/saf');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('Android content URI upload handling: streams through ContentResolver and does not use dart:io File', () async {
    final file = DiscoveredFile(
      id: 'android-saf-1',
      name: 'android_book.epub',
      pathOrUri: 'content://com.android.providers.downloads/doc/123',
      extension: 'epub',
      sizeBytes: 20, // 2 chunks of 10 bytes
      lastModified: DateTime.now(),
      parentFolderIdentifier: 'content://tree',
    );

    final selected = await streamService.createSelectedBookFile(file);

    expect(selected.name, 'android_book.epub');
    expect(selected.extension, 'epub');
    expect(selected.size, 20);
    // Path MUST be null because content URIs cannot be opened with dart:io File
    expect(selected.path, isNull);
    expect(selected.hasStream, isTrue);

    // Consume the stream
    final chunks = await selected.readStream!.toList();
    expect(chunks.length, 2);
    expect(channelCalls.any((c) => c.method == 'openDocumentStream'), isTrue);
    expect(channelCalls.where((c) => c.method == 'readDocumentStreamChunk').length, 2);
    expect(channelCalls.any((c) => c.method == 'closeDocumentStream'), isTrue);
  });

  test('Desktop streaming upload: attaches openRead stream for local files without buffering into RAM', () async {
    final localFile = File('${tempDir.path}/desktop_novel.pdf');
    localFile.writeAsStringSync('Reading Sanctuary Desktop Streaming Test');

    final file = DiscoveredFile(
      id: 'desktop-1',
      name: 'desktop_novel.pdf',
      pathOrUri: localFile.path,
      extension: 'pdf',
      sizeBytes: localFile.lengthSync(),
      lastModified: localFile.lastModifiedSync(),
      parentFolderIdentifier: tempDir.path,
    );

    final selected = await streamService.createSelectedBookFile(file);

    expect(selected.name, 'desktop_novel.pdf');
    expect(selected.extension, 'pdf');
    expect(selected.size, localFile.lengthSync());
    expect(selected.hasPath, isTrue);
    expect(selected.hasStream, isTrue);

    // Verify stream emits content
    final bytes = await selected.readStream!.expand((c) => c).toList();
    expect(String.fromCharCodes(bytes), 'Reading Sanctuary Desktop Streaming Test');
  });

  test('Web compatibility: provides in-memory bytes or stream without dart:io access', () async {
    final file = DiscoveredFile(
      id: 'web-1',
      name: 'web_book.pdf',
      pathOrUri: 'web://uploads/web_book.pdf',
      extension: 'pdf',
      sizeBytes: 100,
      lastModified: DateTime.now(),
      parentFolderIdentifier: 'web://uploads',
      headerBytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]), // %PDF
    );

    final selected = await streamService.createSelectedBookFile(file);

    expect(selected.name, 'web_book.pdf');
    expect(selected.size, 100);
    expect(selected.hasBytes, isTrue);
    expect(selected.bytes, isNotNull);
    expect(selected.bytes!.length, 4);
  });
}

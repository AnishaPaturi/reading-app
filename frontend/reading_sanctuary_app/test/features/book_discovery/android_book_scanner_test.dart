import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/android_book_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AndroidBookScanner scanner;
  final List<MethodCall> methodCalls = [];

  setUp(() {
    methodCalls.clear();
    const channel = MethodChannel('reading_sanctuary/saf');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      methodCalls.add(call);

      switch (call.method) {
        case 'openDocumentTree':
          return {
            'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADownload',
            'name': 'Download',
            'isPersisted': true,
          };

        case 'isUriPermissionGranted':
          final uri = call.arguments['uri'] as String?;
          if (uri != null && uri.contains('revoked')) {
            return false;
          }
          return true;

        case 'releasePersistableUriPermission':
          return true;

        case 'listFiles':
          final uri = call.arguments['uri'] as String?;
          if (uri != null && uri.contains('empty')) {
            return [];
          }
          return [
            {
              'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADownload/document/book1.epub',
              'name': 'The Great Gatsby.epub',
              'extension': 'epub',
              'size': 1048576,
              'lastModified': 1690000000000,
              'mimeType': 'application/epub+zip',
            },
            {
              'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADownload/document/subfolder/notes.pdf',
              'name': 'Philosophy of Mind.pdf',
              'extension': 'pdf',
              'size': 2097152,
              'lastModified': 1690050000000,
              'mimeType': 'application/pdf',
            },
            {
              'uri': 'content://com.android.externalstorage.documents/tree/primary%3ADownload/document/audio.m4b',
              'name': 'Project Hail Mary.m4b',
              'extension': 'm4b',
              'size': 524288000,
              'lastModified': 1690100000000,
              'mimeType': 'audio/mp4',
            },
          ];

        case 'readFileHeader':
          return Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]);

        default:
          return null;
      }
    });

    scanner = AndroidBookScanner(channel: channel);
  });

  tearDown(() {
    const channel = MethodChannel('reading_sanctuary/saf');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('pickFolder returns ScanFolder with persisted SAF tree URI', () async {
    final folder = await scanner.pickFolder();

    expect(folder, isNotNull);
    expect(folder!.name, 'Download');
    expect(folder.pathOrUri, contains('primary%3ADownload'));
    expect(folder.folderType, FolderType.downloads);
    expect(folder.status, FolderAccessStatus.active);

    expect(methodCalls.any((c) => c.method == 'openDocumentTree'), isTrue);
  });

  test('verifyPermission checks live SAF persisted permission', () async {
    const validFolder = ScanFolder(
      id: '1',
      name: 'Downloads',
      pathOrUri: 'content://tree/primary%3ADownload',
    );
    const revokedFolder = ScanFolder(
      id: '2',
      name: 'Revoked',
      pathOrUri: 'content://tree/primary%3Arevoked',
    );

    final isValid = await scanner.verifyPermission(validFolder);
    final isRevoked = await scanner.verifyPermission(revokedFolder);

    expect(isValid, isTrue);
    expect(isRevoked, isFalse);
  });

  test('releasePermission calls native releasePersistableUriPermission', () async {
    const folder = ScanFolder(
      id: '1',
      name: 'Downloads',
      pathOrUri: 'content://tree/primary%3ADownload',
    );

    final released = await scanner.releasePermission(folder);
    expect(released, isTrue);
    expect(methodCalls.any((c) => c.method == 'releasePersistableUriPermission'), isTrue);
  });

  test('scanFolder returns discovered files across nested directories', () async {
    const folder = ScanFolder(
      id: '1',
      name: 'Downloads',
      pathOrUri: 'content://tree/primary%3ADownload',
    );

    final files = await scanner.scanFolder(folder);

    expect(files.length, 3);
    expect(files.any((f) => f.name == 'The Great Gatsby.epub' && f.isEbook), isTrue);
    expect(files.any((f) => f.name == 'Philosophy of Mind.pdf' && f.isEbook), isTrue);
    expect(files.any((f) => f.name == 'Project Hail Mary.m4b' && f.isAudiobook), isTrue);
  });

  test('scanFolder handles empty directories gracefully', () async {
    const folder = ScanFolder(
      id: 'empty-1',
      name: 'Empty Folder',
      pathOrUri: 'content://tree/primary%3Aempty',
    );

    final files = await scanner.scanFolder(folder);
    expect(files, isEmpty);
  });

  test('readFileHeader reads magic byte header via MethodChannel', () async {
    final header = await scanner.readFileHeader('content://document/sample.epub', maxBytes: 4);

    expect(header, isNotNull);
    expect(header!, equals([0x50, 0x4B, 0x03, 0x04]));
  });
}

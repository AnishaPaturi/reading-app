import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/desktop_book_scanner.dart';

void main() {
  late Directory tempDir;
  late DesktopBookScanner scanner;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('reading_sanctuary_test_');
    scanner = DesktopBookScanner();

    // Create file structure:
    // tempDir/
    //   novel.epub
    //   manual.docx
    //   audiobook.mp3
    //   unsupported.txt
    //   installer.exe
    //   subfolder/
    //     deep_book.pdf
    //   .git/
    //     hidden.pdf
    //   empty_folder/

    File('${tempDir.path}/novel.epub').writeAsBytesSync([0x50, 0x4B, 0x03, 0x04, 0x01, 0x02]);
    File('${tempDir.path}/manual.docx').writeAsBytesSync([0x50, 0x4B, 0x03, 0x04]);
    File('${tempDir.path}/audiobook.mp3').writeAsBytesSync([0x49, 0x44, 0x33, 0x00]);
    File('${tempDir.path}/unsupported.txt').writeAsStringSync('Hello World');
    File('${tempDir.path}/installer.exe').writeAsBytesSync([0x4D, 0x5A, 0x00]);

    final subfolder = Directory('${tempDir.path}/subfolder')..createSync();
    File('${subfolder.path}/deep_book.pdf').writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);

    final hiddenFolder = Directory('${tempDir.path}/.git')..createSync();
    File('${hiddenFolder.path}/hidden.pdf').writeAsBytesSync([0x25, 0x50, 0x44, 0x46]);

    Directory('${tempDir.path}/empty_folder').createSync();
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('scanFolder recursively discovers books and audiobooks while filtering unsupported and hidden files', () async {
    final folder = ScanFolder(
      id: 'desktop-1',
      name: 'Temp Test Books',
      pathOrUri: tempDir.path,
    );

    final files = await scanner.scanFolder(folder);

    // Expected matches: novel.epub, manual.docx, audiobook.mp3, deep_book.pdf (4 files)
    expect(files.length, 4);

    final names = files.map((f) => f.name).toSet();
    expect(names, containsAll(['novel.epub', 'manual.docx', 'audiobook.mp3', 'deep_book.pdf']));

    // Excluded: unsupported.txt, installer.exe
    expect(names, isNot(contains('unsupported.txt')));
    expect(names, isNot(contains('installer.exe')));

    // Excluded: hidden folder .git/hidden.pdf
    expect(names, isNot(contains('hidden.pdf')));
  });

  test('verifyPermission returns true for existing directory and false for non-existent', () async {
    final validFolder = ScanFolder(
      id: 'desktop-1',
      name: 'Valid',
      pathOrUri: tempDir.path,
    );
    final nonExistentFolder = ScanFolder(
      id: 'desktop-2',
      name: 'NonExistent',
      pathOrUri: '${tempDir.path}/does_not_exist_folder',
    );

    expect(await scanner.verifyPermission(validFolder), isTrue);
    expect(await scanner.verifyPermission(nonExistentFolder), isFalse);
  });

  test('readFileHeader reads leading bytes from local file', () async {
    final filePath = '${tempDir.path}/novel.epub';
    final header = await scanner.readFileHeader(filePath, maxBytes: 4);

    expect(header, isNotNull);
    expect(header, equals([0x50, 0x4B, 0x03, 0x04]));
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:reading_sanctuary_app/core/sync/services/local_storage_db.dart';
import 'package:reading_sanctuary_app/features/offline/domain/models/download_task.dart';
import 'package:reading_sanctuary_app/features/offline/services/download_manager.dart';

class FakeHttpClient extends http.BaseClient {
  final Uint8List responseBytes;
  final int statusCode;

  FakeHttpClient({required this.responseBytes, this.statusCode = 200});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(responseBytes),
      statusCode,
      contentLength: responseBytes.length,
      request: request,
    );
  }
}

void main() {
  late Directory tempDir;
  late LocalStorageDb localDb;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('download_manager_test_');
    localDb = LocalStorageDb(customDirectoryPath: tempDir.path);
    await localDb.init();
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('Downloads file, verifies SHA-256 checksum and marks downloaded', () async {
    final fileContent = utf8.encode('PDF file sample contents for offline reading test.');
    final expectedHash = sha256.convert(fileContent).toString();

    final fakeClient = FakeHttpClient(responseBytes: Uint8List.fromList(fileContent));
    final manager = DownloadManager(
      localDb: localDb,
      httpClient: fakeClient,
      customDownloadDirPath: tempDir.path,
    );
    await manager.init();

    await manager.downloadBookFile(
      bookId: 'b-100',
      fileId: 'f-200',
      bookTitle: 'The Pragmatic Programmer',
      fileName: 'pragmatic.pdf',
      format: 'PDF',
      directDownloadUrl: 'https://storage.example.com/books/pragmatic.pdf',
      expectedChecksum: expectedHash,
    );

    expect(manager.isDownloaded('f-200'), isTrue);
    final task = manager.getTask('f-200');
    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.downloaded);
    expect(task.totalBytes, fileContent.length);

    final bytes = await manager.getLocalFileBytes('f-200');
    expect(bytes, isNotNull);
    expect(utf8.decode(bytes!), 'PDF file sample contents for offline reading test.');
  });

  test('Fails download when checksum does not match', () async {
    final fileContent = utf8.encode('Corrupted file content');
    const wrongHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    final fakeClient = FakeHttpClient(responseBytes: Uint8List.fromList(fileContent));
    final manager = DownloadManager(
      localDb: localDb,
      httpClient: fakeClient,
      customDownloadDirPath: tempDir.path,
    );
    await manager.init();

    await manager.downloadBookFile(
      bookId: 'b-1',
      fileId: 'f-corrupt',
      bookTitle: 'Corrupt Book',
      fileName: 'book.pdf',
      format: 'PDF',
      directDownloadUrl: 'https://storage.example.com/corrupt.pdf',
      expectedChecksum: wrongHash,
    );

    expect(manager.isDownloaded('f-corrupt'), isFalse);
    final task = manager.getTask('f-corrupt');
    expect(task, isNotNull);
    expect(task!.status, DownloadStatus.failed);
    expect(task.errorMessage, contains('Checksum verification mismatch'));
  });

  test('Deletes download and removes file from disk', () async {
    final fileContent = utf8.encode('Some book data');
    final fakeClient = FakeHttpClient(responseBytes: Uint8List.fromList(fileContent));
    final manager = DownloadManager(
      localDb: localDb,
      httpClient: fakeClient,
      customDownloadDirPath: tempDir.path,
    );
    await manager.init();

    await manager.downloadBookFile(
      bookId: 'b-1',
      fileId: 'f-delete-me',
      bookTitle: 'Temp Book',
      fileName: 'temp.epub',
      format: 'EPUB',
      directDownloadUrl: 'https://storage.example.com/temp.epub',
    );

    expect(manager.isDownloaded('f-delete-me'), isTrue);

    await manager.deleteDownload('f-delete-me');
    expect(manager.isDownloaded('f-delete-me'), isFalse);
    expect(manager.getLocalFilePath('f-delete-me'), isNull);
  });
}

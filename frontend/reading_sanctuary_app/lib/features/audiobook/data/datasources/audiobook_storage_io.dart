import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'audiobook_storage_interface.dart';

class IoAudiobookStorageBackend implements AudiobookStorageBackend {
  final String? customDirectoryPath;
  Directory? _baseDir;

  IoAudiobookStorageBackend({this.customDirectoryPath});

  @override
  Future<void> init() async {
    if (_baseDir != null) return;
    try {
      final dir = customDirectoryPath != null
          ? Directory(customDirectoryPath!)
          : await getApplicationDocumentsDirectory();

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _baseDir = dir;
    } catch (e) {
      throw AudiobookStorageException('Failed to initialize filesystem audiobook storage', e);
    }
  }

  File _getFile(String key) {
    final dir = _baseDir;
    if (dir == null) {
      throw const AudiobookStorageException('Audiobook storage has not been initialized.');
    }
    return File('${dir.path}/$key.json');
  }

  @override
  Future<String?> readStore(String key) async {
    await init();
    try {
      final file = _getFile(key);
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsString();
    } catch (e) {
      if (e is AudiobookStorageException) rethrow;
      throw AudiobookStorageException('Failed to read audiobook store "$key"', e);
    }
  }

  @override
  Future<void> writeStore(String key, String value) async {
    await init();
    try {
      final file = _getFile(key);
      await file.writeAsString(value);
    } catch (e) {
      if (e is AudiobookStorageException) rethrow;
      throw AudiobookStorageException('Failed to write audiobook store "$key"', e);
    }
  }
}

AudiobookStorageBackend createPlatformAudiobookStorage({String? customDirectoryPath}) {
  return IoAudiobookStorageBackend(customDirectoryPath: customDirectoryPath);
}

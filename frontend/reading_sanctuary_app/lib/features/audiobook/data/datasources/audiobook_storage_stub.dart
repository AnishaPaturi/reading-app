import 'audiobook_storage_interface.dart';

AudiobookStorageBackend createPlatformAudiobookStorage({String? customDirectoryPath}) {
  throw UnsupportedError('AudiobookStorageBackend is not supported on this platform.');
}

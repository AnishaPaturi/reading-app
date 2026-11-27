class AudiobookStorageException implements Exception {
  final String message;
  final Object? cause;

  const AudiobookStorageException(this.message, [this.cause]);

  @override
  String toString() =>
      cause != null ? 'AudiobookStorageException: $message ($cause)' : 'AudiobookStorageException: $message';
}

abstract class AudiobookStorageBackend {
  Future<void> init();

  Future<String?> readStore(String key);

  Future<void> writeStore(String key, String value);
}

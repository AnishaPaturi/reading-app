class BookFileValidator {
  static const List<String> supportedExtensions = [
    'pdf',
    'epub',
    'm4a',
    'mp3',
  ];

  static const Map<String, String> mimeTypes = {
    'pdf': 'application/pdf',
    'epub': 'application/epub+zip',
    'm4a': 'audio/mp4',
    'mp3': 'audio/mpeg',
  };

  static bool isSupported(String filename) {
    if (!filename.contains('.')) return false;
    final extension = filename.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  static String getExtension(String filename) {
    if (!filename.contains('.')) return '';
    return filename.split('.').last.toLowerCase();
  }

  static String getMimeType(String filename) {
    final extension = getExtension(filename);
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  static String getFormat(String filename) {
    return getExtension(filename).toUpperCase();
  }
}

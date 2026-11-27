class BookFileValidator {
  static const List<String> supportedExtensions = [
    'pdf',
    'epub',
    'mp3',
    'm4a',
    'm4b',
  ];

  static const Map<String, String> mimeTypes = {
    'pdf': 'application/pdf',
    'epub': 'application/epub+zip',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'm4b': 'audio/mp4',
  };

  static bool isSupported(String filename) {
    final extension = getExtension(filename);
    return supportedExtensions.contains(extension);
  }

  static String getExtension(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == filename.length - 1) {
      return '';
    }

    return filename.substring(dotIndex + 1).toLowerCase();
  }

  static String getMimeType(String filename) {
    return mimeTypes[getExtension(filename)] ??
        'application/octet-stream';
  }

  static String getFormat(String filename) {
    return getExtension(filename).toUpperCase();
  }
}

class AudioFormatUtils {
  static const Set<String> supportedExtensions = {
    'm4b',
    'mp3',
    'm4a',
    'ogg',
    'oga',
    'opus',
  };

  static bool isSupported(String path) {
    if (!path.contains('.')) return false;
    final extension = path.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }

  static String getExtension(String path) {
    if (!path.contains('.')) return '';
    return path.split('.').last.toLowerCase();
  }
}

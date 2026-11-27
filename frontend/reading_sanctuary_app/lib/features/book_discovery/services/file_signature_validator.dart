import 'dart:typed_data';

class FileSignatureValidator {
  /// Validates format magic bytes against declared file extension.
  /// Returns null if valid, or an error string if invalid.
  static String? validateSignature(String extension, Uint8List? headerBytes, int sizeBytes) {
    if (sizeBytes <= 0) {
      return 'File is empty (0 bytes)';
    }

    if (headerBytes == null || headerBytes.isEmpty) {
      return null;
    }

    final ext = extension.toLowerCase().replaceAll('.', '');

    switch (ext) {
      case 'pdf':
        // %PDF -> [0x25, 0x50, 0x44, 0x46]
        if (headerBytes.length < 4 ||
            headerBytes[0] != 0x25 ||
            headerBytes[1] != 0x50 ||
            headerBytes[2] != 0x44 ||
            headerBytes[3] != 0x46) {
          return 'File signature does not match PDF format';
        }
        return null;

      case 'epub':
      case 'docx':
        // PK\x03\x04 -> [0x50, 0x4B, 0x03, 0x04]
        if (headerBytes.length < 4 ||
            headerBytes[0] != 0x50 ||
            headerBytes[1] != 0x4B ||
            headerBytes[2] != 0x03 ||
            headerBytes[3] != 0x04) {
          return 'File signature does not match ${ext.toUpperCase()} ZIP container format';
        }
        return null;

      case 'mp3':
        // ID3 header or MPEG frame sync (0xFF 0xE0)
        final isId3 = headerBytes.length >= 3 &&
            headerBytes[0] == 0x49 &&
            headerBytes[1] == 0x44 &&
            headerBytes[2] == 0x33;
        final isMpeg = headerBytes.length >= 2 &&
            (headerBytes[0] & 0xFF) == 0xFF &&
            ((headerBytes[1] & 0xE0) == 0xE0);
        if (!isId3 && !isMpeg) {
          return 'File signature does not match MP3 audio format';
        }
        return null;

      case 'm4b':
      case 'm4a':
        // MP4 container has 'ftyp' at offset 4
        if (headerBytes.length >= 8) {
          final isFtyp = headerBytes[4] == 0x66 && // 'f'
              headerBytes[5] == 0x74 && // 't'
              headerBytes[6] == 0x79 && // 'y'
              headerBytes[7] == 0x70;   // 'p'
          if (!isFtyp) {
            return 'File signature does not match M4B/M4A MP4 container format';
          }
        }
        return null;

      default:
        return 'Unsupported format: .$ext';
    }
  }
}

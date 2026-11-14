import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'book_file_validator.dart';

class BookImportService {
  Future<PlatformFile?> pickBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: BookFileValidator.supportedExtensions,
      allowMultiple: false,
      withReadStream: !kIsWeb,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;

    if (!BookFileValidator.isSupported(file.name)) {
      throw Exception(
        'Unsupported book format: ${BookFileValidator.getExtension(file.name)}. Supported formats: PDF, EPUB, M4A, MP3.',
      );
    }

    if (!kIsWeb && file.readStream == null && file.path == null && file.bytes == null) {
      throw Exception('Unable to read the selected file.');
    }

    if (kIsWeb && file.bytes == null) {
      throw Exception('Unable to read the selected file in browser.');
    }

    return file;
  }
}

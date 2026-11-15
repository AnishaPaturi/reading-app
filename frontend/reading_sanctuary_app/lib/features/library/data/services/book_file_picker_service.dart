import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/selected_book_file.dart';

class BookFilePickerService {
  static const supportedExtensions = [
    'pdf',
    'epub',
    'mp3',
    'm4b',
  ];

  Future<SelectedBookFile?> pickBookFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: false,
        // Enable stream across platforms so large audiobooks (e.g. 600MB+) stream without crashing RAM.
        withData: kIsWeb,
        withReadStream: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.single;
      final extension = file.extension?.toLowerCase();

      if (extension == null || !supportedExtensions.contains(extension)) {
        throw Exception(
          'Unsupported format. Please select PDF, EPUB, MP3 or M4B.',
        );
      }

      // Browser files must provide readable bytes or a stream.
      if (kIsWeb && file.bytes == null && file.readStream == null) {
        throw Exception(
          'Unable to read the selected file. Please try again.',
        );
      }

      // Native platforms must provide at least one readable source.
      if (!kIsWeb &&
          file.path == null &&
          file.readStream == null &&
          file.bytes == null) {
        throw Exception(
          'Unable to access the selected file.',
        );
      }

      if (file.size <= 0) {
        throw Exception('The selected file is empty.');
      }

      return SelectedBookFile.fromPlatformFile(file);
    } on PlatformException catch (e) {
      throw Exception(
        'File picker error: ${e.message ?? 'Unknown error'}',
      );
    } catch (e) {
      throw Exception(
        'Failed to select book: ${e.toString()}',
      );
    }
  }
}

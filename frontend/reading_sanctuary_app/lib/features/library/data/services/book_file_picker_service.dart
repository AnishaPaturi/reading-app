import 'package:file_picker/file_picker.dart';
import '../models/selected_book_file.dart';

class BookFilePickerService {
  static const supportedExtensions = [
    'pdf',
    'epub',
    'mp3',
    'm4b',
    'm4a',
  ];

  Future<SelectedBookFile?> pickBookFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: false,
        withReadStream: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.single;
      final extension = file.extension?.toLowerCase();

      if (extension == null || !supportedExtensions.contains(extension)) {
        throw Exception('Unsupported book format: ${extension ?? 'unknown'}. Supported formats: PDF, EPUB, MP3, M4B, M4A.');
      }

      return SelectedBookFile.fromPlatformFile(file);
    } on PlatformException catch (e) {
      throw Exception('File picker error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }
}

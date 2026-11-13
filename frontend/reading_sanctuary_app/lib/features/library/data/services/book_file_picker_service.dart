import 'package:file_picker/file_picker.dart';

class BookFilePickerService {
  static const supportedExtensions = [
    'pdf',
    'epub',
    'mp3',
    'm4b',
  ];

  Future<PlatformFile?> pickBookFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: supportedExtensions,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final extension = file.extension?.toLowerCase();

    if (extension == null || !supportedExtensions.contains(extension)) {
      throw Exception('Unsupported book format: ${extension ?? 'unknown'}. Supported formats: PDF, EPUB, MP3, M4B.');
    }

    return file;
  }
}

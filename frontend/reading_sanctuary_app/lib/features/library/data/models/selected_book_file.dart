import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class SelectedBookFile {
  final String name;
  final String extension;
  final int size;
  final String? path;
  final Uint8List? bytes;
  final Stream<List<int>>? readStream;

  const SelectedBookFile({
    required this.name,
    required this.extension,
    required this.size,
    this.path,
    this.bytes,
    this.readStream,
  });

  bool get hasPath => path != null && path!.isNotEmpty;
  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  bool get hasStream => readStream != null;

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  factory SelectedBookFile.fromPlatformFile(PlatformFile file) {
    return SelectedBookFile(
      name: file.name,
      extension: (file.extension ?? '').toLowerCase(),
      size: file.size,
      path: file.path,
      bytes: file.bytes,
      readStream: file.readStream,
    );
  }
}

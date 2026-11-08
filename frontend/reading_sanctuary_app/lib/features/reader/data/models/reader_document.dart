import 'dart:typed_data';
import 'reader_position.dart';

class ReaderDocument {
  final String bookId;
  final String fileId;
  final String bookTitle;
  final String fileFormat;
  final Uint8List fileBytes;
  final ReaderPosition? initialPosition;

  const ReaderDocument({
    required this.bookId,
    required this.fileId,
    required this.bookTitle,
    required this.fileFormat,
    required this.fileBytes,
    this.initialPosition,
  });
}

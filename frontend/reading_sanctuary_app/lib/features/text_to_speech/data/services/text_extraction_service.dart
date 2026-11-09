import '../models/tts_document.dart';
import '../repositories/tts_repository.dart';

class TextExtractionService {
  final TtsRepository repository;

  TextExtractionService({required this.repository});

  Future<TtsDocument> extractChapter({
    required String bookId,
    required String fileId,
    int chapter = 1,
  }) async {
    return await repository.extractText(
      bookId: bookId,
      fileId: fileId,
      chapter: chapter,
    );
  }
}

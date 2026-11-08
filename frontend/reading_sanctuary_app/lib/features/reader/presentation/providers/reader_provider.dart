import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reader_annotations.dart';
import '../../data/models/reader_document.dart';
import '../../data/models/reader_position.dart';
import '../../data/repositories/reader_repository.dart';
import '../../data/services/reader_file_service.dart';
import '../../domain/services/reader_position_service.dart';

final authTokenProvider = StateProvider<String?>((ref) => null);

final readerRepositoryProvider = Provider<ReaderRepository>((ref) {
  return HttpReaderRepository(
    tokenProvider: () => ref.read(authTokenProvider),
  );
});

final readerFileServiceProvider = Provider<ReaderFileService>((ref) {
  return ReaderFileService(
    tokenProvider: () => ref.read(authTokenProvider),
  );
});

final readerPositionServiceProvider = Provider<ReaderPositionService>((ref) {
  final repo = ref.watch(readerRepositoryProvider);
  final service = ReaderPositionService(repository: repo);
  ref.onDispose(service.dispose);
  return service;
});

class ReaderDocumentArgs {
  final String bookId;
  final String fileId;
  final String bookTitle;
  final String fileFormat;

  const ReaderDocumentArgs({
    required this.bookId,
    required this.fileId,
    required this.bookTitle,
    required this.fileFormat,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderDocumentArgs &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          fileId == other.fileId;

  @override
  int get hashCode => bookId.hashCode ^ fileId.hashCode;
}

final readerDocumentProvider =
    FutureProvider.family<ReaderDocument, ReaderDocumentArgs>((ref, args) async {
  final fileService = ref.read(readerFileServiceProvider);
  final repo = ref.read(readerRepositoryProvider);

  final bytesFuture = fileService.loadFileBytes(
    bookId: args.bookId,
    fileId: args.fileId,
  );
  final positionFuture = repo.getPosition(
    bookId: args.bookId,
    fileId: args.fileId,
  );

  final results = await Future.wait([bytesFuture, positionFuture]);
  final bytes = results[0] as List<int>;
  final position = results[1] as ReaderPosition?;

  return ReaderDocument(
    bookId: args.bookId,
    fileId: args.fileId,
    bookTitle: args.bookTitle,
    fileFormat: args.fileFormat,
    fileBytes: Uint8List.fromList(bytes),
    initialPosition: position,
  );
});

final readerCurrentPositionProvider =
    StateProvider.autoDispose<ReaderPosition?>((ref) => null);

final readerBookmarksProvider = FutureProvider.family<List<ReaderBookmark>, String>((ref, bookId) async {
  final repo = ref.read(readerRepositoryProvider);
  return repo.getBookmarks(bookId: bookId);
});

final readerHighlightsProvider = FutureProvider.family<List<ReaderHighlight>, String>((ref, bookId) async {
  final repo = ref.read(readerRepositoryProvider);
  return repo.getHighlights(bookId: bookId);
});

final readerNotesProvider = FutureProvider.family<List<ReaderBookNote>, String>((ref, bookId) async {
  final repo = ref.read(readerRepositoryProvider);
  return repo.getNotes(bookId: bookId);
});

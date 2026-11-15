import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/network_providers.dart';
import '../data/annotation_api.dart';
import '../data/annotation_repository.dart';
import '../domain/annotation_type.dart';
import '../domain/book_annotation.dart';

final annotationApiProvider = Provider<AnnotationApi>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnnotationApi(apiClient: apiClient);
});

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  final api = ref.watch(annotationApiProvider);
  return DefaultAnnotationRepository(api: api);
});

class BookFileAnnotationsNotifier extends StateNotifier<AsyncValue<List<BookAnnotation>>> {
  final AnnotationRepository _repository;
  final String bookFileId;
  final String bookId;

  BookFileAnnotationsNotifier({
    required AnnotationRepository repository,
    required this.bookFileId,
    required this.bookId,
  })  : _repository = repository,
        super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    try {
      final list = await _repository.getAnnotations(bookFileId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<BookAnnotation> addHighlight({
    required String selectedText,
    required String color,
    int? pageNumber,
    Map<String, dynamic>? locationData,
  }) async {
    final now = DateTime.now();
    final tempId = const Uuid().v4();
    final newAnnotation = BookAnnotation(
      id: tempId,
      bookId: bookId,
      bookFileId: bookFileId,
      type: AnnotationType.highlight,
      selectedText: selectedText,
      color: color,
      pageNumber: pageNumber,
      locationData: locationData ?? const {},
      createdAt: now,
      updatedAt: now,
      isPendingSync: true,
    );

    // Optimistic UI update
    final currentList = state.value ?? [];
    state = AsyncValue.data([...currentList, newAnnotation]);

    try {
      final saved = await _repository.saveAnnotation(newAnnotation);
      final updated = (state.value ?? [])
          .map((a) => a.id == tempId ? saved : a)
          .toList();
      state = AsyncValue.data(updated);
      return saved;
    } catch (e) {
      return newAnnotation;
    }
  }

  Future<BookAnnotation> addNote({
    String? selectedText,
    required String noteText,
    String? color,
    int? pageNumber,
    Map<String, dynamic>? locationData,
  }) async {
    final now = DateTime.now();
    final tempId = const Uuid().v4();
    final newAnnotation = BookAnnotation(
      id: tempId,
      bookId: bookId,
      bookFileId: bookFileId,
      type: AnnotationType.note,
      selectedText: selectedText,
      noteText: noteText,
      color: color,
      pageNumber: pageNumber,
      locationData: locationData ?? const {},
      createdAt: now,
      updatedAt: now,
      isPendingSync: true,
    );

    final currentList = state.value ?? [];
    state = AsyncValue.data([...currentList, newAnnotation]);

    try {
      final saved = await _repository.saveAnnotation(newAnnotation);
      final updated = (state.value ?? [])
          .map((a) => a.id == tempId ? saved : a)
          .toList();
      state = AsyncValue.data(updated);
      return saved;
    } catch (e) {
      return newAnnotation;
    }
  }

  Future<void> updateNote({
    required String id,
    required String noteText,
  }) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data([
      for (final a in currentList)
        if (a.id == id) a.copyWith(noteText: noteText, updatedAt: DateTime.now()) else a
    ]);

    try {
      final updated = await _repository.updateAnnotation(id, bookFileId, noteText: noteText);
      final reconciled = (state.value ?? [])
          .map((a) => a.id == id ? updated : a)
          .toList();
      state = AsyncValue.data(reconciled);
    } catch (_) {}
  }

  Future<void> updateColor({
    required String id,
    required String color,
  }) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data([
      for (final a in currentList)
        if (a.id == id) a.copyWith(color: color, updatedAt: DateTime.now()) else a
    ]);

    try {
      final updated = await _repository.updateAnnotation(id, bookFileId, color: color);
      final reconciled = (state.value ?? [])
          .map((a) => a.id == id ? updated : a)
          .toList();
      state = AsyncValue.data(reconciled);
    } catch (_) {}
  }

  Future<void> deleteAnnotation(String id) async {
    final currentList = state.value ?? [];
    state = AsyncValue.data(currentList.where((a) => a.id != id).toList());

    try {
      await _repository.deleteAnnotation(id, bookFileId);
    } catch (_) {}
  }
}

class BookAnnotationParams {
  final String bookId;
  final String bookFileId;

  const BookAnnotationParams({
    required this.bookId,
    required this.bookFileId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAnnotationParams &&
          runtimeType == other.runtimeType &&
          bookId == other.bookId &&
          bookFileId == other.bookFileId;

  @override
  int get hashCode => bookId.hashCode ^ bookFileId.hashCode;
}

final bookFileAnnotationsProvider = StateNotifierProvider.family<
    BookFileAnnotationsNotifier,
    AsyncValue<List<BookAnnotation>>,
    BookAnnotationParams>((ref, params) {
  final repo = ref.watch(annotationRepositoryProvider);
  return BookFileAnnotationsNotifier(
    repository: repo,
    bookFileId: params.bookFileId,
    bookId: params.bookId,
  );
});

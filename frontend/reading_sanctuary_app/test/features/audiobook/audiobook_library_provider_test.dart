import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/datasources/audiobook_local_datasource.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/datasources/audiobook_storage.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_track.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/pages/audiobook_library_page.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/providers/audiobook_library_provider.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/providers/audiobook_providers.dart';

class _InMemoryPersistentStorageBackend implements AudiobookStorageBackend {
  final Map<String, String> stores;
  bool throwOnInit;

  _InMemoryPersistentStorageBackend({
    Map<String, String>? initialStores,
    this.throwOnInit = false,
  }) : stores = initialStores ?? <String, String>{};

  @override
  Future<void> init() async {
    if (throwOnInit) {
      throw const AudiobookStorageException('Simulated storage initialization failure');
    }
  }

  @override
  Future<String?> readStore(String key) async => stores[key];

  @override
  Future<void> writeStore(String key, String value) async {
    stores[key] = value;
  }
}

Audiobook _makeBook({
  required String id,
  required String title,
  required String author,
  required AudiobookStatus status,
  required DateTime dateAdded,
}) {
  return Audiobook(
    id: id,
    title: title,
    author: author,
    totalDurationMs: 600000,
    totalTracks: 1,
    status: status,
    dateAdded: dateAdded,
  );
}

void main() {
  group('AudiobookLibraryProvider Regression Tests', () {
    test('handles empty audiobook collection without throwing on sort', () async {
      final storage = _InMemoryPersistentStorageBackend();
      final datasource = AudiobookLocalDatasource(storageBackend: storage);

      final container = ProviderContainer(
        overrides: [
          audiobookLocalDatasourceProvider.overrideWithValue(datasource),
        ],
      );
      addTearDown(container.dispose);

      await container.read(audiobookLibraryProvider.notifier).refresh();

      expect(container.read(audiobookLibraryProvider).allBooks, isEmpty);
      expect(container.read(filteredAudiobooksProvider), isEmpty);
      expect(container.read(currentAudiobooksProvider), isEmpty);
      expect(container.read(notStartedAudiobooksProvider), isEmpty);
      expect(container.read(completedAudiobooksProvider), isEmpty);
    });

    test('sorts unmodifiable datasource lists without mutating source collections', () async {
      final storage = _InMemoryPersistentStorageBackend();
      final datasource = AudiobookLocalDatasource(storageBackend: storage);
      await datasource.init();

      final b1 = _makeBook(
        id: 'b-1',
        title: 'Zebra Tales',
        author: 'Charlie',
        status: AudiobookStatus.current,
        dateAdded: DateTime(2026, 1, 1),
      );
      final b2 = _makeBook(
        id: 'b-2',
        title: 'Alpha Story',
        author: 'Alice',
        status: AudiobookStatus.notStarted,
        dateAdded: DateTime(2026, 1, 3),
      );
      final b3 = _makeBook(
        id: 'b-3',
        title: 'Middle Book',
        author: 'Bob',
        status: AudiobookStatus.completed,
        dateAdded: DateTime(2026, 1, 2),
      );

      for (final b in [b1, b2, b3]) {
        await datasource.saveAudiobook(b, [
          AudioTrack(
            id: 't-${b.id}',
            audiobookId: b.id,
            filePath: '/audio/${b.id}.mp3',
            fileName: '${b.id}.mp3',
            trackOrder: 1,
            durationMs: 10000,
            format: 'MP3',
          ),
        ]);
      }

      final container = ProviderContainer(
        overrides: [
          audiobookLocalDatasourceProvider.overrideWithValue(datasource),
        ],
      );
      addTearDown(container.dispose);

      await container.read(audiobookLibraryProvider.notifier).refresh();

      final stateBooks = container.read(audiobookLibraryProvider).allBooks;
      final originalOrderIds = stateBooks.map((b) => b.id).toList();

      // Default sort: recentlyAdded (newest dateAdded first)
      final defaultSorted = container.read(filteredAudiobooksProvider);
      expect(defaultSorted.map((b) => b.id).toList(), ['b-2', 'b-3', 'b-1']);

      // Verify source collection in provider state was NOT mutated
      expect(stateBooks.map((b) => b.id).toList(), originalOrderIds);
      // Verify source collection remains unmodifiable
      expect(() => stateBooks.sort((a, b) => a.id.compareTo(b.id)), throwsUnsupportedError);

      // Sort by title
      container.read(audiobookLibraryFilterProvider.notifier).setSortBy('title');
      final titleSorted = container.read(filteredAudiobooksProvider);
      expect(titleSorted.map((b) => b.id).toList(), ['b-2', 'b-3', 'b-1']);
      expect(stateBooks.map((b) => b.id).toList(), originalOrderIds);

      // Sort by author
      container.read(audiobookLibraryFilterProvider.notifier).setSortBy('author');
      final authorSorted = container.read(filteredAudiobooksProvider);
      expect(authorSorted.map((b) => b.id).toList(), ['b-2', 'b-3', 'b-1']);
      expect(stateBooks.map((b) => b.id).toList(), originalOrderIds);

      // Derived section providers also work without mutation
      expect(container.read(currentAudiobooksProvider).map((b) => b.id).toList(), ['b-1']);
      expect(container.read(notStartedAudiobooksProvider).map((b) => b.id).toList(), ['b-2']);
      expect(container.read(completedAudiobooksProvider).map((b) => b.id).toList(), ['b-3']);
    });

    test('filterAndSortAudiobooks is deterministic with tie-breakers on immutable lists', () {
      final sameDate = DateTime(2026, 2, 1);
      final source = List<Audiobook>.unmodifiable([
        _makeBook(id: 'b-3', title: 'Same', author: 'Same', status: AudiobookStatus.current, dateAdded: sameDate),
        _makeBook(id: 'b-1', title: 'Same', author: 'Same', status: AudiobookStatus.current, dateAdded: sameDate),
        _makeBook(id: 'b-2', title: 'Same', author: 'Same', status: AudiobookStatus.current, dateAdded: sameDate),
      ]);

      final sorted = filterAndSortAudiobooks(
        source,
        const AudiobookLibraryFilter(sortBy: 'title'),
      );

      expect(sorted.map((b) => b.id).toList(), ['b-1', 'b-2', 'b-3']);
      expect(source.map((b) => b.id).toList(), ['b-3', 'b-1', 'b-2']);
    });

    test('surfaces storage initialization failure in AudiobookLibraryState instead of crashing', () async {
      final failingStorage = _InMemoryPersistentStorageBackend(throwOnInit: true);
      final datasource = AudiobookLocalDatasource(storageBackend: failingStorage);

      final container = ProviderContainer(
        overrides: [
          audiobookLocalDatasourceProvider.overrideWithValue(datasource),
        ],
      );
      addTearDown(container.dispose);

      await container.read(audiobookLibraryProvider.notifier).refresh();
      final libState = container.read(audiobookLibraryProvider);

      expect(libState.isLoading, isFalse);
      expect(libState.errorMessage, isNotNull);
      expect(libState.errorMessage, contains('Simulated storage initialization failure'));
    });

    testWidgets('AudiobookLibraryPage renders safely with empty and populated unmodifiable lists', (tester) async {
      final storage = _InMemoryPersistentStorageBackend();
      final datasource = AudiobookLocalDatasource(storageBackend: storage);
      await datasource.init();
      await datasource.saveAudiobook(
        _makeBook(
          id: 'book-ui-1',
          title: 'Dune',
          author: 'Frank Herbert',
          status: AudiobookStatus.current,
          dateAdded: DateTime(2026, 5, 1),
        ),
        [
          const AudioTrack(
            id: 'track-ui-1',
            audiobookId: 'book-ui-1',
            filePath: 'https://example.com/dune.mp3',
            fileName: 'dune.mp3',
            trackOrder: 1,
            durationMs: 120000,
            format: 'MP3',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audiobookLocalDatasourceProvider.overrideWithValue(datasource),
          ],
          child: const MaterialApp(
            home: AudiobookLibraryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Audiobooks'), findsOneWidget);
      expect(find.text('Dune'), findsWidgets);
    });
  });
}

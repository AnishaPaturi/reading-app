import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/book.dart';
import 'data/discover_repository.dart';

final discoverRepositoryProvider = Provider<DiscoverRepository>((ref) => MockDiscoverRepository());
final catalogProvider = FutureProvider<List<Book>>((ref) => ref.read(discoverRepositoryProvider).getCatalog());

/// Query matches title, author, genre, series or trope. Selected tropes must ALL match.
List<Book> filterCatalog(List<Book> books,
    {String query = '', String? genre, Set<String> tropes = const {}, double minRating = 0}) {
  final q = query.trim().toLowerCase();
  return books.where((b) {
    final matchesQuery = q.isEmpty ||
        b.title.toLowerCase().contains(q) ||
        b.author.toLowerCase().contains(q) ||
        b.genre.toLowerCase().contains(q) ||
        (b.series?.toLowerCase().contains(q) ?? false) ||
        b.tropes.any((t) => t.toLowerCase().contains(q));
    final matchesGenre = genre == null || b.genre == genre;
    final matchesTropes = tropes.every(b.tropes.contains);
    final matchesRating = (b.avgRating ?? 0) >= minRating;
    return matchesQuery && matchesGenre && matchesTropes && matchesRating;
  }).toList();
}

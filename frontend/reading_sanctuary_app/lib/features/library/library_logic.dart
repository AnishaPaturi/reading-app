import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/book.dart';

List<Book> filterBooks(List<Book> books,
    {String query = '', Set<ReadingStatus> statuses = const {}}) {
  final q = query.trim().toLowerCase();
  return books.where((b) {
    final matchesQuery = q.isEmpty ||
        b.title.toLowerCase().contains(q) ||
        b.author.toLowerCase().contains(q) ||
        b.genre.toLowerCase().contains(q);
    final matchesStatus = statuses.isEmpty || statuses.contains(b.status);
    return matchesQuery && matchesStatus;
  }).toList();
}

final libraryQueryProvider = StateProvider<String>((ref) => '');
final libraryStatusFilterProvider = StateProvider<Set<ReadingStatus>>((ref) => {});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/services/providers.dart';
import '../../shared/models/book.dart';
import 'library_logic.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);
    final query = ref.watch(libraryQueryProvider);
    final statuses = ref.watch(libraryStatusFilterProvider);

    return booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          message: 'Could not load your library.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(booksProvider)),
      data: (books) {
        final shown = filterBooks(books, query: query, statuses: statuses);
        return CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: Text('${books.length} books',
                          style: Theme.of(context).textTheme.titleMedium)),
                  FilledButton.icon(
                    onPressed: () => context.push('/library/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Book'),
                  ),
                ]),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  onChanged: (v) => ref.read(libraryQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search title, author or genre',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _controller.clear();
                              ref.read(libraryQueryProvider.notifier).state = '';
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  for (final s in ReadingStatus.values)
                    FilterChip(
                      label: Text(s.label),
                      selected: statuses.contains(s),
                      onSelected: (on) => ref.read(libraryStatusFilterProvider.notifier).update(
                          (cur) => on ? {...cur, s} : ({...cur}..remove(s))),
                    ),
                  if (statuses.isNotEmpty)
                    TextButton(
                      onPressed: () =>
                          ref.read(libraryStatusFilterProvider.notifier).state = {},
                      child: const Text('Clear all filters'),
                    ),
                ]),
                const SizedBox(height: 20),
              ]),
            ),
          ),
          if (shown.isEmpty)
            const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.search_off, message: 'No books match your search.'))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  childAspectRatio: 0.52,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final b = shown[i];
                    return InkWell(
                      onTap: () => context.push('/book/${b.id}'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        BookCover(book: b),
                        const SizedBox(height: 8),
                        Text(b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(b.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 4),
                        StatusBadge(b.status),
                      ]),
                    );
                  },
                  childCount: shown.length,
                ),
              ),
            ),
        ]);
      },
    );
  }
}

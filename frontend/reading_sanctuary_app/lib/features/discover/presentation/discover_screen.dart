import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../shared/models/book.dart';
import '../../../shared/services/providers.dart';
import '../discover_logic.dart';
import 'discover_book_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = TextEditingController();
  String _query = '';
  String? _genre;
  final Set<String> _tropes = {};
  double _minRating = 0;
  final List<Book> _recentlyViewed = []; // session-only

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _filtering => _query.isNotEmpty || _genre != null || _tropes.isNotEmpty || _minRating > 0;

  void _clearAll() => setState(() {
        _controller.clear();
        _query = '';
        _genre = null;
        _tropes.clear();
        _minRating = 0;
      });

  void _add(Book b) {
    ref.read(booksProvider.notifier).addBook(b);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('"${b.title}" added to Want to Read')));
  }

  void _open(Book b, bool owned) {
    setState(() {
      _recentlyViewed.removeWhere((x) => x.id == b.id);
      _recentlyViewed.insert(0, b);
      if (_recentlyViewed.length > 8) _recentlyViewed.removeLast();
    });
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PreviewSheet(book: b, owned: owned, onAdd: () {
        Navigator.pop(context);
        _add(b);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);
    final owned = {...?ref.watch(booksProvider).valueOrNull?.map((b) => b.id)};
    final library = ref.watch(booksProvider).valueOrNull ?? const <Book>[];

    return catalogAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          message: 'Could not load discovery.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(catalogProvider)),
      data: (catalog) {
        final genres = ({for (final b in catalog) b.genre}.toList())..sort();
        final tropes = ({for (final b in catalog) ...b.tropes}.toList())..sort();
        final results = filterCatalog(catalog,
            query: _query, genre: _genre, tropes: _tropes, minRating: _minRating);

        Widget card(Book b, {double? width}) {
          final c = DiscoverBookCard(
              book: b, inLibrary: owned.contains(b.id), onOpen: () => _open(b, owned.contains(b.id)), onAdd: () => _add(b));
          return width == null ? c : SizedBox(width: width, child: c);
        }

        Widget shelf(String title, List<Book> items) => items.isEmpty
            ? const SizedBox.shrink()
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionHeader(title),
                SizedBox(
                  height: 395,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (_, i) => card(items[i], width: 140),
                  ),
                ),
              ]);

        final trending = ([...catalog]..sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0))).take(8).toList();
        final popular = catalog.where((b) => (b.avgRating ?? 0) >= 4.1).toList();
        final newReleases = ([...catalog]..sort((a, b) => b.addedAt.compareTo(a.addedAt))).take(6).toList();
        final libGenres = {for (final b in library) b.genre};
        final recommended = catalog
            .where((b) => !owned.contains(b.id) && libGenres.contains(b.genre))
            .toList();
        final authors = ({for (final b in catalog) b.author}.toList())..sort();
        final suggestions = _query.isEmpty
            ? <String>[]
            : [
                ...catalog.map((b) => b.title),
                ...authors,
                ...tropes,
              ].where((s) => s.toLowerCase().contains(_query.toLowerCase()) && s.toLowerCase() != _query.toLowerCase()).take(4).toList();

        return ListView(padding: const EdgeInsets.all(20), children: [
          TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search titles, authors, series or tropes',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _controller.clear();
                        _query = '';
                      })),
            ),
          ),
          for (final s in suggestions)
            ListTile(
              dense: true,
              leading: const Icon(Icons.north_west, size: 16),
              title: Text(s),
              onTap: () => setState(() {
                _controller.text = s;
                _controller.selection = TextSelection.collapsed(offset: s.length);
                _query = s;
              }),
            ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            DropdownButton<String?>(
              value: _genre,
              hint: const Text('Genre'),
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All genres')),
                for (final g in genres) DropdownMenuItem<String?>(value: g, child: Text(g)),
              ],
              onChanged: (v) => setState(() => _genre = v),
            ),
            FilterChip(
              label: const Text('4.0+ rating'),
              selected: _minRating >= 4,
              onSelected: (on) => setState(() => _minRating = on ? 4 : 0),
            ),
            if (_filtering) TextButton(onPressed: _clearAll, child: const Text('Clear all')),
          ]),
          const SizedBox(height: 8),
          Text('Tropes', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in tropes)
              FilterChip(
                label: Text(t),
                selected: _tropes.contains(t),
                onSelected: (on) => setState(() => on ? _tropes.add(t) : _tropes.remove(t)),
              ),
          ]),
          if (_filtering) ...[
            SectionHeader('${results.length} result${results.length == 1 ? '' : 's'}'),
            if (results.isEmpty)
              const SizedBox(
                  height: 240,
                  child: EmptyState(icon: Icons.search_off, message: 'No books match these filters.'))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190, mainAxisExtent: 455, crossAxisSpacing: 16, mainAxisSpacing: 16),
                itemCount: results.length,
                itemBuilder: (_, i) => card(results[i]),
              ),
          ] else ...[
            shelf('Trending', trending),
            shelf('New Releases', newReleases),
            shelf('Popular', popular),
            if (recommended.isNotEmpty) shelf('Recommended for You', recommended),
            if (_recentlyViewed.isNotEmpty) shelf('Recently Viewed', _recentlyViewed),
            const SectionHeader('Browse by Genre'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final g in genres)
                ActionChip(label: Text(g), onPressed: () => setState(() => _genre = g)),
            ]),
            const SectionHeader('Browse by Author'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final a in authors)
                ActionChip(
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: Text(a),
                    onPressed: () => setState(() {
                      _controller.text = a;
                      _query = a;
                    })),
            ]),
          ],
        ]);
      },
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  const _PreviewSheet({required this.book, required this.owned, required this.onAdd});
  final Book book;
  final bool owned;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 96, child: BookCover(book: book)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(book.title, style: t.titleLarge),
                Text('by ${book.author}'),
                if (book.series != null) Text(book.series!, style: t.bodySmall),
                const SizedBox(height: 6),
                Row(children: [
                  RatingStars(book.avgRating),
                  const SizedBox(width: 6),
                  Text(book.avgRating?.toStringAsFixed(1) ?? ''),
                ]),
                Text('${book.genre} · ${book.pages} pages', style: t.bodySmall),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final tr in book.tropes) Chip(label: Text(tr))]),
          const SizedBox(height: 12),
          Text(book.description, style: t.bodyLarge),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: owned
                ? const OutlinedButton(onPressed: null, child: Text('Already in your library'))
                : FilledButton(onPressed: onAdd, child: const Text('Add to Library')),
          ),
        ]),
      ),
    );
  }
}

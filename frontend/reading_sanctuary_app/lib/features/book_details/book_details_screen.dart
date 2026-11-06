import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/book.dart';
import '../../shared/services/providers.dart';

class BookDetailsScreen extends ConsumerWidget {
  const BookDetailsScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(booksProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const EmptyState(icon: Icons.error_outline, message: 'Could not load book.'),
      data: (books) {
        final matches = books.where((b) => b.id == bookId);
        if (matches.isEmpty) {
          return const EmptyState(icon: Icons.search_off, message: 'Book not found.');
        }
        final b = matches.first;
        final t = Theme.of(context).textTheme;

        void setStatus(ReadingStatus s) {
          ref.read(booksProvider.notifier).setStatus(b.id, s);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('"${b.title}" moved to ${s.label}')));
        }

        final info = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.title, style: t.headlineLarge),
          Text('by ${b.author}', style: t.titleMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            StatusBadge(b.status),
            RatingStars(b.rating),
            Text('${b.genre} · ${b.pages} pages'),
          ]),
          const SizedBox(height: 16),
          if (b.progress > 0 && b.progress < 1) ...[
            ProgressBar(b.progress),
            const SizedBox(height: 4),
            Text('${(b.progress * 100).round()}% · page ${b.currentPage} of ${b.pages}',
                style: t.bodySmall),
            const SizedBox(height: 16),
          ],
          Wrap(spacing: 10, runSpacing: 10, children: [
            if (b.formats.contains(BookFormat.ebook))
              FilledButton.icon(
                  onPressed: () => context.go('/read'),
                  icon: const Icon(Icons.menu_book),
                  label: Text(b.progress > 0 ? 'Continue Reading' : 'Read Now')),
            if (b.formats.contains(BookFormat.audiobook))
              OutlinedButton.icon(
                  onPressed: () => context.go('/read'),
                  icon: const Icon(Icons.headphones),
                  label: const Text('Listen Now')),
          ]),
          const SectionHeader('About the Book'),
          Text(b.description, style: t.bodyLarge),
          const SectionHeader('Reading Status'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in ReadingStatus.values)
              ChoiceChip(
                label: Text(s.label),
                selected: b.status == s,
                onSelected: (_) => setStatus(s),
              ),
          ]),
          const SizedBox(height: 8),
          Text('Changing status never removes notes, highlights or history.', style: t.bodySmall),
        ]);

        return LayoutBuilder(builder: (context, box) {
          final wide = box.maxWidth >= 720;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 240, child: BookCover(book: b)),
                    const SizedBox(width: 32),
                    Expanded(child: info),
                  ])
                : Column(children: [
                    SizedBox(width: 200, child: BookCover(book: b)),
                    const SizedBox(height: 24),
                    info,
                  ]),
          );
        });
      },
    );
  }
}

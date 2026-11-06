import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/book.dart';
import '../../shared/services/providers.dart';

String _greeting() {
  final h = DateTime.now().hour;
  final part = h < 12 ? 'morning' : (h < 18 ? 'afternoon' : 'evening');
  return 'Good $part, Reader.';
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(booksProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
              icon: Icons.error_outline,
              message: 'Something went wrong loading your books.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(booksProvider)),
          data: (books) {
            if (books.isEmpty) {
              return EmptyState(
                  icon: Icons.menu_book_outlined,
                  message: 'Your sanctuary is waiting for its first story.',
                  actionLabel: 'Add Your First Book',
                  onAction: () => context.push('/library/add'));
            }
            return LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth >= 1000;
              final main = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _ContinueReading(books: books),
                _RecentlyAdded(books: books),
              ]);
              const side = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _GoalsCard(),
                _QuickActions(),
              ]);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_greeting(), style: Theme.of(context).textTheme.headlineMedium),
                  Text(DateFormat('EEEE, d MMMM').format(DateTime.now())),
                  wide
                      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: main),
                          const SizedBox(width: 28),
                          const SizedBox(width: 340, child: side),
                        ])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [main, side]),
                ]),
              );
            });
          },
        );
  }
}

class _ContinueReading extends ConsumerWidget {
  const _ContinueReading({required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = books.where((b) => b.status == ReadingStatus.currentlyReading).toList()
      ..sort((a, b) => (b.lastOpenedAt ?? DateTime(0)).compareTo(a.lastOpenedAt ?? DateTime(0)));

    void move(Book b, ReadingStatus s) {
      ref.read(booksProvider.notifier).setStatus(b.id, s);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('"${b.title}" moved to ${s.label}')));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('Continue Reading',
          actionLabel: 'View all', onAction: () => context.go('/tracker/reading')),
      if (reading.isEmpty)
        const Text('Nothing in progress. Pick something from your library.')
      else
        LayoutBuilder(builder: (context, box) {
          final cols = box.maxWidth >= 640 ? 2 : 1;
          final w = (box.maxWidth - (cols - 1) * 16) / cols;
          return Wrap(spacing: 16, runSpacing: 16, children: [
            for (final b in reading)
              SizedBox(
                width: w,
                child: SanctuaryCard(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 72, child: BookCover(book: b)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                              child: Text(b.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge)),
                          PopupMenuButton<String>(
                            tooltip: 'More options',
                            onSelected: (v) {
                              switch (v) {
                                case 'done':
                                  move(b, ReadingStatus.completed);
                                case 'hold':
                                  move(b, ReadingStatus.onHold);
                                case 'dnf':
                                  move(b, ReadingStatus.dnf);
                                case 'remove':
                                  move(b, ReadingStatus.wantToRead);
                                case 'details':
                                  context.push('/book/${b.id}');
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'done', child: Text('Mark as Completed')),
                              PopupMenuItem(value: 'hold', child: Text('Move to On Hold')),
                              PopupMenuItem(value: 'dnf', child: Text('Move to DNF')),
                              PopupMenuItem(value: 'remove', child: Text('Remove from Currently Reading')),
                              PopupMenuItem(value: 'details', child: Text('Open Book Details')),
                            ],
                          ),
                        ]),
                        Text(b.author, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 10),
                        ProgressBar(b.progress),
                        const SizedBox(height: 4),
                        Text(
                            '${(b.progress * 100).round()}% · p. ${b.currentPage}/${b.pages} · ${timeAgo(b.lastOpenedAt)}',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 10),
                        Wrap(spacing: 8, children: [
                          FilledButton(
                              onPressed: () => context.go('/read'),
                              child: const Text('Continue Reading')),
                          TextButton(
                              onPressed: () => context.push('/book/${b.id}'),
                              child: const Text('Details')),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
          ]);
        }),
    ]);
  }
}

class _RecentlyAdded extends StatelessWidget {
  const _RecentlyAdded({required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    final recent = ([...books]..sort((a, b) => b.addedAt.compareTo(a.addedAt))).take(8).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader('Recently Added', actionLabel: 'Library', onAction: () => context.go('/library')),
      SizedBox(
        height: 250,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: recent.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (context, i) {
            final b = recent[i];
            return SizedBox(
              width: 120,
              child: InkWell(
                onTap: () => context.push('/book/${b.id}'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  BookCover(book: b),
                  const SizedBox(height: 8),
                  Text(b.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(
                      '${b.formats.map((f) => f.name).join(' + ')} · ${DateFormat.MMMd().format(b.addedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader('Reading Goals'),
      SanctuaryCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily · 20 / 30 min'),
          const SizedBox(height: 6),
          const ProgressBar(20 / 30),
          const SizedBox(height: 14),
          const Text('Weekly · 3 / 5 hours'),
          const SizedBox(height: 6),
          const ProgressBar(3 / 5),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.local_fire_department_outlined, color: AppColors.gold),
            const SizedBox(width: 6),
            Text('12-day streak', style: t.titleSmall),
          ]),
          const SizedBox(height: 8),
          Text('Sample data until goals are built (Milestone 5).', style: t.bodySmall),
          Wrap(children: [
            TextButton(onPressed: () => context.push('/settings'), child: const Text('Edit Goal')),
            TextButton(onPressed: () => context.go('/statistics'), child: const Text('View Statistics')),
          ]),
        ]),
      ),
    ]);
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    Widget a(String label, IconData icon, String path) => OutlinedButton.icon(
        onPressed: () => context.push(path), icon: Icon(icon, size: 18), label: Text(label));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionHeader('Quick Actions'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        a('Upload Book', Icons.upload_file, '/library/add'),
        a('Add Manually', Icons.edit_outlined, '/library/add-manual'),
        a('Browse Library', Icons.local_library_outlined, '/library'),
        a('Journal Entry', Icons.edit_note, '/journal/new'),
        a('View TBR', Icons.bookmark_add_outlined, '/tracker/tbr'),
        a('Statistics', Icons.insights_outlined, '/statistics'),
      ]),
    ]);
  }
}

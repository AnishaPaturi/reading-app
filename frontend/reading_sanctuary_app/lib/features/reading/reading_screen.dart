import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/time_ago.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/book.dart';
import '../../shared/services/providers.dart';

/// "Reading" tab: what you are reading now and what you have paused.
class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(booksProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(
              icon: Icons.error_outline,
              message: 'Could not load your reading list.',
              actionLabel: 'Retry',
              onAction: () => ref.invalidate(booksProvider)),
          data: (books) {
            Widget section(String title, ReadingStatus s, String empty, String cta) {
              final list = books.where((b) => b.status == s).toList();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionHeader(title),
                if (list.isEmpty)
                  SanctuaryCard(child: Row(children: [
                    Expanded(child: Text(empty)),
                    TextButton(onPressed: () => context.go('/discover'), child: Text(cta)),
                  ]))
                else
                  for (final b in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SanctuaryCard(
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          SizedBox(width: 64, child: BookCover(book: b)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(b.title, style: Theme.of(context).textTheme.titleLarge),
                              Text(b.author, style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 8),
                              ProgressBar(b.progress),
                              const SizedBox(height: 4),
                              Text('${(b.progress * 100).round()}% · p. ${b.currentPage}/${b.pages} · ${timeAgo(b.lastOpenedAt)}',
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, children: [
                                FilledButton(
                                    onPressed: () => context.push(
                                        '/reader/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&format=PDF'),
                                    child: Text(s == ReadingStatus.onHold ? 'Resume' : 'Continue Reading')),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    final hasAudio = b.formats.contains(BookFormat.audiobook);
                                    if (hasAudio) {
                                      context.push(
                                        '/listen/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&author=${Uri.encodeComponent(b.author)}&format=MP3',
                                      );
                                    } else {
                                      context.push(
                                        '/listen/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&author=${Uri.encodeComponent(b.author)}&format=PDF&mode=tts',
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    b.formats.contains(BookFormat.audiobook)
                                        ? Icons.headphones
                                        : Icons.record_voice_over_outlined,
                                    size: 16,
                                  ),
                                  label: Text(
                                    b.formats.contains(BookFormat.audiobook)
                                        ? 'Listen'
                                        : 'Listen (TTS)',
                                  ),
                                ),
                                TextButton(
                                    onPressed: () => context.push('/book/${b.id}'), child: const Text('Details')),
                              ]),
                            ]),
                          ),
                        ]),
                      ),
                    ),
              ]);
            }

            return ListView(padding: const EdgeInsets.all(20), children: [
              section('Currently Reading', ReadingStatus.currentlyReading, 'Nothing in progress.', 'Find a book'),
              section('On Hold', ReadingStatus.onHold, 'No paused books.', 'Discover'),
            ]);
          },
        );
  }
}

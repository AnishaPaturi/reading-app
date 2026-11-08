import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/book.dart';
import '../../shared/services/providers.dart';

class BookDetailsScreen extends ConsumerStatefulWidget {
  const BookDetailsScreen({super.key, required this.bookId});
  final String bookId;
  @override
  ConsumerState<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends ConsumerState<BookDetailsScreen> {
  // Session-only until the review/ratings model exists in a later milestone.
  final Map<String, int> _ratings = {'Spice': 0, 'Fluff': 0, 'Tear': 0, 'Humor': 0};
  int _format = 0;
  bool? _readAgain;

  @override
  Widget build(BuildContext context) {
    return ref.watch(booksProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const EmptyState(icon: Icons.error_outline, message: 'Could not load book.'),
      data: (books) {
        final matches = books.where((b) => b.id == widget.bookId);
        if (matches.isEmpty) return const EmptyState(icon: Icons.search_off, message: 'Book not found.');
        final b = matches.first;
        final t = Theme.of(context).textTheme;
        final headerColor = Color.lerp(b.coverColors.first, Colors.white, .22)!;

        void setStatus(ReadingStatus s) {
          ref.read(booksProvider.notifier).setStatus(b.id, s);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('"${b.title}" moved to ${s.label}')));
        }

        Future<void> updatePage() async {
          final page = await showDialog<int>(
              context: context, builder: (_) => _PageKeypad(current: b.currentPage, total: b.pages));
          if (page != null && mounted) {
            ref.read(booksProvider.notifier).setProgress(b.id, page / b.pages);
          }
        }

        final formats = [
          ('Book', Icons.menu_book_outlined, true),
          ('eBook', Icons.tablet_mac_outlined, b.formats.contains(BookFormat.ebook)),
          ('Audiobook', Icons.headphones, b.formats.contains(BookFormat.audiobook)),
        ];

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  color: headerColor,
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    SizedBox(width: 84, child: BookCover(book: b)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.title,
                            style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(b.author, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 6),
                        Text(
                            b.status == ReadingStatus.completed
                                ? 'Finished: ${DateFormat.yMMMd().format(b.lastOpenedAt ?? b.addedAt)}'
                                : 'Added: ${DateFormat.yMMMd().format(b.addedAt)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Format:', style: t.bodySmall),
                    const SizedBox(height: 8),
                    Row(children: [
                      for (var i = 0; i < formats.length; i++)
                        Expanded(
                          child: Opacity(
                            opacity: formats[i].$3 ? 1 : .35,
                            child: InkWell(
                              onTap: formats[i].$3 ? () => setState(() => _format = i) : null,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _format == i ? AppColors.gold.withAlpha(45) : null,
                                  border: Border.all(
                                      color: _format == i ? AppColors.gold : AppColors.gold.withAlpha(60)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(children: [
                                  Icon(formats[i].$2),
                                  const SizedBox(height: 4),
                                  Text(formats[i].$1, style: t.labelSmall),
                                ]),
                              ),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 20),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      FilledButton.icon(
                        onPressed: () {
                          if (_format == 2) {
                            context.push('/read');
                          } else {
                            final formatName = _format == 1 ? 'EPUB' : 'PDF';
                            context.push(
                              '/reader/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&format=$formatName',
                            );
                          }
                        },
                        icon: Icon(_format == 2 ? Icons.headphones : Icons.menu_book),
                        label: Text(_format == 2
                            ? 'Listen Now'
                            : (b.progress > 0 ? 'Continue Reading' : 'Read Now')),
                      ),
                      OutlinedButton.icon(
                        onPressed: updatePage,
                        icon: const Icon(Icons.dialpad),
                        label: const Text('Update page'),
                      ),
                    ]),
                    if (b.progress > 0 && b.progress < 1) ...[
                      const SizedBox(height: 14),
                      ProgressBar(b.progress),
                      const SizedBox(height: 4),
                      Text('${(b.progress * 100).round()}% · page ${b.currentPage} of ${b.pages}',
                          style: t.bodySmall),
                    ],
                    const SizedBox(height: 24),
                    Center(child: Text('Overall Rating', style: t.bodySmall)),
                    const SizedBox(height: 4),
                    Center(child: RatingStars(b.rating, size: 22)),
                    const SizedBox(height: 16),
                    Wrap(spacing: 24, runSpacing: 16, children: [
                      _IconRating('Spice', Icons.local_fire_department_outlined, Icons.local_fire_department,
                          const Color(0xFFE8613C), _ratings['Spice']!, (v) => setState(() => _ratings['Spice'] = v)),
                      _IconRating('Fluff', Icons.favorite_border, Icons.favorite,
                          AppColors.gold, _ratings['Fluff']!, (v) => setState(() => _ratings['Fluff'] = v)),
                      _IconRating('Tear', Icons.water_drop_outlined, Icons.water_drop,
                          const Color(0xFF4FA3D9), _ratings['Tear']!, (v) => setState(() => _ratings['Tear'] = v)),
                      _IconRating('Humor', Icons.workspace_premium_outlined, Icons.workspace_premium,
                          const Color(0xFFE6A23C), _ratings['Humor']!, (v) => setState(() => _ratings['Humor'] = v)),
                    ]),
                    const SizedBox(height: 16),
                    Text('Would you read this book again?', style: t.bodySmall),
                    Row(children: [
                      IconButton(
                        tooltip: 'Yes',
                        isSelected: _readAgain == true,
                        icon: const Icon(Icons.thumb_up_outlined),
                        selectedIcon: const Icon(Icons.thumb_up, color: AppColors.gold),
                        onPressed: () => setState(() => _readAgain = true),
                      ),
                      IconButton(
                        tooltip: 'No',
                        isSelected: _readAgain == false,
                        icon: const Icon(Icons.thumb_down_outlined),
                        selectedIcon: const Icon(Icons.thumb_down, color: AppColors.gold),
                        onPressed: () => setState(() => _readAgain = false),
                      ),
                    ]),
                    const SectionHeader('About the Book'),
                    Text('${b.genre} · ${b.pages} pages', style: t.bodySmall),
                    const SizedBox(height: 6),
                    Text(b.description, style: t.bodyLarge),
                    const SectionHeader('Reading Status'),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final s in ReadingStatus.values)
                        ChoiceChip(
                            label: Text(s.label), selected: b.status == s, onSelected: (_) => setStatus(s)),
                    ]),
                    const SizedBox(height: 8),
                    Text('Changing status never removes notes, highlights or history.', style: t.bodySmall),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _IconRating extends StatelessWidget {
  const _IconRating(this.label, this.empty, this.filled, this.color, this.value, this.onChanged);
  final String label;
  final IconData empty;
  final IconData filled;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label Rating', style: Theme.of(context).textTheme.bodySmall),
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              tooltip: '$label $i of 5',
              visualDensity: VisualDensity.compact,
              // tapping the current value clears it
              onPressed: () => onChanged(value == i ? 0 : i),
              icon: Icon(i <= value ? filled : empty, color: i <= value ? color : null, size: 22),
            ),
        ]),
      ]);
}

class _PageKeypad extends StatefulWidget {
  const _PageKeypad({required this.current, required this.total});
  final int current;
  final int total;
  @override
  State<_PageKeypad> createState() => _PageKeypadState();
}

class _PageKeypadState extends State<_PageKeypad> {
  String _v = '';

  void _tap(String k) => setState(() {
        if (k == '<') {
          if (_v.isNotEmpty) _v = _v.substring(0, _v.length - 1);
        } else if (_v.length < 5) {
          _v += k;
        }
      });

  @override
  Widget build(BuildContext context) {
    final n = int.tryParse(_v);
    final valid = n != null && n >= 0 && n <= widget.total;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Set Current Page Number', style: Theme.of(context).textTheme.titleMedium),
          Text('Your current saved page is ${widget.current} out of ${widget.total}',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                border: Border.all(color: valid || _v.isEmpty ? AppColors.gold : Theme.of(context).colorScheme.error),
                borderRadius: BorderRadius.circular(6)),
            child: Text(_v.isEmpty ? '—' : _v,
                textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          ),
          if (_v.isNotEmpty && !valid)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Enter a page from 0 to ${widget.total}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', '<']])
            Row(children: [
              for (final k in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: k.isEmpty
                        ? const SizedBox(height: 48)
                        : OutlinedButton(
                            onPressed: () => _tap(k),
                            child: k == '<' ? const Icon(Icons.backspace_outlined, size: 18) : Text(k),
                          ),
                  ),
                ),
            ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip'))),
            Expanded(
                child: FilledButton(
                    onPressed: valid ? () => Navigator.pop(context, n) : null, child: const Text('Submit'))),
          ]),
        ]),
      ),
    );
  }
}

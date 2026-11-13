import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/book_cover.dart';
import '../../core/widgets/clay_components.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/book.dart';
import '../../shared/services/providers.dart';
import '../library/theme/bookshelf_theme.dart';
import '../offline/presentation/widgets/offline_download_button.dart';

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
      loading: () => const Scaffold(
        backgroundColor: ClayColors.background,
        body: Center(child: CircularProgressIndicator(color: ClayColors.deepPurple)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: ClayColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
            onPressed: () => context.canPop() ? context.pop() : context.go('/library'),
          ),
        ),
        body: const EmptyState(icon: Icons.error_outline, message: 'Could not load book.'),
      ),
      data: (books) {
        final matches = books.where((b) => b.id == widget.bookId);
        if (matches.isEmpty) {
          return Scaffold(
            backgroundColor: ClayColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
                onPressed: () => context.canPop() ? context.pop() : context.go('/library'),
              ),
            ),
            body: const EmptyState(icon: Icons.search_off, message: 'Book not found.'),
          );
        }
        final b = matches.first;

        void setStatus(ReadingStatus s) {
          ref.read(booksProvider.notifier).setStatus(b.id, s);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${b.title}" moved to ${s.label}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }

        Future<void> updatePage() async {
          final page = await showDialog<int>(
            context: context,
            builder: (_) => _PageKeypad(current: b.currentPage, total: b.pages),
          );
          if (page != null && mounted) {
            ref.read(booksProvider.notifier).setProgress(b.id, page / b.pages);
          }
        }

        final formats = [
          ('Book', Icons.menu_book_rounded, true),
          ('eBook', Icons.tablet_mac_rounded, b.formats.contains(BookFormat.ebook)),
          ('Audiobook', Icons.headphones_rounded, b.formats.contains(BookFormat.audiobook)),
        ];

        return Scaffold(
          backgroundColor: ClayColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
              tooltip: 'Back',
              onPressed: () => context.canPop() ? context.pop() : context.go('/library'),
            ),
            title: Text(
              'Book Details',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ClayColors.textDark,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  (b.rating ?? 0) >= 4.0 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: (b.rating ?? 0) >= 4.0 ? ClayColors.coral : ClayColors.textDark,
                ),
                tooltip: 'Favorite',
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Book Card with Claymorphic Container
                      ClayCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 96,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BookCover(book: b),
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: ClayColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    b.author,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: ClayColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ClayColors.lavender.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          b.genre,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: ClayColors.deepPurple,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: ClayColors.mint.withValues(alpha: 0.35),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${b.pages} pages',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: ClayColors.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    b.status == ReadingStatus.completed
                                        ? 'Finished: ${DateFormat.yMMMd().format(b.lastOpenedAt ?? b.addedAt)}'
                                        : 'Added: ${DateFormat.yMMMd().format(b.addedAt)}',
                                    style: GoogleFonts.inter(
                                      color: ClayColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Format Selector in Clay Tiles
                      Text(
                        'Available Formats',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: ClayColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          for (var i = 0; i < formats.length; i++)
                            Expanded(
                              child: Opacity(
                                opacity: formats[i].$3 ? 1 : .4,
                                child: InkWell(
                                  onTap: formats[i].$3 ? () => setState(() => _format = i) : null,
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    margin: EdgeInsets.only(right: i < formats.length - 1 ? 10 : 0),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _format == i ? ClayColors.deepPurple : Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _format == i
                                              ? ClayColors.deepPurple.withValues(alpha: 0.3)
                                              : Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: _format == i ? ClayColors.deepPurple : const Color(0xFFE5DCF4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          formats[i].$2,
                                          color: _format == i ? Colors.white : ClayColors.deepPurple,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          formats[i].$1,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _format == i ? Colors.white : ClayColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_format == 2) {
                                context.push(
                                  '/listen/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&author=${Uri.encodeComponent(b.author)}&format=MP3',
                                );
                              } else {
                                final formatName = _format == 1 ? 'EPUB' : 'PDF';
                                context.push(
                                  '/reader/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&format=$formatName',
                                );
                              }
                            },
                            icon: Icon(
                              _format == 2 ? Icons.headphones_rounded : Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              _format == 2
                                  ? 'Listen Now'
                                  : (b.progress > 0 ? 'Continue Reading' : 'Read Now'),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ClayColors.deepPurple,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 2,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final hasAudio = b.formats.contains(BookFormat.audiobook);
                              if (hasAudio && _format != 1 && _format != 0) {
                                context.push(
                                  '/listen/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&author=${Uri.encodeComponent(b.author)}&format=MP3',
                                );
                              } else {
                                final formatName = _format == 1 ? 'EPUB' : 'PDF';
                                context.push(
                                  '/listen/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&author=${Uri.encodeComponent(b.author)}&format=$formatName&mode=tts',
                                );
                              }
                            },
                            icon: Icon(
                              b.formats.contains(BookFormat.audiobook) && _format != 1 && _format != 0
                                  ? Icons.headphones_rounded
                                  : Icons.record_voice_over_rounded,
                              color: ClayColors.deepPurple,
                              size: 18,
                            ),
                            label: Text(
                              b.formats.contains(BookFormat.audiobook) && _format != 1 && _format != 0
                                  ? 'Audiobook'
                                  : 'Text-to-Speech',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ClayColors.deepPurple),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(color: Color(0xFFDDD2F5), width: 1.5),
                              ),
                              elevation: 1,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: updatePage,
                            icon: const Icon(Icons.dialpad_rounded, color: ClayColors.textDark, size: 18),
                            label: Text(
                              'Update page',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ClayColors.textDark),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              side: const BorderSide(color: Color(0xFFDDD2F5), width: 1.5),
                              backgroundColor: Colors.white,
                            ),
                          ),
                          OfflineDownloadButton(
                            bookId: b.id,
                            fileId: b.id,
                            bookTitle: b.title,
                            fileName:
                                '${b.title.replaceAll(RegExp(r'[^\w\s]+'), '').trim()}.${_format == 1 ? 'epub' : (_format == 2 ? 'mp3' : 'pdf')}',
                            format: _format == 1 ? 'EPUB' : (_format == 2 ? 'MP3' : 'PDF'),
                          ),
                        ],
                      ),

                      if (b.progress > 0 && b.progress < 1) ...[
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: b.progress,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFDDD2F5),
                            valueColor: const AlwaysStoppedAnimation(ClayColors.coral),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(b.progress * 100).round()}% completed · page ${b.currentPage} of ${b.pages}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Rating & Moods
                      ClayCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Rating',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ClayColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(child: RatingStars(b.rating, size: 26)),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 20,
                              runSpacing: 14,
                              children: [
                                _IconRating('Spice', Icons.local_fire_department_outlined, Icons.local_fire_department_rounded,
                                    ClayColors.coral, _ratings['Spice']!, (v) => setState(() => _ratings['Spice'] = v)),
                                _IconRating('Fluff', Icons.favorite_border_rounded, Icons.favorite_rounded,
                                    const Color(0xFFF37C76), _ratings['Fluff']!, (v) => setState(() => _ratings['Fluff'] = v)),
                                _IconRating('Tear', Icons.water_drop_outlined, Icons.water_drop_rounded,
                                    const Color(0xFF67B5EC), _ratings['Tear']!, (v) => setState(() => _ratings['Tear'] = v)),
                                _IconRating('Humor', Icons.sentiment_very_satisfied_outlined, Icons.sentiment_very_satisfied_rounded,
                                    ClayColors.amber, _ratings['Humor']!, (v) => setState(() => _ratings['Humor'] = v)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Would you read this book again?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ClayColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('👍 Yes'),
                                  selected: _readAgain == true,
                                  onSelected: (_) => setState(() => _readAgain = true),
                                  selectedColor: ClayColors.lavender,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                const SizedBox(width: 10),
                                ChoiceChip(
                                  label: const Text('👎 No'),
                                  selected: _readAgain == false,
                                  onSelected: (_) => setState(() => _readAgain = false),
                                  selectedColor: ClayColors.lavender,
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // About the Book
                      ClayCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About the Book',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: ClayColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              b.description.isNotEmpty ? b.description : 'No description provided.',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                height: 1.5,
                                color: ClayColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Reading Status
                      ClayCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reading Status',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: ClayColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final s in ReadingStatus.values)
                                  ChoiceChip(
                                    label: Text(s.label),
                                    selected: b.status == s,
                                    onSelected: (_) => setStatus(s),
                                    selectedColor: ClayColors.deepPurple,
                                    labelStyle: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: b.status == s ? Colors.white : ClayColors.textDark,
                                    ),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: b.status == s ? ClayColors.deepPurple : const Color(0xFFDDD2F5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Changing status never removes notes, highlights or reading progress.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: ClayColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label Rating',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ClayColors.textMuted,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$label $i of 5',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onChanged(value == i ? 0 : i),
                  icon: Icon(
                    i <= value ? filled : empty,
                    color: i <= value ? color : const Color(0xFFC7BCE0),
                    size: 22,
                  ),
                ),
            ],
          ),
        ],
      );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set Current Page',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ClayColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Saved page is ${widget.current} of ${widget.total}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ClayColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7FE),
                border: Border.all(
                  color: valid || _v.isEmpty ? ClayColors.primaryPurple : Colors.redAccent,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _v.isEmpty ? '—' : _v,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
            ),
            if (_v.isNotEmpty && !valid)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Enter a page from 0 to ${widget.total}',
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '<']
            ])
              Row(
                children: [
                  for (final k in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: k.isEmpty
                          ? const SizedBox(height: 48)
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                side: const BorderSide(color: Color(0xFFE5DCF4)),
                                backgroundColor: const Color(0xFFFAF7FE),
                              ),
                              onPressed: () => _tap(k),
                              child: k == '<'
                                  ? const Icon(Icons.backspace_outlined, size: 18, color: ClayColors.textDark)
                                  : Text(
                                      k,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: ClayColors.textDark,
                                      ),
                                    ),
                            ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: ClayColors.textMuted),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClayColors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: valid ? () => Navigator.pop(context, n) : null,
                    child: Text(
                      'Save',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

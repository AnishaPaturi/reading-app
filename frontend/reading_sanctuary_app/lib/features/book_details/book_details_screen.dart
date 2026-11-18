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
import '../../shared/utils/book_file_navigation.dart';
import '../bookshelf/presentation/widgets/book_delete_dialog.dart';
import '../dnf/screens/dnf_cinematic_screen.dart';
import '../offline/presentation/widgets/offline_download_button.dart';
import 'widgets/edit_book_metadata_sheet.dart';

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

  void _showEnlargedCover(BuildContext context, Book book) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 380, maxHeight: 560),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BookCover(book: book, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditMetadata(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditBookMetadataSheet(book: book),
    );
  }

  Future<void> _handleDeleteBook(BuildContext context, Book book) async {
    final confirmed = await showBookDeleteDialog(context, book);
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(booksProvider.notifier).moveToDeleted(book.id);
      if (!context.mounted) return;

      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/library');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${book.title}" moved to Deleted'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: ClayColors.primaryPurple,
            onPressed: () {
              ref.read(booksProvider.notifier).restoreBook(book.id);
            },
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete book: $error'),
          backgroundColor: const Color(0xFF8B2635),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
          if (s == ReadingStatus.dnf) {
            DnfCinematicScreen.trigger(
              context,
              book: b,
              previousStatus: b.status,
            );
            return;
          }
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
                icon: const Icon(
                  Icons.edit_note_rounded,
                  color: ClayColors.deepPurple,
                  size: 26,
                ),
                tooltip: 'Edit Details',
                onPressed: () => _openEditMetadata(context, b),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: ClayColors.coral,
                ),
                tooltip: 'Move to Deleted',
                onPressed: () => _handleDeleteBook(context, b),
              ),
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
                            InkWell(
                              onTap: () => _showEnlargedCover(context, b),
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  SizedBox(
                                    width: 100,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: BookCover(book: b),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
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
                                      if (b.recommendation != null && b.recommendation!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFBF4E2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFE2C26E), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.thumb_up_alt_rounded, size: 12, color: Color(0xFF8A6D1C)),
                                              const SizedBox(width: 4),
                                              Text(
                                                b.recommendation!,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF8A6D1C),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (b.mood != null && b.mood!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEBF7F0),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFF8FD8A8), width: 1),
                                          ),
                                          child: Text(
                                            b.mood!,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF227042),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    b.status == ReadingStatus.completed
                                        ? 'Finished: ${DateFormat.yMMMd().format(b.completionDate ?? b.lastOpenedAt ?? b.addedAt)}'
                                        : (b.startDate != null
                                            ? 'Started: ${DateFormat.yMMMd().format(b.startDate!)}'
                                            : 'Added: ${DateFormat.yMMMd().format(b.addedAt)}'),
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
                                openBookAudio(context, b);
                              } else if (_format == 1) {
                                openBookInFormat(
                                  context,
                                  b,
                                  format: BookFileFormat.epub,
                                );
                              } else {
                                openBookInFormat(
                                  context,
                                  b,
                                  format: BookFileFormat.pdf,
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
                                openBookAudio(context, b);
                              } else {
                                final format = _format == 1 ? BookFileFormat.epub : BookFileFormat.pdf;
                                BookFile? docFile;
                                for (final file in b.files) {
                                  if (file.format == format) {
                                    docFile = file;
                                    break;
                                  }
                                }
                                docFile ??= b.files.where((f) => !f.format.isAudio).firstOrNull;
                                if (docFile == null || docFile.id.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No readable file is attached to "${b.title}". Please upload the file again.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final formatName = docFile.format.label;
                                context.push(
                                  '/listen/${b.id}/${docFile.id}?title=${Uri.encodeComponent(b.title)}&author=${Uri.encodeComponent(b.author)}&format=$formatName&mode=tts',
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
                            if (b.ratingOutOf100 != null) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 14),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF7FE),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: ClayColors.softLilac),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.analytics_outlined, size: 18, color: ClayColors.deepPurple),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Score out of 100',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${b.ratingOutOf100} / 100',
                                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: ClayColors.deepPurple),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (b.spiceRating != null && b.spiceRating! > 0) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF6F4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFFFDCD6)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.local_fire_department_rounded, size: 18, color: ClayColors.coral),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Spice Rating',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        for (var i = 1; i <= 5; i++)
                                          Icon(
                                            i <= b.spiceRating! ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
                                            color: i <= b.spiceRating! ? ClayColors.coral : const Color(0xFFE0C4BE),
                                            size: 18,
                                          ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${b.spiceRating} / 5',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: ClayColors.coral),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (b.tropes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Tropes & Themes',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: ClayColors.textDark),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: b.tropes.map((t) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0ECFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFDCD2F5)),
                                    ),
                                    child: Text(
                                      '#$t',
                                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: ClayColors.deepPurple),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
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

                      // Acquisition & Edition Details
                      ClayCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Acquisition & Edition',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: ClayColors.textDark,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () => _openEditMetadata(context, b),
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: ClayColors.deepPurple),
                                  label: Text(
                                    'Edit',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: ClayColors.deepPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Acquisition',
                              value: b.acquisitionMethod ?? 'Purchased',
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Purchase Price',
                              value: b.purchasePrice != null
                                  ? '${b.currency ?? '₹'} ${b.purchasePrice!.toStringAsFixed(2)}'
                                  : 'Not recorded',
                            ),
                            if (b.purchaseDate != null) ...[
                              const SizedBox(height: 10),
                              _buildDetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Purchase Date',
                                value: DateFormat.yMMMd().format(b.purchaseDate!),
                              ),
                            ],
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              icon: Icons.business_outlined,
                              label: 'Publisher',
                              value: b.publisher ?? 'Not specified',
                            ),
                            const SizedBox(height: 10),
                            _buildDetailRow(
                              icon: Icons.tag_rounded,
                              label: 'ISBN',
                              value: b.isbn ?? 'Not specified',
                            ),
                            if (b.startDate != null || b.completionDate != null) ...[
                              const Divider(height: 24, color: Color(0xFFE5DCF4)),
                              if (b.startDate != null) ...[
                                _buildDetailRow(
                                  icon: Icons.play_arrow_outlined,
                                  label: 'Reading Started',
                                  value: DateFormat.yMMMd().format(b.startDate!),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (b.completionDate != null) ...[
                                _buildDetailRow(
                                  icon: Icons.check_circle_outline_rounded,
                                  label: 'Reading Completed',
                                  value: DateFormat.yMMMd().format(b.completionDate!),
                                ),
                              ],
                            ],
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
                            if (b.status == ReadingStatus.dnf) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1614),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.4), width: 1.2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF2E1912),
                                      ),
                                      child: const Icon(
                                        Icons.local_fire_department_rounded,
                                        color: Color(0xFFFF9800),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Retired to DNF Sanctuary',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFFFE082),
                                            ),
                                          ),
                                          Text(
                                            b.dnfDate != null
                                                ? 'Parted ways on ${DateFormat.yMMMd().format(b.dnfDate!)}'
                                                : 'A story gracefully retired',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5,
                                              color: const Color(0xFFB0A4BC),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => DnfCinematicScreen.trigger(context, book: b),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFFFB74D),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      child: const Text('View Ceremony'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ClayColors.primaryPurple),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: ClayColors.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ClayColors.textDark,
          ),
        ),
      ],
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

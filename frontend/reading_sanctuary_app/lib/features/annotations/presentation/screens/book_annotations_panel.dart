import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../reader/data/models/reader_annotations.dart';
import '../../../reader/presentation/providers/reader_provider.dart';
import '../../domain/annotation_type.dart';
import '../../domain/book_annotation.dart';
import '../../providers/annotation_providers.dart';
import '../widgets/add_note_dialog.dart';
import '../widgets/annotation_card.dart';

class BookAnnotationsPanel extends ConsumerStatefulWidget {
  final String bookId;
  final String bookFileId;
  final String bookTitle;
  final int? currentPage;
  final ValueChanged<BookAnnotation> onSelectAnnotation;
  final ValueChanged<ReaderBookmark>? onSelectBookmark;

  const BookAnnotationsPanel({
    super.key,
    required this.bookId,
    required this.bookFileId,
    required this.bookTitle,
    this.currentPage,
    required this.onSelectAnnotation,
    this.onSelectBookmark,
  });

  @override
  ConsumerState<BookAnnotationsPanel> createState() => _BookAnnotationsPanelState();
}

class _BookAnnotationsPanelState extends ConsumerState<BookAnnotationsPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  BookAnnotationParams get _params => BookAnnotationParams(
        bookId: widget.bookId,
        bookFileId: widget.bookFileId,
      );

  Future<void> _handleAddStandaloneNote() async {
    final note = await AddNoteDialog.show(
      context,
      pageNumber: widget.currentPage,
    );

    if (note != null && note.trim().isNotEmpty) {
      await ref.read(bookFileAnnotationsProvider(_params).notifier).addNote(
            noteText: note.trim(),
            pageNumber: widget.currentPage,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final annotationsAsync = ref.watch(bookFileAnnotationsProvider(_params));
    final bookmarksAsync = ref.watch(readerBookmarksProvider(widget.bookId));
    final notifier = ref.read(bookFileAnnotationsProvider(_params).notifier);

    return Container(
      width: 380,
      color: ClayColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE5FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: ClayColors.deepPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Annotations',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: ClayColors.textDark,
                          ),
                        ),
                        Text(
                          widget.bookTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: ClayColors.textDark),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),

            // Tab Bar with 5 tabs: All, Highlights, Notes, Bookmarks, Quotes
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEBE5F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1.5),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: ClayColors.deepPurple,
                unselectedLabelColor: ClayColors.textMuted,
                labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Highlights'),
                  Tab(text: 'Notes'),
                  Tab(text: 'Bookmarks'),
                  Tab(text: 'Quotes'),
                ],
              ),
            ),

            // Add Standalone Note Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ElevatedButton.icon(
                onPressed: _handleAddStandaloneNote,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  widget.currentPage != null ? 'Add Note for Page ${widget.currentPage}' : 'Add Note',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClayColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Content Body
            Expanded(
              child: annotationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: ClayColors.deepPurple),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 32),
                      const SizedBox(height: 8),
                      Text('Failed to load annotations', style: GoogleFonts.inter(color: ClayColors.textMuted)),
                      TextButton(
                        onPressed: () => notifier.load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (annotations) {
                  final highlights = annotations.where((a) => a.type == AnnotationType.highlight).toList();
                  final notes = annotations.where((a) => a.type == AnnotationType.note).toList();
                  final quotes = annotations.where((a) => a.type == AnnotationType.quote).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. All
                      _buildAnnotationList(
                        annotations,
                        'No annotations yet',
                        'Select text in the reader to highlight, take notes, or save quotes.',
                      ),
                      // 2. Highlights
                      _buildAnnotationList(
                        highlights,
                        'No highlights yet',
                        'Select text and pick a color to highlight passages.',
                      ),
                      // 3. Notes
                      _buildAnnotationList(
                        notes,
                        'No notes yet',
                        'Tap "+ Add Note" or select a passage to save your thoughts.',
                      ),
                      // 4. Bookmarks
                      bookmarksAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: ClayColors.deepPurple),
                        ),
                        error: (err, _) => Center(
                          child: Text('Could not load bookmarks: $err', style: GoogleFonts.inter(color: ClayColors.textMuted)),
                        ),
                        data: (bookmarks) => _buildBookmarksList(bookmarks),
                      ),
                      // 5. Quotes
                      _buildAnnotationList(
                        quotes,
                        'No quotes yet',
                        'Select memorable passages and save them to your Quotes collection.',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList(List<ReaderBookmark> bookmarks) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFECE5FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_border_rounded, size: 36, color: ClayColors.deepPurple),
              ),
              const SizedBox(height: 14),
              Text(
                'No bookmarks yet',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: ClayColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap the ribbon icon in the reader toolbar to save your reading places.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        final title = b.label ?? (b.pageNumber != null ? 'Page ${b.pageNumber}' : 'Bookmark');

        return ClayCard(
          padding: const EdgeInsets.all(14),
          onTap: () {
            widget.onSelectBookmark?.call(b);
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE5F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bookmark_rounded, color: ClayColors.primaryPurple, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    if (b.note != null && b.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        b.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: ClayColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      b.pageNumber != null ? 'Page ${b.pageNumber}' : 'Section Marker',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ClayColors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                tooltip: 'Remove Bookmark',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Bookmark?'),
                      content: const Text('Remove this bookmark from your collection?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(readerRepositoryProvider).deleteBookmark(
                          bookId: widget.bookId,
                          bookmarkId: b.id,
                        );
                    ref.invalidate(readerBookmarksProvider(widget.bookId));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnnotationList(
    List<BookAnnotation> list,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFECE5FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded, size: 36, color: ClayColors.deepPurple),
              ),
              const SizedBox(height: 14),
              Text(
                emptyTitle,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: ClayColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final notifier = ref.read(bookFileAnnotationsProvider(_params).notifier);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final a = list[index];
        return AnnotationCard(
          annotation: a,
          onTapLocation: () {
            widget.onSelectAnnotation(a);
          },
          onEditNote: a.noteText != null
              ? () async {
                  final updatedNote = await AddNoteDialog.show(
                    context,
                    selectedText: a.selectedText,
                    pageNumber: a.pageNumber,
                    initialNote: a.noteText,
                    isEditing: true,
                  );
                  if (updatedNote != null) {
                    await notifier.updateNote(id: a.id, noteText: updatedNote);
                  }
                }
              : null,
          onChangeColor: (colorOpt) async {
            await notifier.updateColor(id: a.id, color: colorOpt.hex);
          },
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Annotation?'),
                content: const Text('This will remove this annotation from your account.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await notifier.deleteAnnotation(a.id);
            }
          },
        );
      },
    );
  }
}

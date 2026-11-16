import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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

  const BookAnnotationsPanel({
    super.key,
    required this.bookId,
    required this.bookFileId,
    required this.bookTitle,
    this.currentPage,
    required this.onSelectAnnotation,
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
    _tabController = TabController(length: 4, vsync: this);
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
    final notifier = ref.read(bookFileAnnotationsProvider(_params).notifier);

    return Container(
      width: 380,
      color: const Color(0xFFFBF9FE),
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

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Highlights'),
                  Tab(text: 'Notes'),
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
                  backgroundColor: ClayColors.deepPurple,
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
                      _buildAnnotationList(annotations, 'No annotations yet', 'Select text in the reader to highlight, take notes, or save quotes.'),
                      _buildAnnotationList(highlights, 'No highlights yet', 'Select text and pick a color to highlight passages.'),
                      _buildAnnotationList(notes, 'No notes yet', 'Tap "+ Add Note" or select a passage to save your thoughts.'),
                      _buildAnnotationList(quotes, 'No quotes yet', 'Select memorable passages and save them to your Quotes collection.'),
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

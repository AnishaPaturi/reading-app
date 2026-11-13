import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/reader_annotations.dart';

class ReaderAnnotationPanel extends StatefulWidget {
  final List<ReaderHighlight> highlights;
  final List<ReaderBookNote> notes;
  final ValueChanged<ReaderHighlight> onSelectHighlight;
  final ValueChanged<ReaderHighlight> onDeleteHighlight;
  final Function(String title, String content) onAddNote;
  final ValueChanged<ReaderBookNote> onDeleteNote;

  const ReaderAnnotationPanel({
    super.key,
    required this.highlights,
    required this.notes,
    required this.onSelectHighlight,
    required this.onDeleteHighlight,
    required this.onAddNote,
    required this.onDeleteNote,
  });

  @override
  State<ReaderAnnotationPanel> createState() => _ReaderAnnotationPanelState();
}

class _ReaderAnnotationPanelState extends State<ReaderAnnotationPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddNoteDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Book Note',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: ClayColors.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: GoogleFonts.inter(color: ClayColors.textMuted),
                filled: true,
                fillColor: const Color(0xFFFAF7FE),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              style: GoogleFonts.inter(color: ClayColors.textDark),
              decoration: InputDecoration(
                labelText: 'Content',
                labelStyle: GoogleFonts.inter(color: ClayColors.textMuted),
                filled: true,
                fillColor: const Color(0xFFFAF7FE),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDD2F5))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty && contentCtrl.text.trim().isNotEmpty) {
                widget.onAddNote(titleCtrl.text.trim(), contentCtrl.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: ClayColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TabBar(
                controller: _tabController,
                indicatorColor: ClayColors.deepPurple,
                labelColor: ClayColors.deepPurple,
                unselectedLabelColor: ClayColors.textMuted,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
                tabs: [
                  Tab(text: 'Highlights (${widget.highlights.length})'),
                  Tab(text: 'Notes (${widget.notes.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Highlights Tab
                  widget.highlights.isEmpty
                      ? Center(
                          child: Text(
                            'No highlights yet.',
                            style: GoogleFonts.inter(color: ClayColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          itemCount: widget.highlights.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final h = widget.highlights[index];
                            return Material(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFDDD2F5)),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 10,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: h.color.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                title: Text(
                                  '"${h.selectedText}"',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: ClayColors.textDark,
                                  ),
                                ),
                                subtitle: h.annotationNote != null
                                    ? Text(h.annotationNote!, style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted))
                                    : (h.pageNumber != null ? Text('Page ${h.pageNumber}', style: GoogleFonts.inter(fontSize: 11.5, color: ClayColors.textMuted)) : null),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: ClayColors.coral),
                                  onPressed: () => widget.onDeleteHighlight(h),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onSelectHighlight(h);
                                },
                              ),
                            );
                          },
                        ),

                  // Notes Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ElevatedButton.icon(
                          onPressed: _showAddNoteDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text('New Note', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClayColors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                        ),
                      ),
                      const Divider(color: Color(0xFFDDD2F5), height: 1),
                      Expanded(
                        child: widget.notes.isEmpty
                            ? Center(
                                child: Text(
                                  'No notes yet.',
                                  style: GoogleFonts.inter(color: ClayColors.textMuted),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                itemCount: widget.notes.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  final n = widget.notes[index];
                                  return Material(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: const BorderSide(color: Color(0xFFDDD2F5)),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        n.title,
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: ClayColors.textDark),
                                      ),
                                      subtitle: Text(
                                        n.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(fontSize: 12.5, color: ClayColors.textMuted),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: ClayColors.coral),
                                        onPressed: () => widget.onDeleteNote(n),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

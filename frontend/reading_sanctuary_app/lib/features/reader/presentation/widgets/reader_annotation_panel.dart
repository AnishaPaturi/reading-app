import 'package:flutter/material.dart';
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
        title: const Text('Add Book Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty && contentCtrl.text.trim().isNotEmpty) {
                widget.onAddNote(titleCtrl.text.trim(), contentCtrl.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Highlights (${widget.highlights.length})'),
                Tab(text: 'Notes (${widget.notes.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Highlights Tab
                  widget.highlights.isEmpty
                      ? const Center(child: Text('No highlights yet.'))
                      : ListView.separated(
                          itemCount: widget.highlights.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final h = widget.highlights[index];
                            return ListTile(
                              leading: Container(
                                width: 12,
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
                              ),
                              subtitle: h.annotationNote != null
                                  ? Text(h.annotationNote!)
                                  : (h.pageNumber != null ? Text('Page ${h.pageNumber}') : null),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => widget.onDeleteHighlight(h),
                              ),
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onSelectHighlight(h);
                              },
                            );
                          },
                        ),

                  // Notes Tab
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: OutlinedButton.icon(
                          onPressed: _showAddNoteDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('New Note'),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: widget.notes.isEmpty
                            ? const Center(child: Text('No notes yet.'))
                            : ListView.separated(
                                itemCount: widget.notes.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final n = widget.notes[index];
                                  return ListTile(
                                    title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      n.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      onPressed: () => widget.onDeleteNote(n),
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

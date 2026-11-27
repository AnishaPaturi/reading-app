import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/reader_annotations.dart';
import '../../data/models/reader_chapter.dart';

class ReaderSidebar extends StatefulWidget {
  final List<ReaderChapter> chapters;
  final List<ReaderBookmark> bookmarks;
  final ValueChanged<ReaderChapter> onSelectChapter;
  final ValueChanged<ReaderBookmark> onSelectBookmark;
  final ValueChanged<ReaderBookmark> onDeleteBookmark;
  final int? currentPage;

  const ReaderSidebar({
    super.key,
    this.chapters = const [],
    required this.bookmarks,
    required this.onSelectChapter,
    required this.onSelectBookmark,
    required this.onDeleteBookmark,
    this.currentPage,
  });

  @override
  State<ReaderSidebar> createState() => _ReaderSidebarState();
}

class _ReaderSidebarState extends State<ReaderSidebar> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: ClayColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDDD2F5)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: ClayColors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: ClayColors.textMuted,
                  labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.toc_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text('Contents (${widget.chapters.length})'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bookmark_rounded, size: 17),
                            const SizedBox(width: 6),
                            Text('Bookmarks (${widget.bookmarks.length})'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFFDDD2F5), height: 1),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContentsTab(),
                  _buildBookmarksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentsTab() {
    if (widget.chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, size: 48, color: ClayColors.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'No table of contents available.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: widget.chapters.length,
      itemBuilder: (context, index) {
        return _buildChapterTile(widget.chapters[index], depth: 0);
      },
    );
  }

  Widget _buildChapterTile(ReaderChapter chapter, {int depth = 0}) {
    final hasChildren = chapter.subchapters.isNotEmpty;
    final isCurrent = widget.currentPage != null && chapter.pageNumber == widget.currentPage;

    if (hasChildren) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrent ? ClayColors.deepPurple : const Color(0xFFDDD2F5),
              width: isCurrent ? 1.5 : 1.0,
            ),
          ),
          child: ExpansionTile(
            tilePadding: EdgeInsets.fromLTRB(12.0 + (depth * 10.0), 0, 12, 0),
            leading: Icon(
              Icons.folder_open_rounded,
              size: 20,
              color: isCurrent ? ClayColors.deepPurple : ClayColors.primaryPurple,
            ),
            title: Text(
              chapter.title,
              style: GoogleFonts.inter(
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
                fontSize: 13.5,
                color: isCurrent ? ClayColors.deepPurple : ClayColors.textDark,
              ),
            ),
            trailing: chapter.pageNumber != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ClayColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'p. ${chapter.pageNumber}',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: ClayColors.textMuted),
                    ),
                  )
                : null,
            children: chapter.subchapters.map((sub) => _buildChapterTile(sub, depth: depth + 1)).toList(),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isCurrent ? const Color(0xFFF2ECFC) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCurrent ? ClayColors.deepPurple : const Color(0xFFDDD2F5),
            width: isCurrent ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: EdgeInsets.fromLTRB(14.0 + (depth * 12.0), 2, 14, 2),
          leading: Icon(
            Icons.article_outlined,
            size: 18,
            color: isCurrent ? ClayColors.deepPurple : ClayColors.textMuted,
          ),
          title: Text(
            chapter.title,
            style: GoogleFonts.inter(
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
              color: isCurrent ? ClayColors.deepPurple : ClayColors.textDark,
            ),
          ),
          trailing: chapter.pageNumber != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ClayColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'p. ${chapter.pageNumber}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: ClayColors.textMuted),
                  ),
                )
              : null,
          onTap: () {
            Navigator.of(context).pop();
            widget.onSelectChapter(chapter);
          },
        ),
      ),
    );
  }

  Widget _buildBookmarksTab() {
    if (widget.bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_border_rounded, size: 48, color: ClayColors.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'No bookmarks saved yet.',
                style: GoogleFonts.inter(
                  color: ClayColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      itemCount: widget.bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final b = widget.bookmarks[index];
        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFDDD2F5)),
          ),
          child: ListTile(
            leading: const Icon(Icons.bookmark_rounded, color: ClayColors.amber),
            title: Text(
              b.label?.isNotEmpty == true
                  ? b.label!
                  : (b.pageNumber != null ? 'Page ${b.pageNumber}' : 'Bookmark ${index + 1}'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: ClayColors.textDark,
              ),
            ),
            subtitle: b.note != null
                ? Text(
                    b.note!,
                    style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: ClayColors.coral),
              onPressed: () => widget.onDeleteBookmark(b),
            ),
            onTap: () {
              Navigator.of(context).pop();
              widget.onSelectBookmark(b);
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/reader_annotations.dart';
import '../../data/models/reader_document.dart';
import '../../data/models/reader_position.dart';
import '../../data/models/reader_settings.dart';
import '../../domain/enums/reader_file_type.dart';
import '../providers/reader_provider.dart';
import '../providers/reader_settings_provider.dart';
import '../widgets/docx_reader_view.dart';
import '../widgets/epub_reader_view.dart';
import '../widgets/pdf_reader_view.dart';
import '../widgets/reader_annotation_panel.dart';
import '../widgets/reader_bottom_bar.dart';
import '../widgets/reader_error.dart';
import '../widgets/reader_loading.dart';
import '../widgets/reader_settings_panel.dart';
import '../widgets/reader_sidebar.dart';
import '../widgets/reader_toolbar.dart';
import '../../analytics/application/analytics_providers.dart';
import '../../analytics/data/models/activity_session.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String fileId;
  final String bookTitle;
  final String fileFormat;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.fileId,
    this.bookTitle = 'Reader',
    this.fileFormat = 'PDF',
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<PdfReaderViewState> _pdfKey = GlobalKey<PdfReaderViewState>();
  final GlobalKey<EpubReaderViewState> _epubKey = GlobalKey<EpubReaderViewState>();

  ReaderDocumentArgs get _args => ReaderDocumentArgs(
        bookId: widget.bookId,
        fileId: widget.fileId,
        bookTitle: widget.bookTitle,
        fileFormat: widget.fileFormat,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityTrackingServiceProvider).startSession(
            activityType: ActivityType.READING,
            bookId: widget.bookId,
            bookFileId: widget.fileId,
          );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(activityTrackingServiceProvider).closeSession();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(activityTrackingServiceProvider).startSession(
            activityType: ActivityType.READING,
            bookId: widget.bookId,
            bookFileId: widget.fileId,
          );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(activityTrackingServiceProvider).closeSession();
    super.dispose();
  }

  void _onPositionChanged(ReaderPosition position) {
    ref.read(readerCurrentPositionProvider.notifier).state = position;
    ref.read(readerPositionServiceProvider).onPositionChanged(
          bookId: widget.bookId,
          fileId: widget.fileId,
          position: position,
        );
    ref.read(activityTrackingServiceProvider).updateProgress(
          currentLocation: position.locationValue,
          currentPage: position.pageNumber,
        );
  }

  Future<void> _handleToggleBookmark(List<ReaderBookmark> existingBookmarks) async {
    final currentPos = ref.read(readerCurrentPositionProvider);
    final repo = ref.read(readerRepositoryProvider);

    final isAlreadyBookmarked = existingBookmarks.any((b) =>
        b.locationValue == currentPos?.locationValue ||
        (b.pageNumber != null && b.pageNumber == currentPos?.pageNumber));

    if (isAlreadyBookmarked) {
      final existing = existingBookmarks.firstWhere((b) =>
          b.locationValue == currentPos?.locationValue ||
          (b.pageNumber != null && b.pageNumber == currentPos?.pageNumber));
      await repo.deleteBookmark(bookId: widget.bookId, bookmarkId: existing.id);
    } else {
      await repo.createBookmark(
        bookId: widget.bookId,
        bookFileId: widget.fileId,
        locationType: currentPos?.locationType ?? 'PDF_PAGE',
        locationValue: currentPos?.locationValue ?? 'page=1',
        pageNumber: currentPos?.pageNumber,
        label: currentPos?.pageNumber != null ? 'Page ${currentPos!.pageNumber}' : 'Bookmark',
      );
    }
    ref.invalidate(readerBookmarksProvider(widget.bookId));
  }

  void _showHighlightColorPicker(String selectedText, String startLocation, String endLocation, int? pageNumber) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Highlight Selection', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('"$selectedText"', maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ReaderHighlightColor.values.map((c) {
                  return InkWell(
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(readerRepositoryProvider).createHighlight(
                            bookId: widget.bookId,
                            bookFileId: widget.fileId,
                            selectedText: selectedText,
                            locationType: ref.read(readerCurrentPositionProvider)?.locationType ?? 'PDF_PAGE',
                            startLocation: startLocation,
                            endLocation: endLocation,
                            pageNumber: pageNumber,
                            color: c,
                          );
                      ref.invalidate(readerHighlightsProvider(widget.bookId));
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(readerSettingsProvider);
          final notifier = ref.read(readerSettingsProvider.notifier);
          return ReaderSettingsPanel(
            settings: settings,
            onThemeChanged: notifier.updateTheme,
            onFontSizeChanged: notifier.updateFontSize,
            onLineSpacingChanged: notifier.updateLineSpacing,
            onMarginChanged: notifier.updateMargin,
            onPageLayoutChanged: notifier.updatePageLayout,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docAsync = ref.watch(readerDocumentProvider(_args));
    final currentPosition = ref.watch(readerCurrentPositionProvider);
    final settings = ref.watch(readerSettingsProvider);
    final bookmarksAsync = ref.watch(readerBookmarksProvider(widget.bookId));
    final highlightsAsync = ref.watch(readerHighlightsProvider(widget.bookId));
    final notesAsync = ref.watch(readerNotesProvider(widget.bookId));

    final bookmarks = bookmarksAsync.value ?? [];
    final highlights = highlightsAsync.value ?? [];
    final notes = notesAsync.value ?? [];

    final isCurrentBookmarked = bookmarks.any((b) =>
        b.locationValue == currentPosition?.locationValue ||
        (b.pageNumber != null && b.pageNumber == currentPosition?.pageNumber));

    return docAsync.when(
      loading: () => Scaffold(
        body: ReaderLoadingView(title: widget.bookTitle),
      ),
      error: (e, _) => Scaffold(
        body: ReaderErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(readerDocumentProvider(_args)),
        ),
      ),
      data: (doc) {
        final fileType = ReaderFileType.fromFormat(doc.fileFormat);

        return Scaffold(
          key: _scaffoldKey,
          appBar: ReaderToolbar(
            title: doc.bookTitle,
            format: doc.fileFormat,
            isBookmarked: isCurrentBookmarked,
            onBack: () => Navigator.of(context).maybePop(),
            onToggleBookmark: () => _handleToggleBookmark(bookmarks),
            onOpenSettings: _openSettingsPanel,
            onOpenAnnotations: () => _scaffoldKey.currentState?.openEndDrawer(),
            onListenTts: () {
              context.push(
                '/listen/${widget.bookId}/${widget.fileId}?mode=tts&title=${Uri.encodeComponent(doc.bookTitle)}&format=${doc.fileFormat}',
              );
            },
          ),
          drawer: ReaderSidebar(
            bookmarks: bookmarks,
            onSelectBookmark: (b) {
              if (b.pageNumber != null && _pdfKey.currentState != null) {
                _pdfKey.currentState!.goToPage(b.pageNumber!);
              } else if (b.locationType == 'EPUB_CFI' && _epubKey.currentState != null) {
                _epubKey.currentState!.toCfi(b.locationValue);
              }
            },
            onDeleteBookmark: (b) async {
              await ref.read(readerRepositoryProvider).deleteBookmark(
                    bookId: widget.bookId,
                    bookmarkId: b.id,
                  );
              ref.invalidate(readerBookmarksProvider(widget.bookId));
            },
          ),
          endDrawer: ReaderAnnotationPanel(
            highlights: highlights,
            notes: notes,
            onSelectHighlight: (h) {
              if (h.pageNumber != null && _pdfKey.currentState != null) {
                _pdfKey.currentState!.goToPage(h.pageNumber!);
              } else if (h.locationType == 'EPUB_CFI' && _epubKey.currentState != null) {
                _epubKey.currentState!.toCfi(h.startLocation);
              }
            },
            onDeleteHighlight: (h) async {
              await ref.read(readerRepositoryProvider).deleteHighlight(
                    bookId: widget.bookId,
                    highlightId: h.id,
                  );
              ref.invalidate(readerHighlightsProvider(widget.bookId));
            },
            onAddNote: (title, content) async {
              await ref.read(readerRepositoryProvider).createNote(
                    bookId: widget.bookId,
                    title: title,
                    content: content,
                  );
              ref.invalidate(readerNotesProvider(widget.bookId));
            },
            onDeleteNote: (n) async {
              await ref.read(readerRepositoryProvider).deleteNote(
                    bookId: widget.bookId,
                    noteId: n.id,
                  );
              ref.invalidate(readerNotesProvider(widget.bookId));
            },
          ),
          body: _buildReaderBody(fileType, doc, settings),
          bottomNavigationBar: ReaderBottomBar(
            currentPage: currentPosition?.pageNumber,
            totalPages: currentPosition?.totalPages,
            progressPercentage: currentPosition?.progressPercentage ?? 0.0,
            onPrevious: () {
              if (currentPosition?.pageNumber != null && _pdfKey.currentState != null) {
                _pdfKey.currentState!.goToPage(currentPosition!.pageNumber! - 1);
              }
            },
            onNext: () {
              if (currentPosition?.pageNumber != null && _pdfKey.currentState != null) {
                _pdfKey.currentState!.goToPage(currentPosition!.pageNumber! + 1);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildReaderBody(ReaderFileType type, ReaderDocument doc, ReaderSettings settings) {
    switch (type) {
      case ReaderFileType.pdf:
        return PdfReaderView(
          key: _pdfKey,
          fileBytes: doc.fileBytes,
          initialPosition: doc.initialPosition,
          settings: settings,
          onPositionChanged: _onPositionChanged,
          onTextSelected: (text, start, end, page) {
            _showHighlightColorPicker(text, start, end, page);
          },
        );
      case ReaderFileType.epub:
        return EpubReaderView(
          key: _epubKey,
          fileBytes: doc.fileBytes,
          initialPosition: doc.initialPosition,
          settings: settings,
          onPositionChanged: _onPositionChanged,
          onTextSelected: (text, start, end) {
            _showHighlightColorPicker(text, start, end, null);
          },
        );
      case ReaderFileType.docx:
        return DocxReaderView(
          fileBytes: doc.fileBytes,
          initialPosition: doc.initialPosition,
          settings: settings,
          onPositionChanged: _onPositionChanged,
        );
    }
  }
}

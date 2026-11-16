import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../analytics/application/analytics_providers.dart';
import '../../../analytics/data/models/activity_session.dart';
import '../../../annotations/domain/book_annotation.dart';
import '../../../annotations/presentation/screens/book_annotations_panel.dart';
import '../../../annotations/presentation/widgets/add_note_dialog.dart';
import '../../../annotations/presentation/widgets/annotation_context_menu.dart';
import '../../../annotations/providers/annotation_providers.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';
import '../../data/models/reader_annotations.dart';
import '../../data/models/reader_document.dart';
import '../../data/models/reader_position.dart';
import '../../data/models/reader_settings.dart';
import '../../domain/enums/reader_file_type.dart';
import '../providers/reader_provider.dart';
import '../providers/reader_settings_provider.dart';
import '../providers/reading_progress_provider.dart';
import '../widgets/docx_reader_view.dart';
import '../widgets/epub_reader_view.dart';
import '../widgets/pdf_reader_view.dart';
import '../widgets/reader_bottom_bar.dart';
import '../widgets/reader_error.dart';
import '../widgets/reader_loading.dart';
import '../widgets/reader_settings_panel.dart';
import '../widgets/reader_sidebar.dart';
import '../widgets/reader_toolbar.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String fileId;
  final String bookTitle;
  final String fileFormat;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.fileId,
    this.bookTitle = 'Book Reader',
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

  BookAnnotationParams get _annotationParams => BookAnnotationParams(
        bookId: widget.bookId,
        bookFileId: widget.fileId,
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      ref.read(readerPositionServiceProvider).flushPending();
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
    ref.read(readerPositionServiceProvider).flushPending();
    ref.read(activityTrackingServiceProvider).closeSession();
    super.dispose();
  }

  void _onPositionChanged(ReaderPosition position) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    });
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

  void _handleTextSelected({
    required String selectedText,
    required String startLocation,
    required String endLocation,
    int? pageNumber,
    List<NormalizedRect> rectangles = const [],
  }) {
    AnnotationContextMenu.show(
      context,
      selectedText: selectedText,
      pageNumber: pageNumber,
      onHighlight: (colorOption) async {
        final locationData = <String, dynamic>{
          'startLocation': startLocation,
          'endLocation': endLocation,
          if (rectangles.isNotEmpty)
            'rectangles': rectangles.map((r) => r.toJson()).toList(),
        };
        if (startLocation.contains('/6/') || startLocation.contains('epubcfi') || startLocation.contains(':')) {
          locationData['cfi'] = startLocation;
        }

        await ref.read(bookFileAnnotationsProvider(_annotationParams).notifier).addHighlight(
              selectedText: selectedText,
              pageNumber: pageNumber,
              color: colorOption.hex,
              locationData: locationData,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Highlighted in ${colorOption.name}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      onAddNote: () async {
        final note = await AddNoteDialog.show(
          context,
          selectedText: selectedText,
          pageNumber: pageNumber,
        );
        if (note != null && note.trim().isNotEmpty && mounted) {
          final locationData = <String, dynamic>{
            'startLocation': startLocation,
            'endLocation': endLocation,
            if (rectangles.isNotEmpty)
              'rectangles': rectangles.map((r) => r.toJson()).toList(),
          };
          if (startLocation.contains('/6/') || startLocation.contains('epubcfi') || startLocation.contains(':')) {
            locationData['cfi'] = startLocation;
          }

          await ref.read(bookFileAnnotationsProvider(_annotationParams).notifier).addNote(
                noteText: note.trim(),
                selectedText: selectedText,
                pageNumber: pageNumber,
                locationData: locationData,
              );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Note attached to passage'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _handleResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Reading Progress?'),
        content: const Text(
          'This will clear your saved reading position for this book file and return to the beginning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset Progress'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop(); // Close settings panel
      await ref.read(readerRepositoryProvider).resetPosition(
            bookId: widget.bookId,
            fileId: widget.fileId,
          );
      if (_pdfKey.currentState != null) {
        _pdfKey.currentState!.goToPage(1);
      }
      ref.read(readerCurrentPositionProvider.notifier).state = const ReaderPosition(
        locationType: 'PDF_PAGE',
        locationValue: 'page=1',
        pageNumber: 1,
        progressPercentage: 0.0,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reading progress reset to the beginning.')),
        );
      }
    }
  }

  void _openSettingsPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
            onResetProgress: _handleResetProgress,
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
    final annotationsAsync = ref.watch(bookFileAnnotationsProvider(_annotationParams));

    final bookmarks = bookmarksAsync.value ?? [];
    final annotations = annotationsAsync.value ?? [];

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

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            ref.read(readerPositionServiceProvider).flushPending();
            try {
              final progressParams = ReadingProgressParams(
                bookFileId: widget.fileId,
                format: widget.fileFormat,
              );
              ref.read(readingProgressNotifierProvider(progressParams).notifier).saveImmediately();
            } catch (_) {}
          },
          child: Scaffold(
            key: _scaffoldKey,
            appBar: ReaderToolbar(
              title: doc.bookTitle,
              format: doc.fileFormat,
              isBookmarked: isCurrentBookmarked,
              onBack: () async {
                final navigator = Navigator.of(context);
                await ref.read(readerPositionServiceProvider).flushPending();
                try {
                  final progressParams = ReadingProgressParams(
                    bookFileId: widget.fileId,
                    format: widget.fileFormat,
                  );
                  await ref.read(readingProgressNotifierProvider(progressParams).notifier).saveImmediately();
                } catch (_) {}
                if (mounted) {
                  ref.invalidate(booksProvider);
                  navigator.maybePop();
                }
              },
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
            endDrawer: Drawer(
              width: 380,
              child: BookAnnotationsPanel(
                bookId: widget.bookId,
                bookFileId: widget.fileId,
                bookTitle: widget.bookTitle,
                currentPage: currentPosition?.pageNumber,
                onSelectAnnotation: (annotation) {
                  Navigator.of(context).pop();
                  if (annotation.pageNumber != null && _pdfKey.currentState != null) {
                    _pdfKey.currentState!.jumpToAnnotation(annotation);
                  } else if (annotation.epubCfi != null && _epubKey.currentState != null) {
                    _epubKey.currentState!.toCfi(annotation.epubCfi!);
                  }
                },
              ),
            ),
            body: _buildReaderBody(fileType, doc, settings, annotations),
            bottomNavigationBar: ReaderBottomBar(
              currentPage: currentPosition?.pageNumber,
              totalPages: currentPosition?.totalPages,
              progressPercentage: currentPosition?.progressPercentage ?? 0.0,
              onPageSelected: (page) {
                if (fileType == ReaderFileType.pdf && _pdfKey.currentState != null) {
                  _pdfKey.currentState!.goToPage(page);
                }
              },
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
          ),
        );
      },
    );
  }

  Widget _buildReaderBody(
    ReaderFileType type,
    ReaderDocument doc,
    ReaderSettings settings,
    List<BookAnnotation> annotations,
  ) {
    switch (type) {
      case ReaderFileType.pdf:
        return PdfReaderView(
          key: _pdfKey,
          fileBytes: doc.fileBytes,
          initialPosition: doc.initialPosition,
          settings: settings,
          annotations: annotations,
          onPositionChanged: _onPositionChanged,
          onAnnotationTap: (a) {
            _pdfKey.currentState?.jumpToAnnotation(a);
            _scaffoldKey.currentState?.openEndDrawer();
          },
          onTextSelected: (text, start, end, page, rects) {
            _handleTextSelected(
              selectedText: text,
              startLocation: start,
              endLocation: end,
              pageNumber: page,
              rectangles: rects,
            );
          },
        );
      case ReaderFileType.epub:
        return EpubReaderView(
          key: _epubKey,
          fileBytes: doc.fileBytes,
          initialPosition: doc.initialPosition,
          settings: settings,
          annotations: annotations,
          onPositionChanged: _onPositionChanged,
          onAnnotationTap: (a) {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          onTextSelected: (text, start, end) {
            _handleTextSelected(
              selectedText: text,
              startLocation: start,
              endLocation: end,
              pageNumber: null,
            );
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

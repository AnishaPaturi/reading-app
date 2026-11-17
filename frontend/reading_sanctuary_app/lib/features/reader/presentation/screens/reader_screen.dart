import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../analytics/application/analytics_providers.dart';
import '../../../analytics/data/models/activity_session.dart';
import '../../../annotations/domain/book_annotation.dart';
import '../../../annotations/presentation/screens/book_annotations_panel.dart';
import '../../../annotations/presentation/widgets/add_note_dialog.dart';
import '../../../annotations/presentation/widgets/annotation_context_menu.dart';
import '../../../annotations/providers/annotation_providers.dart';
import '../../../home/presentation/providers/home_reading_progress_provider.dart';
import '../../../tracker/application/quotes_highlights_provider.dart';
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

class ReaderTextSelectionState {
  final String selectedText;
  final String startLocation;
  final String endLocation;
  final int? pageNumber;
  final List<NormalizedRect> rectangles;
  final Rect? targetRect;

  const ReaderTextSelectionState({
    required this.selectedText,
    required this.startLocation,
    required this.endLocation,
    this.pageNumber,
    this.rectangles = const [],
    this.targetRect,
  });
}

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
  bool _sessionClosed = false;

  Timer? _bookProgressDebounce;
  double? _pendingBookProgress;
  ReaderTextSelectionState? _activeSelection;

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
      if (!mounted) return;
      ref.read(activityTrackingServiceProvider).startSession(
            activityType: ActivityType.READING,
            bookId: widget.bookId,
            bookFileId: widget.fileId,
          );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _bookProgressDebounce?.cancel();
      _flushBookProgress();
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

  Future<void> _teardownSessionAndSave() async {
    if (_sessionClosed) return;
    _sessionClosed = true;

    _bookProgressDebounce?.cancel();
    await _flushBookProgress();

    await ref.read(readerPositionServiceProvider).flushPending();
    try {
      final progressParams = ReadingProgressParams(
        bookFileId: widget.fileId,
        format: widget.fileFormat,
      );
      await ref.read(readingProgressNotifierProvider(progressParams).notifier).saveImmediately();
    } catch (_) {}
    await ref.read(activityTrackingServiceProvider).closeSession();
  }

  @override
  void dispose() {
    _bookProgressDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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

      if (position.locationType == 'EPUB_CFI') {
        final params = ReadingProgressParams(
          bookFileId: widget.fileId,
          format: 'EPUB',
        );

        ref
            .read(readingProgressNotifierProvider(params).notifier)
            .updateEpubPosition(
              chapterHref: null,
              cfi: position.locationValue,
              progressPercentage: position.progressPercentage,
              pageNumber: position.pageNumber,
              totalPages: position.totalPages,
            );

        _scheduleBookProgressUpdate(
          position.progressPercentage / 100.0,
        );
      } else if (position.locationType == 'PDF_PAGE') {
        final params = ReadingProgressParams(
          bookFileId: widget.fileId,
          format: 'PDF',
        );

        if (position.pageNumber != null && position.totalPages != null) {
          ref
              .read(readingProgressNotifierProvider(params).notifier)
              .updatePdfPage(
                page: position.pageNumber!,
                totalPages: position.totalPages!,
              );
        }

        _scheduleBookProgressUpdate(
          position.progressPercentage / 100.0,
        );
      }
    });
  }

  void _scheduleBookProgressUpdate(double progress) {
    _pendingBookProgress = progress.clamp(0.0, 1.0);

    _bookProgressDebounce?.cancel();

    _bookProgressDebounce = Timer(
      const Duration(seconds: 2),
      _flushBookProgress,
    );
  }

  Future<void> _flushBookProgress() async {
    _bookProgressDebounce?.cancel();

    final progress = _pendingBookProgress;

    if (progress == null || !mounted) return;

    _pendingBookProgress = null;

    try {
      await ref
          .read(booksProvider.notifier)
          .setProgress(widget.bookId, progress);

      ref.invalidate(homeReadingProgressProvider);
    } catch (error, stackTrace) {
      debugPrint('Book progress update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
    Rect? targetRect,
  }) {
    setState(() {
      _activeSelection = ReaderTextSelectionState(
        selectedText: selectedText,
        startLocation: startLocation,
        endLocation: endLocation,
        pageNumber: pageNumber,
        rectangles: rectangles,
        targetRect: targetRect,
      );
    });
  }

  Widget _buildFloatingAnnotationToolbarOverlay() {
    final selection = _activeSelection;
    if (selection == null) return const SizedBox.shrink();

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    const double toolbarWidth = 350.0;
    const double toolbarHeight = 175.0;

    double left;
    double top;

    if (selection.targetRect != null && selection.targetRect != Rect.zero) {
      final target = selection.targetRect!;
      left = (target.center.dx - (toolbarWidth / 2))
          .clamp(16.0, screenSize.width - toolbarWidth - 16.0);

      final spaceAbove = target.top - padding.top;
      if (spaceAbove >= toolbarHeight + 16.0) {
        top = target.top - toolbarHeight - 12.0;
      } else {
        top = target.bottom + 12.0;
        if (top + toolbarHeight > screenSize.height - padding.bottom - 16.0) {
          top = (screenSize.height - toolbarHeight) / 2;
        }
      }
    } else {
      left = (screenSize.width - toolbarWidth) / 2;
      top = padding.top + 70.0;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                _activeSelection = null;
              });
              _epubKey.currentState?.clearSelection();
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: toolbarWidth,
          child: PointerInterceptor(
            child: Material(
              color: Colors.transparent,
              child: AnnotationContextMenu(
                selectedText: selection.selectedText,
                pageNumber: selection.pageNumber,
                onHighlight: (colorOption) async {
                  final startLoc = selection.startLocation;
                  final endLoc = selection.endLocation;
                  final locationData = <String, dynamic>{
                    'startLocation': startLoc,
                    'endLocation': endLoc,
                    if (selection.rectangles.isNotEmpty)
                      'rectangles': selection.rectangles.map((r) => r.toJson()).toList(),
                  };
                  if (startLoc.contains('/6/') || startLoc.contains('epubcfi') || startLoc.contains(':')) {
                    locationData['cfi'] = startLoc;
                  }

                  await ref.read(bookFileAnnotationsProvider(_annotationParams).notifier).addHighlight(
                        selectedText: selection.selectedText,
                        pageNumber: selection.pageNumber,
                        color: colorOption.hex,
                        locationData: locationData,
                      );

                  if (startLoc.isNotEmpty && _epubKey.currentState != null) {
                    await _epubKey.currentState?.addHighlight(
                      cfi: startLoc,
                      color: colorOption.color,
                    );
                  }

                  setState(() {
                    _activeSelection = null;
                  });
                  _epubKey.currentState?.clearSelection();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Highlighted in ${colorOption.name}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onUnderline: (colorOption) async {
                  final startLoc = selection.startLocation;
                  final endLoc = selection.endLocation;
                  final locationData = <String, dynamic>{
                    'startLocation': startLoc,
                    'endLocation': endLoc,
                    'style': 'underline',
                    if (selection.rectangles.isNotEmpty)
                      'rectangles': selection.rectangles.map((r) => r.toJson()).toList(),
                  };
                  if (startLoc.contains('/6/') || startLoc.contains('epubcfi') || startLoc.contains(':')) {
                    locationData['cfi'] = startLoc;
                  }

                  await ref.read(bookFileAnnotationsProvider(_annotationParams).notifier).addHighlight(
                        selectedText: selection.selectedText,
                        pageNumber: selection.pageNumber,
                        color: colorOption.hex,
                        locationData: locationData,
                      );

                  if (startLoc.isNotEmpty && _epubKey.currentState != null) {
                    await _epubKey.currentState?.addUnderline(cfi: startLoc);
                  }

                  setState(() {
                    _activeSelection = null;
                  });
                  _epubKey.currentState?.clearSelection();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Underlined passage'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onAddNote: () async {
                  final selText = selection.selectedText;
                  final pageNum = selection.pageNumber;
                  final startLoc = selection.startLocation;
                  final endLoc = selection.endLocation;
                  final rects = selection.rectangles;

                  setState(() {
                    _activeSelection = null;
                  });

                  final note = await AddNoteDialog.show(
                    context,
                    selectedText: selText,
                    pageNumber: pageNum,
                  );

                  if (note != null && note.trim().isNotEmpty && mounted) {
                    final locationData = <String, dynamic>{
                      'startLocation': startLoc,
                      'endLocation': endLoc,
                      if (rects.isNotEmpty)
                        'rectangles': rects.map((r) => r.toJson()).toList(),
                    };
                    if (startLoc.contains('/6/') || startLoc.contains('epubcfi') || startLoc.contains(':')) {
                      locationData['cfi'] = startLoc;
                    }

                    await ref.read(bookFileAnnotationsProvider(_annotationParams).notifier).addNote(
                          noteText: note.trim(),
                          selectedText: selText,
                          pageNumber: pageNum,
                          locationData: locationData,
                        );

                    _epubKey.currentState?.clearSelection();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Note attached to passage'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    _epubKey.currentState?.clearSelection();
                  }
                },
                onSaveQuote: () async {
                  final selText = selection.selectedText;
                  final pageNum = selection.pageNumber;
                  final startLoc = selection.startLocation;
                  final endLoc = selection.endLocation;
                  final rects = selection.rectangles;

                  final locationData = <String, dynamic>{
                    'startLocation': startLoc,
                    'endLocation': endLoc,
                    if (rects.isNotEmpty)
                      'rectangles': rects.map((r) => r.toJson()).toList(),
                  };
                  if (startLoc.contains('/6/') || startLoc.contains('epubcfi') || startLoc.contains(':')) {
                    locationData['cfi'] = startLoc;
                  }

                  await ref.read(bookFileAnnotationsProvider(_annotationParams).notifier).addQuote(
                        selectedText: selText,
                        pageNumber: pageNum,
                        locationData: locationData,
                      );

                  try {
                    ref.read(quotesHighlightsProvider.notifier).addItem(
                          text: selText,
                          source: widget.bookTitle,
                          chapter: pageNum != null ? 'Page $pageNum' : 'Passage',
                          isQuote: true,
                        );
                  } catch (_) {}

                  setState(() {
                    _activeSelection = null;
                  });
                  _epubKey.currentState?.clearSelection();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved to Quotes'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: selection.selectedText));
                  setState(() {
                    _activeSelection = null;
                  });
                  _epubKey.currentState?.clearSelection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passage copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                onDismiss: () {
                  setState(() {
                    _activeSelection = null;
                  });
                  _epubKey.currentState?.clearSelection();
                },
              ),
            ),
          ),
        ),
      ],
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
    final progressParams = ReadingProgressParams(
      bookFileId: widget.fileId,
      format: widget.fileFormat,
    );
    ref.watch(readingProgressNotifierProvider(progressParams));

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
            _bookProgressDebounce?.cancel();
            if (mounted) {
              _flushBookProgress();
            }
            if (!_sessionClosed) {
              _sessionClosed = true;
              ref.read(readerPositionServiceProvider).flushPending();
              ref.read(activityTrackingServiceProvider).closeSession();
              try {
                final progressParams = ReadingProgressParams(
                  bookFileId: widget.fileId,
                  format: widget.fileFormat,
                );
                ref.read(readingProgressNotifierProvider(progressParams).notifier).saveImmediately();
              } catch (_) {}
            }
            ref.invalidate(booksProvider);
            ref.invalidate(homeReadingProgressProvider);
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: ClayColors.background,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: PointerInterceptor(
                child: ReaderToolbar(
                  title: doc.bookTitle,
                  format: doc.fileFormat,
                  isBookmarked: isCurrentBookmarked,
                  onBack: () async {
                    final navigator = Navigator.of(context);
                    await _teardownSessionAndSave();
                    if (mounted) {
                      ref.invalidate(booksProvider);
                      ref.invalidate(homeReadingProgressProvider);
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
              ),
            ),
            drawer: ReaderSidebar(
              bookmarks: bookmarks,
              onSelectBookmark: (b) {
                if (b.pageNumber != null && _pdfKey.currentState != null) {
                  _pdfKey.currentState!.goToPage(b.pageNumber!);
                } else if ((b.locationType == 'EPUB_CFI' ||
                        b.locationValue.contains('epubcfi') ||
                        b.locationValue.contains('/6/')) &&
                    _epubKey.currentState != null) {
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
                onSelectBookmark: (b) {
                  Navigator.of(context).pop();
                  if (b.pageNumber != null && _pdfKey.currentState != null) {
                    _pdfKey.currentState!.goToPage(b.pageNumber!);
                  } else if ((b.locationType == 'EPUB_CFI' ||
                          b.locationValue.contains('epubcfi') ||
                          b.locationValue.contains('/6/')) &&
                      _epubKey.currentState != null) {
                    _epubKey.currentState!.toCfi(b.locationValue);
                  }
                },
              ),
            ),
            body: Stack(
              children: [
                _buildReaderBody(fileType, doc, settings, annotations),
                if (_activeSelection != null)
                  _buildFloatingAnnotationToolbarOverlay(),
              ],
            ),
            bottomNavigationBar: PointerInterceptor(
              child: ReaderBottomBar(
                currentPage: fileType == ReaderFileType.epub
                    ? null
                    : currentPosition?.pageNumber,
                totalPages: fileType == ReaderFileType.epub
                    ? null
                    : currentPosition?.totalPages,
                progressPercentage: currentPosition?.progressPercentage ?? 0.0,
                onSeek: fileType == ReaderFileType.epub
                    ? (percentage) {
                        _epubKey.currentState?.toProgressPercentage(percentage);
                      }
                    : null,
                onPageSelected: (page) {
                  if (fileType == ReaderFileType.pdf && _pdfKey.currentState != null) {
                    _pdfKey.currentState!.goToPage(page);
                  }
                },
                onPrevious: () {
                  if (fileType == ReaderFileType.epub) {
                    _epubKey.currentState?.prev();
                  } else if (fileType == ReaderFileType.pdf) {
                    final page = currentPosition?.pageNumber;
                    if (page != null) {
                      _pdfKey.currentState?.goToPage(page - 1);
                    }
                  }
                },
                onNext: () {
                  if (fileType == ReaderFileType.epub) {
                    _epubKey.currentState?.next();
                  } else if (fileType == ReaderFileType.pdf) {
                    final page = currentPosition?.pageNumber;
                    if (page != null) {
                      _pdfKey.currentState?.goToPage(page + 1);
                    }
                  }
                },
              ),
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
          onTextSelected: (text, start, end, page, rects, [targetRect]) {
            _handleTextSelected(
              selectedText: text,
              startLocation: start,
              endLocation: end,
              pageNumber: page,
              rectangles: rects,
              targetRect: targetRect,
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
          onAnnotationTap: (annotation) {
            _scaffoldKey.currentState?.openEndDrawer();
          },
          onTextSelected: (text, start, end, [targetRect]) {
            _handleTextSelected(
              selectedText: text,
              startLocation: start,
              endLocation: end,
              pageNumber: null,
              rectangles: const [],
              targetRect: targetRect,
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

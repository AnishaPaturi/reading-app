import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
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

  String? _webSelectedText;
  String? _webSelectedCfi;
  final TextEditingController _webNoteController = TextEditingController();

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
    _webNoteController.dispose();
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

        if (startLocation.isNotEmpty && _epubKey.currentState != null) {
          await _epubKey.currentState?.addHighlight(
            cfi: startLocation,
            color: colorOption.color,
          );
        }

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
      onSaveQuote: () async {
        final locationData = <String, dynamic>{
          'startLocation': startLocation,
          'endLocation': endLocation,
          if (rectangles.isNotEmpty)
            'rectangles': rectangles.map((r) => r.toJson()).toList(),
        };
        if (startLocation.contains('/6/') || startLocation.contains('epubcfi') || startLocation.contains(':')) {
          locationData['cfi'] = startLocation;
        }

        await ref.read(bookFileAnnotationsProvider(_annotationParams).notifier).addQuote(
              selectedText: selectedText,
              pageNumber: pageNumber,
              locationData: locationData,
            );
        try {
          ref.read(quotesHighlightsProvider.notifier).addItem(
                text: selectedText,
                source: widget.bookTitle,
                chapter: pageNumber != null ? 'Page $pageNumber' : 'Passage',
                isQuote: true,
              );
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved to Quotes'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    ).whenComplete(() {
      if (mounted) {
        _epubKey.currentState?.clearSelection();
      }
    });
  }

  Widget _buildWebEpubAnnotationToolbar() {
    if (_webSelectedText == null || _webSelectedCfi == null) {
      return const SizedBox.shrink();
    }

    final selectedText = _webSelectedText!;
    final cfi = _webSelectedCfi!;

    return PointerInterceptor(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFF30251F),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFF8B7355),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '“$selectedText”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF5E6C8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _epubAnnotationButton(
                  'Gold',
                  const Color(0xFFE5C07B),
                  selectedText,
                  cfi,
                ),
                _epubAnnotationButton(
                  'Rose',
                  const Color(0xFFE8A0A0),
                  selectedText,
                  cfi,
                ),
                _epubAnnotationButton(
                  'Sage',
                  const Color(0xFFA3B18A),
                  selectedText,
                  cfi,
                ),
                TextButton.icon(
                  onPressed: () async {
                    await _epubKey.currentState?.addUnderline(
                      cfi: cfi,
                    );

                    if (mounted) {
                      setState(() {
                        _webSelectedText = null;
                        _webSelectedCfi = null;
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.format_underlined,
                    color: Color(0xFFF5E6C8),
                  ),
                  label: const Text(
                    'Underline',
                    style: TextStyle(color: Color(0xFFF5E6C8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _webNoteController,
                    style: const TextStyle(
                      color: Color(0xFFF5E6C8),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Write a note about this passage...',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Save note',
                  onPressed: () async {
                    final note = _webNoteController.text.trim();

                    if (note.isEmpty) return;

                    final locationData = <String, dynamic>{
                      'cfi': cfi,
                      'startLocation': cfi,
                      'endLocation': cfi,
                    };

                    await ref
                        .read(
                          bookFileAnnotationsProvider(
                            _annotationParams,
                          ).notifier,
                        )
                        .addNote(
                          selectedText: selectedText,
                          noteText: note,
                          locationData: locationData,
                        );

                    _webNoteController.clear();

                    await _epubKey.currentState?.clearSelection();

                    if (mounted) {
                      setState(() {
                        _webSelectedText = null;
                        _webSelectedCfi = null;
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.save,
                    color: Color(0xFFE5C07B),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: () async {
                    await _epubKey.currentState?.clearSelection();

                    if (mounted) {
                      setState(() {
                        _webSelectedText = null;
                        _webSelectedCfi = null;
                      });
                    }
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFF5E6C8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _epubAnnotationButton(
    String label,
    Color color,
    String selectedText,
    String cfi,
  ) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
      ),
      onPressed: () async {
        final hex = '#${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}'.toUpperCase();

        await ref
            .read(
              bookFileAnnotationsProvider(
                _annotationParams,
              ).notifier,
            )
            .addHighlight(
              selectedText: selectedText,
              color: hex,
              locationData: {
                'cfi': cfi,
                'startLocation': cfi,
                'endLocation': cfi,
              },
            );

        await _epubKey.currentState?.addHighlight(
          cfi: cfi,
          color: color,
        );

        await _epubKey.currentState?.clearSelection();

        if (mounted) {
          setState(() {
            _webSelectedText = null;
            _webSelectedCfi = null;
          });
        }
      },
      child: Text(label),
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
              ),
            ),
            body: _buildReaderBody(fileType, doc, settings, annotations),
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
                  if (fileType == ReaderFileType.pdf) {
                    final page = currentPosition?.pageNumber;
                    if (page != null) {
                      _pdfKey.currentState?.goToPage(page - 1);
                    }
                  } else if (fileType == ReaderFileType.epub) {
                    _epubKey.currentState?.prev();
                  }
                },
                onNext: () {
                  if (fileType == ReaderFileType.pdf) {
                    final page = currentPosition?.pageNumber;
                    if (page != null) {
                      _pdfKey.currentState?.goToPage(page + 1);
                    }
                  } else if (fileType == ReaderFileType.epub) {
                    _epubKey.currentState?.next();
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
        return Column(
          children: [
            _buildWebEpubAnnotationToolbar(),
            Expanded(
              child: EpubReaderView(
                key: _epubKey,
                fileBytes: doc.fileBytes,
                initialPosition: doc.initialPosition,
                settings: settings,
                annotations: annotations,
                onPositionChanged: _onPositionChanged,
                onAnnotationTap: (annotation) {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
                onTextSelected: (text, start, end) {
                  if (kIsWeb) {
                    setState(() {
                      _webSelectedText = text;
                      _webSelectedCfi = start;
                    });
                  } else {
                    _handleTextSelected(
                      selectedText: text,
                      startLocation: start,
                      endLocation: end,
                      pageNumber: null,
                    );
                  }
                },
              ),
            ),
          ],
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

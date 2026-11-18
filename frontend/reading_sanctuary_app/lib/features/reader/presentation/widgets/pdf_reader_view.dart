import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../annotations/domain/annotation_type.dart';
import '../../../annotations/domain/book_annotation.dart';
import '../../data/models/reader_chapter.dart';
import '../../data/models/reader_position.dart';
import '../../data/models/reader_settings.dart';

class PdfReaderView extends StatefulWidget {
  final Uint8List fileBytes;
  final ReaderPosition? initialPosition;
  final ReaderSettings settings;
  final List<BookAnnotation> annotations;
  final void Function(ReaderPosition position) onPositionChanged;
  final ValueChanged<List<ReaderChapter>>? onChaptersLoaded;
  final void Function(
    String text,
    String startLocation,
    String endLocation,
    int pageNumber,
    List<NormalizedRect> rectangles, [
    Rect? targetRect,
  ])? onTextSelected;
  final ValueChanged<BookAnnotation>? onAnnotationTap;

  const PdfReaderView({
    super.key,
    required this.fileBytes,
    this.initialPosition,
    required this.settings,
    this.annotations = const [],
    required this.onPositionChanged,
    this.onChaptersLoaded,
    this.onTextSelected,
    this.onAnnotationTap,
  });

  @override
  State<PdfReaderView> createState() => PdfReaderViewState();
}

class PdfReaderViewState extends State<PdfReaderView> {
  late final PdfViewerController _controller;
  late final PdfTextSearcher _textSearcher;
  int _pageNumber = 1;
  int _pageCount = 1;
  String? _emphasizedAnnotationId;
  final Map<String, List<NormalizedRect>> _resolvedAnnotationRects = {};

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _textSearcher = PdfTextSearcher(_controller);
    _pageNumber = widget.initialPosition?.pageNumber ?? 1;
  }

  @override
  void dispose() {
    _textSearcher.dispose();
    super.dispose();
  }

  PdfTextSearcher get textSearcher => _textSearcher;

  void startSearch(String query) {
    if (query.trim().isEmpty) {
      _textSearcher.resetTextSearch();
    } else {
      _textSearcher.startTextSearch(query.trim());
    }
  }

  void nextSearchMatch() => _textSearcher.goToNextMatch();

  void prevSearchMatch() => _textSearcher.goToPrevMatch();

  void clearSearch() => _textSearcher.resetTextSearch();

  @override
  void didUpdateWidget(covariant PdfReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.annotations != oldWidget.annotations) {
      _resolveMissingAnnotationGeometries();
    }
  }

  void goToPage(int page) {
    final safeTotal = _pageCount > 0 ? _pageCount : page;
    final safePage = page.clamp(1, safeTotal);
    _pageNumber = safePage;

    if (_controller.isReady) {
      _controller.goToPage(pageNumber: safePage);
    }
  }

  void jumpToAnnotation(BookAnnotation annotation) {
    if (annotation.pageNumber != null) {
      final targetPage = annotation.pageNumber!;
      goToPage(targetPage);

      setState(() {
        _emphasizedAnnotationId = annotation.id;
      });

      // Scroll into view if coordinates exist or are resolved
      final rects = annotation.normalizedRects.isNotEmpty
          ? annotation.normalizedRects
          : (_resolvedAnnotationRects[annotation.id] ?? const []);

      if (rects.isNotEmpty && _controller.isReady && targetPage <= _controller.pages.length) {
        final pdfPage = _controller.pages[targetPage - 1];
        try {
          final first = rects.first;
          final totalRectInPage = Rect.fromLTRB(
            first.left * pdfPage.width,
            first.top * pdfPage.height,
            (first.left + first.width) * pdfPage.width,
            (first.top + first.height) * pdfPage.height,
          );

          final pdfRect = totalRectInPage.toPdfRect(page: pdfPage);
          final docRect = _controller.calcRectForRectInsidePage(
            pageNumber: targetPage,
            rect: pdfRect,
          );
          _controller.ensureVisible(docRect, margin: 40.0);
        } catch (_) {}
      }

      // Emphasis stays for 2.5 seconds then gently clears
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _emphasizedAnnotationId == annotation.id) {
          setState(() {
            _emphasizedAnnotationId = null;
          });
        }
      });
    }
  }

  void _handlePageChanged(int? page) {
    if (page == null) return;
    setState(() {
      _pageNumber = page;
    });
    final progress = _pageCount > 0 ? ((page / _pageCount) * 100).clamp(0.0, 100.0) : 0.0;
    widget.onPositionChanged(
      ReaderPosition(
        locationType: 'PDF_PAGE',
        locationValue: 'page=$page',
        pageNumber: page,
        totalPages: _pageCount,
        progressPercentage: progress,
      ),
    );
    _resolveMissingAnnotationGeometries();
  }

  void _resolveMissingAnnotationGeometries() {
    if (!_controller.isReady || widget.annotations.isEmpty) return;

    for (final a in widget.annotations) {
      if ((a.type == AnnotationType.highlight || a.type == AnnotationType.quote) &&
          a.normalizedRects.isEmpty &&
          a.pageNumber != null &&
          a.selectedText != null &&
          a.selectedText!.trim().isNotEmpty &&
          !_resolvedAnnotationRects.containsKey(a.id)) {
        _resolveAnnotationGeometry(a);
      }
    }
  }

  Future<void> _resolveAnnotationGeometry(BookAnnotation a) async {
    if (!_controller.isReady || a.pageNumber == null) return;
    final pageNum = a.pageNumber!;
    if (pageNum < 1 || pageNum > _controller.pages.length) return;
    final pdfPage = _controller.pages[pageNum - 1];

    try {
      final structured = await pdfPage.loadStructuredText();
      final cleanFull = structured.fullText.replaceAll('\r\n', '\n');
      final query = a.selectedText!.trim();
      if (query.isEmpty) return;

      final idx = cleanFull.toLowerCase().indexOf(query.toLowerCase());
      if (idx != -1) {
        final range = structured.getRangeFromAB(idx, idx + query.length - 1);
        final rects = <NormalizedRect>[];
        for (final r in range.enumerateFragmentBoundingRects()) {
          final rectInPage = r.bounds.toRect(page: pdfPage);
          rects.add(
            NormalizedRect(
              left: (rectInPage.left / pdfPage.width).clamp(0.0, 1.0),
              top: (rectInPage.top / pdfPage.height).clamp(0.0, 1.0),
              width: (rectInPage.width / pdfPage.width).clamp(0.0, 1.0),
              height: (rectInPage.height / pdfPage.height).clamp(0.0, 1.0),
            ),
          );
        }
        if (rects.isNotEmpty && mounted) {
          setState(() {
            _resolvedAnnotationRects[a.id] = rects;
          });
        }
      }
    } catch (e) {
      debugPrint('Error resolving annotation geometry for ${a.id}: $e');
    }
  }

  Future<List<NormalizedRect>> _extractRectangles({
    required String text,
    required int pageNum,
    required List<PdfPageTextRange> ranges,
    PdfTextSelectionAnchor? a,
    PdfTextSelectionAnchor? b,
  }) async {
    final rectangles = <NormalizedRect>[];
    if (!_controller.isReady || pageNum < 1 || pageNum > _controller.pages.length) {
      return rectangles;
    }
    final pdfPage = _controller.pages[pageNum - 1];

    // Method 1: Extract directly from ranges (most accurate)
    if (ranges.isNotEmpty) {
      try {
        for (final range in ranges) {
          for (final r in range.enumerateFragmentBoundingRects()) {
            final rectInPage = r.bounds.toRect(page: pdfPage);
            rectangles.add(
              NormalizedRect(
                left: (rectInPage.left / pdfPage.width).clamp(0.0, 1.0),
                top: (rectInPage.top / pdfPage.height).clamp(0.0, 1.0),
                width: (rectInPage.width / pdfPage.width).clamp(0.0, 1.0),
                height: (rectInPage.height / pdfPage.height).clamp(0.0, 1.0),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error extracting bounds from ranges: $e');
      }
    }

    // Method 2: Extract from anchors
    if (rectangles.isEmpty && a != null && b != null) {
      try {
        final range = a.page.getRangeFromAB(a.index, b.index);
        for (final r in range.enumerateFragmentBoundingRects()) {
          final rectInPage = r.bounds.toRect(page: pdfPage);
          rectangles.add(
            NormalizedRect(
              left: (rectInPage.left / pdfPage.width).clamp(0.0, 1.0),
              top: (rectInPage.top / pdfPage.height).clamp(0.0, 1.0),
              width: (rectInPage.width / pdfPage.width).clamp(0.0, 1.0),
              height: (rectInPage.height / pdfPage.height).clamp(0.0, 1.0),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error extracting bounds from anchors: $e');
      }
    }

    // Method 3: Fallback by searching page structured text
    if (rectangles.isEmpty) {
      try {
        final structured = await pdfPage.loadStructuredText();
        final cleanFull = structured.fullText.replaceAll('\r\n', '\n');
        final query = text.trim();
        final idx = cleanFull.toLowerCase().indexOf(query.toLowerCase());
        if (idx != -1) {
          final range = structured.getRangeFromAB(idx, idx + query.length - 1);
          for (final r in range.enumerateFragmentBoundingRects()) {
            final rectInPage = r.bounds.toRect(page: pdfPage);
            rectangles.add(
              NormalizedRect(
                left: (rectInPage.left / pdfPage.width).clamp(0.0, 1.0),
                top: (rectInPage.top / pdfPage.height).clamp(0.0, 1.0),
                width: (rectInPage.width / pdfPage.width).clamp(0.0, 1.0),
                height: (rectInPage.height / pdfPage.height).clamp(0.0, 1.0),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error extracting bounds from structured text: $e');
      }
    }

    return rectangles;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ClayColors.background,
      child: PdfViewer.data(
        widget.fileBytes,
        sourceName: 'Reading Sanctuary Document',
        controller: _controller,
        initialPageNumber: widget.initialPosition?.pageNumber ?? 1,
        params: PdfViewerParams(
          layoutPages: widget.settings.pageLayout == Axis.horizontal
              ? (pages, params) {
                  final height = pages.fold(0.0, (prev, page) => math.max(prev, page.height)) + params.margin * 2;
                  final pageLayouts = <Rect>[];
                  double x = params.margin;
                  for (final page in pages) {
                    pageLayouts.add(
                      Rect.fromLTWH(
                        x,
                        (height - page.height) / 2,
                        page.width,
                        page.height,
                      ),
                    );
                    x += page.width + params.margin;
                  }
                  return PdfPageLayout(pageLayouts: pageLayouts, documentSize: Size(x, height));
                }
              : null,
          onPageChanged: _handlePageChanged,
          pagePaintCallbacks: [
            (canvas, pageRect, page) {
              _textSearcher.paintMatches(canvas, pageRect, page);
              final pageHighlights = widget.annotations.where(
                (a) => a.pageNumber == page.pageNumber &&
                    (a.type == AnnotationType.highlight || a.type == AnnotationType.quote),
              );
              for (final highlight in pageHighlights) {
                final isEmphasized = _emphasizedAnnotationId == highlight.id;
                final isQuote = highlight.type == AnnotationType.quote;
                final baseColor = highlight.displayColor;
                final paint = Paint()
                  ..color = isEmphasized
                      ? (isQuote ? ClayColors.softLilac.withValues(alpha: 0.85) : baseColor.withValues(alpha: 0.70))
                      : (isQuote ? ClayColors.softLilac.withValues(alpha: 0.45) : baseColor.withValues(alpha: 0.40))
                  ..style = PaintingStyle.fill;

                final borderPaint = isEmphasized
                    ? (Paint()
                        ..color = isQuote ? ClayColors.primaryPurple : ClayColors.deepPurple
                        ..strokeWidth = 2.0
                        ..style = PaintingStyle.stroke)
                    : (isQuote
                        ? (Paint()
                            ..color = ClayColors.primaryPurple.withValues(alpha: 0.6)
                            ..strokeWidth = 1.0
                            ..style = PaintingStyle.stroke)
                        : null);

                final rects = highlight.normalizedRects.isNotEmpty
                    ? highlight.normalizedRects
                    : (_resolvedAnnotationRects[highlight.id] ?? const []);

                for (final r in rects) {
                  final absRect = r.toAbsoluteRect(pageRect);
                  final rrect = RRect.fromRectAndRadius(absRect, const Radius.circular(3));
                  canvas.drawRRect(rrect, paint);
                  if (borderPaint != null) {
                    canvas.drawRRect(rrect, borderPaint);
                  }
                }
              }
            },
          ],
          pageOverlaysBuilder: (context, pageRect, page) {
            final notes = widget.annotations.where(
              (a) => a.pageNumber == page.pageNumber && a.type == AnnotationType.note,
            ).toList();
            if (notes.isEmpty) return const [];

            return [
              Positioned(
                right: 12,
                top: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (notes.isNotEmpty && widget.onAnnotationTap != null) {
                        widget.onAnnotationTap!(notes.first);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ClayColors.deepPurple.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sticky_note_2_rounded, size: 14, color: Colors.white),
                          if (notes.length > 1) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${notes.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          customizeContextMenuItems: (params, items) {
            if (params.contextMenuFor == PdfViewerPart.selectedText) {
              items.insert(
                0,
                ContextMenuButtonItem(
                  label: 'Annotate',
                  onPressed: () async {
                    final text = await params.textSelectionDelegate.getSelectedText();
                    final ranges = await params.textSelectionDelegate.getSelectedTextRanges();
                    params.dismissContextMenu();
                    if (text.trim().isNotEmpty && widget.onTextSelected != null) {
                      final pageNum = ranges.isNotEmpty
                          ? ranges.first.pageNumber
                          : (params.a?.page.pageNumber ?? _pageNumber);

                      final rectangles = await _extractRectangles(
                        text: text.trim(),
                        pageNum: pageNum,
                        ranges: ranges,
                        a: params.a,
                        b: params.b,
                      );

                      Rect? targetRect;
                      if (rectangles.isNotEmpty && _controller.isReady && pageNum <= _controller.pages.length) {
                        try {
                          final pdfPage = _controller.pages[pageNum - 1];
                          final first = rectangles.first;
                          final totalRectInPage = Rect.fromLTRB(
                            first.left * pdfPage.width,
                            first.top * pdfPage.height,
                            (first.left + first.width) * pdfPage.width,
                            (first.top + first.height) * pdfPage.height,
                          );
                          final pdfRect = totalRectInPage.toPdfRect(page: pdfPage);
                          targetRect = _controller.calcRectForRectInsidePage(
                            pageNumber: pageNum,
                            rect: pdfRect,
                          );
                        } catch (_) {}
                      }

                      widget.onTextSelected!(
                        text.trim(),
                        'page=$pageNum',
                        'page=$pageNum',
                        pageNum,
                        rectangles,
                        targetRect,
                      );
                    }
                  },
                ),
              );
            }
          },
          onViewerReady: (document, controller) async {
            setState(() {
              _pageCount = document.pages.length;
            });
            if (_pageNumber > 1 && _pageNumber <= _pageCount) {
              controller.goToPage(pageNumber: _pageNumber);
            }
            _handlePageChanged(_pageNumber);
            _resolveMissingAnnotationGeometries();

            if (widget.onChaptersLoaded != null) {
              try {
                final outlineNodes = await document.loadOutline();
                if (outlineNodes.isNotEmpty && mounted) {
                  ReaderChapter convertNode(PdfOutlineNode node) {
                    return ReaderChapter(
                      title: node.title.trim().isNotEmpty ? node.title.trim() : 'Section',
                      pageNumber: node.dest?.pageNumber,
                      subchapters: node.children.map(convertNode).toList(),
                    );
                  }

                  widget.onChaptersLoaded!(outlineNodes.map(convertNode).toList());
                }
              } catch (e) {
                debugPrint('Failed to load PDF outline: $e');
              }
            }
          },
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../annotations/domain/annotation_type.dart';
import '../../../annotations/domain/book_annotation.dart';
import '../../data/models/reader_position.dart';
import '../../data/models/reader_settings.dart';

class PdfReaderView extends StatefulWidget {
  final Uint8List fileBytes;
  final ReaderPosition? initialPosition;
  final ReaderSettings settings;
  final List<BookAnnotation> annotations;
  final void Function(ReaderPosition position) onPositionChanged;
  final void Function(String text, String startLocation, String endLocation, int pageNumber)? onTextSelected;
  final ValueChanged<BookAnnotation>? onAnnotationTap;

  const PdfReaderView({
    super.key,
    required this.fileBytes,
    this.initialPosition,
    required this.settings,
    this.annotations = const [],
    required this.onPositionChanged,
    this.onTextSelected,
    this.onAnnotationTap,
  });

  @override
  State<PdfReaderView> createState() => PdfReaderViewState();
}

class PdfReaderViewState extends State<PdfReaderView> {
  late final PdfViewerController _controller;
  int _pageNumber = 1;
  int _pageCount = 1;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _pageNumber = widget.initialPosition?.pageNumber ?? 1;
  }

  void goToPage(int page) {
    final safeTotal = _pageCount > 0 ? _pageCount : page;
    final safePage = page.clamp(1, safeTotal);
    _pageNumber = safePage;

    if (_controller.isReady) {
      _controller.goToPage(pageNumber: safePage);
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.settings.themeMode.backgroundColor,
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
              final pageHighlights = widget.annotations.where(
                (a) => a.pageNumber == page.pageNumber && a.type == AnnotationType.highlight,
              );
              for (final highlight in pageHighlights) {
                final paint = Paint()
                  ..color = highlight.displayColor.withValues(alpha: 0.38)
                  ..style = PaintingStyle.fill;

                final rects = highlight.normalizedRects;
                if (rects.isNotEmpty) {
                  for (final r in rects) {
                    canvas.drawRect(r.toAbsoluteRect(pageRect), paint);
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
                        color: const Color(0xFF533E85).withValues(alpha: 0.88),
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
                    params.dismissContextMenu();
                    if (text != null && text.trim().isNotEmpty && widget.onTextSelected != null) {
                      final pageNum = params.a?.page.pageNumber ?? _pageNumber;
                      widget.onTextSelected!(
                        text.trim(),
                        'page=$pageNum',
                        'page=$pageNum',
                        pageNum,
                      );
                    }
                  },
                ),
              );
            }
          },
          onViewerReady: (document, controller) {
            setState(() {
              _pageCount = document.pages.length;
            });
            if (_pageNumber > 1 && _pageNumber <= _pageCount) {
              controller.goToPage(pageNumber: _pageNumber);
            }
            _handlePageChanged(_pageNumber);
          },
        ),
      ),
    );
  }
}

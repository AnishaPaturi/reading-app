import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../data/models/reader_position.dart';
import '../../data/models/reader_settings.dart';

class PdfReaderView extends StatefulWidget {
  final Uint8List fileBytes;
  final ReaderPosition? initialPosition;
  final ReaderSettings settings;
  final void Function(ReaderPosition position) onPositionChanged;
  final void Function(String text, String startLocation, String endLocation, int pageNumber)? onTextSelected;

  const PdfReaderView({
    super.key,
    required this.fileBytes,
    this.initialPosition,
    required this.settings,
    required this.onPositionChanged,
    this.onTextSelected,
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
    if (page >= 1 && page <= _pageCount) {
      _controller.goToPage(pageNumber: page);
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
          layoutPages: (pages, params) {
            return widget.settings.pageLayout == Axis.horizontal
                ? defaultHorizontalPageLayout(pages, params)
                : defaultVerticalPageLayout(pages, params);
          },
          onPageChanged: _handlePageChanged,
          onViewerReady: (document, controller) {
            setState(() {
              _pageCount = document.pages.length;
            });
            _handlePageChanged(_pageNumber);
          },
        ),
      ),
    );
  }
}

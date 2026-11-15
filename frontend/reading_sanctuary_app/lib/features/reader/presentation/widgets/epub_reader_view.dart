import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import '../../../annotations/domain/annotation_type.dart';
import '../../../annotations/domain/book_annotation.dart';
import '../../data/models/reader_position.dart';
import '../../data/models/reader_settings.dart';

class EpubReaderView extends StatefulWidget {
  final Uint8List fileBytes;
  final ReaderPosition? initialPosition;
  final ReaderSettings settings;
  final List<BookAnnotation> annotations;
  final void Function(ReaderPosition position) onPositionChanged;
  final void Function(String text, String startLocation, String endLocation)? onTextSelected;
  final ValueChanged<BookAnnotation>? onAnnotationTap;

  const EpubReaderView({
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
  State<EpubReaderView> createState() => EpubReaderViewState();
}

class EpubReaderViewState extends State<EpubReaderView> {
  late final EpubController _controller;
  bool _isEpubLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = EpubController();
  }

  @override
  void didUpdateWidget(covariant EpubReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isEpubLoaded && widget.annotations != oldWidget.annotations) {
      _applyHighlights();
    }
  }

  void _applyHighlights() {
    for (final a in widget.annotations) {
      final cfi = a.epubCfi;
      if (a.type == AnnotationType.highlight && cfi != null && cfi.isNotEmpty) {
        try {
          _controller.addHighlight(
            cfi: cfi,
            color: a.displayColor,
            opacity: 0.38,
          );
        } catch (_) {}
      }
    }
  }

  void toCfi(String cfi) {
    _controller.display(cfi: cfi);
  }

  EpubTheme _getTheme() {
    switch (widget.settings.themeMode) {
      case ReaderThemeMode.dark:
        return EpubTheme.dark();
      case ReaderThemeMode.sepia:
        return EpubTheme.custom(
          backgroundDecoration: BoxDecoration(color: widget.settings.themeMode.backgroundColor),
          foregroundColor: widget.settings.themeMode.textColor,
        );
      case ReaderThemeMode.light:
        return EpubTheme.light();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.settings.themeMode.backgroundColor,
      child: EpubViewer(
        epubController: _controller,
        epubSource: EpubSource.fromData(widget.fileBytes),
        initialCfi: widget.initialPosition?.locationType == 'EPUB_CFI'
            ? widget.initialPosition?.locationValue
            : null,
        displaySettings: EpubDisplaySettings(
          fontSize: widget.settings.fontSize.round(),
          flow: widget.settings.pageLayout == Axis.horizontal
              ? EpubFlow.paginated
              : EpubFlow.scrolled,
          theme: _getTheme(),
        ),
        onEpubLoaded: () {
          _isEpubLoaded = true;
          _applyHighlights();
        },
        onAnnotationClicked: (cfi, rect) {
          if (widget.onAnnotationTap != null) {
            final match = widget.annotations.firstWhere(
              (a) => a.epubCfi == cfi,
              orElse: () => BookAnnotation(
                id: '',
                bookId: '',
                bookFileId: '',
                type: AnnotationType.highlight,
                locationData: {'cfi': cfi},
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            if (match.id.isNotEmpty) {
              widget.onAnnotationTap!(match);
            }
          }
        },
        onRelocated: (location) {
          final progress = (location.progress * 100).clamp(0.0, 100.0);
          widget.onPositionChanged(
            ReaderPosition(
              locationType: 'EPUB_CFI',
              locationValue: location.startCfi,
              pageNumber: location.chapterPage,
              totalPages: location.chapterTotalPages,
              progressPercentage: progress,
            ),
          );
        },
        onTextSelected: (selection) {
          if (widget.onTextSelected != null && selection.selectedText.trim().isNotEmpty) {
            widget.onTextSelected!(
              selection.selectedText,
              selection.selectionCfi,
              selection.selectionCfi,
            );
          }
        },
      ),
    );
  }
}

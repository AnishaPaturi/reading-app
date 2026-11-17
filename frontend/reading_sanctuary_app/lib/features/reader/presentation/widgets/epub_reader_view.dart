import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../annotations/domain/annotation_type.dart';
import '../../../annotations/domain/book_annotation.dart';
import '../../data/models/reader_position.dart';
import '../../data/models/reader_settings.dart';

class EpubReaderView extends StatefulWidget {
  final Uint8List fileBytes;
  final ReaderPosition? initialPosition;
  final ReaderSettings settings;
  final List<BookAnnotation> annotations;

  final ValueChanged<ReaderPosition> onPositionChanged;

  final void Function(
    String text,
    String startLocation,
    String endLocation, [
    Rect? targetRect,
  ])? onTextSelected;

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
  EpubReaderViewState createState() => EpubReaderViewState();
}

class EpubReaderViewState extends State<EpubReaderView> {
  late final EpubController _controller;

  bool _isEpubLoaded = false;
  bool _locationsReady = false;
  bool _isDisposed = false;

  double _lastProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = EpubController();

    _lastProgress =
        widget.initialPosition?.progressPercentage ?? 0.0;
  }

  bool get isLoaded => _isEpubLoaded;

  bool get locationsReady => _locationsReady;

  // ---------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------

  Future<void> next() async {
    if (!_isEpubLoaded || _isDisposed) return;

    try {
      _controller.next();
    } catch (error, stackTrace) {
      debugPrint('EPUB next navigation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> prev() async {
    if (!_isEpubLoaded || _isDisposed) return;

    try {
      _controller.prev();
    } catch (error, stackTrace) {
      debugPrint('EPUB previous navigation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> toProgressPercentage(double percentage) async {
    if (!_isEpubLoaded || _isDisposed) {
      debugPrint('EPUB seek ignored: reader not loaded.');
      return;
    }

    if (!_locationsReady) {
      debugPrint(
        'EPUB seek ignored: location generation is not complete.',
      );
      return;
    }

    final safePercentage =
        percentage.clamp(0.0, 100.0) / 100.0;

    debugPrint(
      'EPUB seek requested: ${(safePercentage * 100).toStringAsFixed(1)}%',
    );

    try {
      _controller.toProgressPercentage(safePercentage);
    } catch (error, stackTrace) {
      debugPrint('EPUB seek failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> toCfi(String cfi) async {
    if (!_isEpubLoaded || _isDisposed || cfi.isEmpty) return;

    try {
      _controller.display(cfi: cfi);
    } catch (error, stackTrace) {
      debugPrint('EPUB CFI navigation failed: $error');
    }
  }

  // ---------------------------------------------------------
  // SELECTION
  // ---------------------------------------------------------

  Future<void> clearSelection() async {
    if (!_isEpubLoaded || _isDisposed) return;

    try {
      _controller.clearSelection();
    } catch (error) {
      debugPrint('EPUB selection clearing failed: $error');
    }
  }

  // ---------------------------------------------------------
  // ANNOTATIONS
  // ---------------------------------------------------------

  Future<void> addHighlight({
    required String cfi,
    required Color color,
  }) async {
    if (!_isEpubLoaded || _isDisposed || cfi.isEmpty) return;

    try {
      _controller.addHighlight(
        cfi: cfi,
        color: color,
        opacity: 0.40,
      );

      await clearSelection();
    } catch (error, stackTrace) {
      debugPrint('EPUB highlight failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> addUnderline({
    required String cfi,
  }) async {
    if (!_isEpubLoaded || _isDisposed || cfi.isEmpty) return;

    try {
      _controller.addUnderline(cfi: cfi);
      await clearSelection();
    } catch (error) {
      debugPrint('EPUB underline failed: $error');
    }
  }

  Future<void> removeHighlight({
    required String cfi,
  }) async {
    if (!_isEpubLoaded || _isDisposed || cfi.isEmpty) return;

    try {
      _controller.removeHighlight(cfi: cfi);
    } catch (error) {
      debugPrint('EPUB highlight removal failed: $error');
    }
  }

  // ---------------------------------------------------------
  // PROGRESS
  // ---------------------------------------------------------

  void _emitPosition(EpubLocation location) {
    if (_isDisposed) return;

    if (_locationsReady) {
      _lastProgress =
          (location.progress * 100).clamp(0.0, 100.0);
    }

    widget.onPositionChanged(
      ReaderPosition(
        locationType: 'EPUB_CFI',
        locationValue: location.startCfi,
        pageNumber: location.chapterPage,
        totalPages: location.chapterTotalPages,
        progressPercentage: _lastProgress,
      ),
    );
  }

  Future<void> _onLocationsLoaded() async {
    if (_isDisposed) return;

    _locationsReady = true;

    debugPrint('EPUB locations generated successfully.');

    try {
      final location =
          await _controller.getCurrentLocation();

      if (!_isDisposed) {
        _emitPosition(location);
      }
    } catch (error) {
      debugPrint('Could not retrieve initial EPUB location: $error');
    }
  }

  // ---------------------------------------------------------
  // RESTORE HIGHLIGHTS
  // ---------------------------------------------------------

  Future<void> _applyHighlights() async {
    if (!_isEpubLoaded || _isDisposed) return;

    for (final annotation in widget.annotations) {
      if (_isDisposed) return;

      final cfi = annotation.epubCfi;

      if (cfi == null || cfi.isEmpty) continue;

      try {
        if (annotation.type == AnnotationType.highlight ||
            annotation.type == AnnotationType.quote) {
          _controller.addHighlight(
            cfi: cfi,
            color: annotation.type == AnnotationType.quote
                ? ClayColors.softLilac
                : annotation.displayColor,
            opacity: annotation.type == AnnotationType.quote
                ? 0.45
                : 0.38,
          );
        }
      } catch (error) {
        debugPrint(
          'Could not restore annotation ${annotation.id}: $error',
        );
      }
    }
  }

  // ---------------------------------------------------------
  // THEME & STYLES (Overflow & Selection Fixes)
  // ---------------------------------------------------------

  EpubTheme _getTheme() {
    final customCss = <String, dynamic>{
      'html': {
        'max-width': '100% !important',
        'overflow-x': 'hidden !important',
        'box-sizing': 'border-box !important',
        'user-select': 'text !important',
        '-webkit-user-select': 'text !important',
      },
      'body': {
        'max-width': '100% !important',
        'overflow-x': 'hidden !important',
        'box-sizing': 'border-box !important',
        'user-select': 'text !important',
        '-webkit-user-select': 'text !important',
        'line-height': '${widget.settings.lineSpacing} !important',
        'padding': '0 ${widget.settings.margin.horizontalPadding}px !important',
      },
      'body *': {
        'user-select': 'text !important',
        '-webkit-user-select': 'text !important',
      },
      'p': {
        'line-height': '${widget.settings.lineSpacing} !important',
      },
      'img, svg, video, table': {
        'max-width': '100% !important',
        'height': 'auto !important',
      },
    };

    return EpubTheme.custom(
      backgroundDecoration: const BoxDecoration(color: ClayColors.background),
      foregroundColor: ClayColors.textDark,
      customCss: customCss,
    );
  }

  // ---------------------------------------------------------
  // WIDGET LIFECYCLE
  // ---------------------------------------------------------

  @override
  void didUpdateWidget(covariant EpubReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isEpubLoaded &&
        widget.annotations != oldWidget.annotations) {
      _applyHighlights();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final flow = widget.settings.pageLayout == Axis.horizontal
        ? EpubFlow.paginated
        : EpubFlow.scrolled;

    return Container(
      color: ClayColors.background,
      child: EpubViewer(
        epubController: _controller,

        epubSource: EpubSource.fromData(widget.fileBytes),

        initialCfi:
            widget.initialPosition?.locationType == 'EPUB_CFI'
                ? widget.initialPosition?.locationValue
                : null,

        displaySettings: EpubDisplaySettings(
          fontSize: widget.settings.fontSize.round(),
          flow: flow,

          // Snap must not disable vertical scrolling.
          snap: flow == EpubFlow.paginated,

          theme: _getTheme(),
        ),

        // ---------------------------------------------------
        // LOADING
        // ---------------------------------------------------

        onEpubLoaded: () async {
          if (_isDisposed) return;

          _isEpubLoaded = true;

          debugPrint('EPUB successfully loaded.');

          await _applyHighlights();
        },

        onLoadError: (error) {
          debugPrint('EPUB loading error: ${error.message}');
        },

        onLocationLoaded: _onLocationsLoaded,

        // ---------------------------------------------------
        // PAGE NAVIGATION / PROGRESS
        // ---------------------------------------------------

        onRelocated: (location) {
          _emitPosition(location);
        },

        // ---------------------------------------------------
        // TEXT SELECTION
        // ---------------------------------------------------

        suppressNativeContextMenu: true,

        onTextSelected: (selection) {
          final selectedText = selection.selectedText.trim();
          final cfiRange = selection.selectionCfi;

          if (selectedText.isEmpty || cfiRange.isEmpty) {
            return;
          }

          debugPrint('EPUB selection detected.');
          debugPrint('Selected text: $selectedText');
          debugPrint('Selection CFI: $cfiRange');

          widget.onTextSelected?.call(
            selectedText,
            cfiRange,
            cfiRange,
            null,
          );
        },

        // ---------------------------------------------------
        // SELECTION LIFECYCLE
        // ---------------------------------------------------

        onSelectionChanging: () {
          debugPrint('EPUB selection is changing.');
        },

        onDeselection: () {
          debugPrint('EPUB text selection cleared.');
        },

        // Clear selection when navigating to another page.
        clearSelectionOnPageChange: true,

        // ---------------------------------------------------
        // ANNOTATION CLICK
        // ---------------------------------------------------

        onAnnotationClicked: (cfi, rect) {
          final match = widget.annotations.where(
            (annotation) => annotation.epubCfi == cfi,
          );

          if (match.isNotEmpty) {
            widget.onAnnotationTap?.call(match.first);
          }
        },
      ),
    );
  }
}

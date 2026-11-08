import 'dart:typed_data';
import 'package:docx_viewer/docx_viewer.dart';
import 'package:flutter/material.dart';
import '../../data/models/reader_position.dart';
import '../../data/models/reader_settings.dart';

class DocxReaderView extends StatefulWidget {
  final Uint8List fileBytes;
  final ReaderPosition? initialPosition;
  final ReaderSettings settings;
  final void Function(ReaderPosition position) onPositionChanged;

  const DocxReaderView({
    super.key,
    required this.fileBytes,
    this.initialPosition,
    required this.settings,
    required this.onPositionChanged,
  });

  @override
  State<DocxReaderView> createState() => _DocxReaderViewState();
}

class _DocxReaderViewState extends State<DocxReaderView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialPosition?.locationType == 'DOCX_ANCHOR' &&
          _scrollController.hasClients) {
        final val = widget.initialPosition?.locationValue ?? '';
        final offsetMatch = RegExp(r'offset=(\d+)').firstMatch(val);
        if (offsetMatch != null) {
          final offset = double.tryParse(offsetMatch.group(1) ?? '0') ?? 0.0;
          if (offset > 0 && offset <= _scrollController.position.maxScrollExtent) {
            _scrollController.jumpTo(offset);
          }
        }
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final progress = max > 0 ? ((current / max) * 100).clamp(0.0, 100.0) : 0.0;

    widget.onPositionChanged(
      ReaderPosition(
        locationType: 'DOCX_ANCHOR',
        locationValue: 'offset=${current.round()}',
        progressPercentage: progress,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.settings.themeMode.backgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: widget.settings.margin.horizontalPadding,
        vertical: 24,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: DefaultTextStyle(
          style: TextStyle(
            color: widget.settings.themeMode.textColor,
            fontSize: widget.settings.fontSize,
            height: widget.settings.lineSpacing,
          ),
          child: DocxView(
            bytes: widget.fileBytes,
            fontSize: widget.settings.fontSize.round(),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ReaderBookmark {
  final String id;
  final String bookId;
  final String bookFileId;
  final String? label;
  final String? note;
  final String locationType;
  final String locationValue;
  final int? pageNumber;
  final DateTime createdAt;

  const ReaderBookmark({
    required this.id,
    required this.bookId,
    required this.bookFileId,
    this.label,
    this.note,
    required this.locationType,
    required this.locationValue,
    this.pageNumber,
    required this.createdAt,
  });

  factory ReaderBookmark.fromJson(Map<String, dynamic> json) {
    return ReaderBookmark(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookFileId: json['bookFileId'] as String,
      label: json['label'] as String?,
      note: json['note'] as String?,
      locationType: json['locationType'] as String,
      locationValue: json['locationValue'] as String,
      pageNumber: json['pageNumber'] as int?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

enum ReaderHighlightColor {
  yellow(Color(0xFFFFF176)),
  green(Color(0xFFAED581)),
  blue(Color(0xFF81D4FA)),
  pink(Color(0xFFF48FB1)),
  purple(Color(0xFFCE93D8)),
  orange(Color(0xFFFFB74D));

  final Color color;
  const ReaderHighlightColor(this.color);

  static ReaderHighlightColor fromString(String name) {
    switch (name.toUpperCase()) {
      case 'GREEN':
        return ReaderHighlightColor.green;
      case 'BLUE':
        return ReaderHighlightColor.blue;
      case 'PINK':
        return ReaderHighlightColor.pink;
      case 'PURPLE':
        return ReaderHighlightColor.purple;
      case 'ORANGE':
        return ReaderHighlightColor.orange;
      case 'YELLOW':
      default:
        return ReaderHighlightColor.yellow;
    }
  }

  String get nameUpper => name.toUpperCase();
}

class ReaderHighlight {
  final String id;
  final String bookId;
  final String bookFileId;
  final String selectedText;
  final String locationType;
  final String startLocation;
  final String endLocation;
  final int? pageNumber;
  final ReaderHighlightColor color;
  final String? annotationNote;
  final DateTime createdAt;

  const ReaderHighlight({
    required this.id,
    required this.bookId,
    required this.bookFileId,
    required this.selectedText,
    required this.locationType,
    required this.startLocation,
    required this.endLocation,
    this.pageNumber,
    required this.color,
    this.annotationNote,
    required this.createdAt,
  });

  factory ReaderHighlight.fromJson(Map<String, dynamic> json) {
    return ReaderHighlight(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      bookFileId: json['bookFileId'] as String,
      selectedText: json['selectedText'] as String,
      locationType: json['locationType'] as String,
      startLocation: json['startLocation'] as String,
      endLocation: json['endLocation'] as String,
      pageNumber: json['pageNumber'] as int?,
      color: ReaderHighlightColor.fromString(json['color'] as String? ?? 'YELLOW'),
      annotationNote: json['annotationNote'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ReaderBookNote {
  final String id;
  final String bookId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReaderBookNote({
    required this.id,
    required this.bookId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReaderBookNote.fromJson(Map<String, dynamic> json) {
    return ReaderBookNote(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

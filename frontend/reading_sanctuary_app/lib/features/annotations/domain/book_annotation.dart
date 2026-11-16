import 'dart:convert';
import 'package:flutter/material.dart';
import 'annotation_type.dart';

/// Normalized rectangle (0.0 to 1.0 relative to page dimensions).
class NormalizedRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const NormalizedRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
      };

  factory NormalizedRect.fromJson(Map<String, dynamic> json) {
    double parse(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '0') ?? 0.0;
    }

    return NormalizedRect(
      left: parse(json['left']),
      top: parse(json['top']),
      width: parse(json['width']),
      height: parse(json['height']),
    );
  }

  Rect toAbsoluteRect(Rect pageRect) {
    return Rect.fromLTWH(
      pageRect.left + left * pageRect.width,
      pageRect.top + top * pageRect.height,
      width * pageRect.width,
      height * pageRect.height,
    );
  }
}

class BookAnnotation {
  final String id;
  final String bookId;
  final String bookFileId;

  final AnnotationType type;
  final String? selectedText;
  final String? noteText;
  final String? color; // Hex string e.g. "#F5E7A8"

  final int? pageNumber;
  final Map<String, dynamic> locationData;

  final DateTime createdAt;
  final DateTime updatedAt;

  final bool isPendingSync;
  final bool isDeletedLocally;

  const BookAnnotation({
    required this.id,
    required this.bookId,
    required this.bookFileId,
    required this.type,
    this.selectedText,
    this.noteText,
    this.color,
    this.pageNumber,
    this.locationData = const {},
    required this.createdAt,
    required this.updatedAt,
    this.isPendingSync = false,
    this.isDeletedLocally = false,
  });

  /// Extract rectangles from locationData if available
  List<NormalizedRect> get normalizedRects {
    final raw = locationData['rectangles'];
    if (raw is List) {
      final list = <NormalizedRect>[];
      for (final item in raw) {
        if (item is Map) {
          list.add(NormalizedRect.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return list;
    }
    return const [];
  }

  /// Extract CFI string from locationData if available
  String? get epubCfi {
    return locationData['cfi']?.toString();
  }

  Color get displayColor {
    if (color == null || color!.isEmpty) {
      return const Color(0xFFF5E7A8); // default warm yellow
    }
    try {
      var hex = color!.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFFF5E7A8);
    }
  }

  BookAnnotation copyWith({
    String? id,
    String? bookId,
    String? bookFileId,
    AnnotationType? type,
    String? selectedText,
    String? noteText,
    String? color,
    int? pageNumber,
    Map<String, dynamic>? locationData,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPendingSync,
    bool? isDeletedLocally,
  }) {
    return BookAnnotation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookFileId: bookFileId ?? this.bookFileId,
      type: type ?? this.type,
      selectedText: selectedText ?? this.selectedText,
      noteText: noteText ?? this.noteText,
      color: color ?? this.color,
      pageNumber: pageNumber ?? this.pageNumber,
      locationData: locationData ?? this.locationData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      isDeletedLocally: isDeletedLocally ?? this.isDeletedLocally,
    );
  }

  factory BookAnnotation.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parseLocation(dynamic loc) {
      if (loc == null) return {};
      if (loc is Map<String, dynamic>) return loc;
      if (loc is Map) return Map<String, dynamic>.from(loc);
      if (loc is String) {
        try {
          final decoded = jsonDecode(loc);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return {};
    }

    DateTime parseDate(dynamic d) {
      if (d is String) {
        final parsed = DateTime.tryParse(d);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return BookAnnotation(
      id: json['id']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      bookFileId: json['bookFileId']?.toString() ?? '',
      type: AnnotationTypeX.fromString(json['type']?.toString()),
      selectedText: json['selectedText']?.toString(),
      noteText: json['noteText']?.toString(),
      color: json['color']?.toString(),
      pageNumber: json['pageNumber'] is int
          ? json['pageNumber'] as int
          : int.tryParse(json['pageNumber']?.toString() ?? ''),
      locationData: parseLocation(json['locationData']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      isPendingSync: json['isPendingSync'] == true,
      isDeletedLocally: json['isDeletedLocally'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookFileId': bookFileId,
      'type': type.nameUpper,
      'selectedText': selectedText,
      'noteText': noteText,
      'color': color,
      'pageNumber': pageNumber,
      'locationData': jsonEncode(locationData),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPendingSync': isPendingSync,
      'isDeletedLocally': isDeletedLocally,
    };
  }
}

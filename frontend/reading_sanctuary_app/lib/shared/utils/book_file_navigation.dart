import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/book.dart';

/// Opens the exact attached file matching the requested format.
/// Never substitutes book.id for file.id.
Future<T?> openBookInFormat<T>(
  BuildContext context,
  Book book, {
  required BookFileFormat format,
}) {
  BookFile? targetFile;

  for (final file in book.files) {
    if (file.format == format) {
      targetFile = file;
      break;
    }
  }

  if (targetFile == null || targetFile.id.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No ${format.label} file is attached to "${book.title}".',
        ),
      ),
    );
    return Future.value(null);
  }

  final isAudio = format.isAudio;

  final path = isAudio
      ? '/listen/${book.id}/${targetFile.id}'
      : '/reader/${book.id}/${targetFile.id}';

  final queryParameters = <String, String>{
    'title': book.title,
    'format': format.label,
    if (isAudio) 'author': book.author,
  };

  final uri = Uri(
    path: path,
    queryParameters: queryParameters,
  );

  return context.push<T>(uri.toString());
}

/// Opens a document, preferring PDF and then EPUB.
Future<T?> openBookDocument<T>(BuildContext context, Book book) {
  if (book.files.isEmpty) {
    _showMissingFileMessage(context, book);
    return Future.value(null);
  }

  final pdf = book.files.where(
    (file) => file.format == BookFileFormat.pdf,
  );

  if (pdf.isNotEmpty) {
    return openBookInFormat<T>(
      context,
      book,
      format: BookFileFormat.pdf,
    );
  }

  final epub = book.files.where(
    (file) => file.format == BookFileFormat.epub,
  );

  if (epub.isNotEmpty) {
    return openBookInFormat<T>(
      context,
      book,
      format: BookFileFormat.epub,
    );
  }

  _showMissingFileMessage(context, book);
  return Future.value(null);
}

/// Opens an audiobook, preferring MP3, then M4B, then M4A.
Future<T?> openBookAudio<T>(BuildContext context, Book book) {
  const audioFormats = [
    BookFileFormat.mp3,
    BookFileFormat.m4b,
    BookFileFormat.m4a,
  ];

  for (final format in audioFormats) {
    if (book.files.any((file) => file.format == format)) {
      return openBookInFormat<T>(
        context,
        book,
        format: format,
      );
    }
  }

  _showMissingFileMessage(context, book);
  return Future.value(null);
}

void _showMissingFileMessage(
  BuildContext context,
  Book book,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'No readable file is attached to "${book.title}". '
        'Please upload the file again.',
      ),
    ),
  );
}

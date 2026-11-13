import 'package:flutter/material.dart';

enum BookshelfLayoutStyle {
  shelf('shelf', 'Classic Shelf', 'Traditional bookshelf with standing books', Icons.shelves),
  gallery('gallery', 'Cover Gallery', 'Front-facing covers in a clean grid', Icons.grid_view_rounded),
  compact('compact', 'Compact List', 'Detailed list with reading status & progress', Icons.view_headline_rounded);

  final String key;
  final String label;
  final String description;
  final IconData icon;

  const BookshelfLayoutStyle(this.key, this.label, this.description, this.icon);

  static BookshelfLayoutStyle fromKey(String? key) {
    if (key == null) return BookshelfLayoutStyle.shelf;
    for (final style in BookshelfLayoutStyle.values) {
      if (style.key.toLowerCase() == key.toLowerCase()) return style;
    }
    return BookshelfLayoutStyle.shelf;
  }
}

enum BookshelfBackgroundStyle {
  solid('solid', 'Solid Tint', Icons.square_rounded),
  gradient('gradient', 'Soft Gradient', Icons.gradient_rounded),
  wood('wood', 'Warm Woodwork', Icons.forest_rounded),
  parchment('parchment', 'Aged Parchment', Icons.auto_stories_rounded);

  final String key;
  final String label;
  final IconData icon;

  const BookshelfBackgroundStyle(this.key, this.label, this.icon);

  static BookshelfBackgroundStyle fromKey(String? key) {
    if (key == null) return BookshelfBackgroundStyle.solid;
    for (final style in BookshelfBackgroundStyle.values) {
      if (style.key.toLowerCase() == key.toLowerCase()) return style;
    }
    return BookshelfBackgroundStyle.solid;
  }
}

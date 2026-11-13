import 'package:flutter/material.dart';

class BookshelfModel {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String themeColor;
  final String accentColor;
  final String icon;
  final String backgroundStyle;
  final String layoutStyle;
  final bool isFavorite;
  final int sortOrder;
  final int bookCount;
  final List<String> bookIds;
  final DateTime? createdAt;

  const BookshelfModel({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.themeColor = '#2C221E',
    this.accentColor = '#D4AF37',
    this.icon = 'shelves',
    this.backgroundStyle = 'solid',
    this.layoutStyle = 'shelf',
    this.isFavorite = false,
    this.sortOrder = 0,
    this.bookCount = 0,
    this.bookIds = const [],
    this.createdAt,
  });

  BookshelfModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? themeColor,
    String? accentColor,
    String? icon,
    String? backgroundStyle,
    String? layoutStyle,
    bool? isFavorite,
    int? sortOrder,
    int? bookCount,
    List<String>? bookIds,
    DateTime? createdAt,
  }) {
    return BookshelfModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      themeColor: themeColor ?? this.themeColor,
      accentColor: accentColor ?? this.accentColor,
      icon: icon ?? this.icon,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
      bookCount: bookCount ?? this.bookCount,
      bookIds: bookIds ?? this.bookIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory BookshelfModel.fromJson(Map<String, dynamic> json) {
    return BookshelfModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Shelf',
      description: json['description']?.toString(),
      color: json['color']?.toString(),
      themeColor: json['themeColor']?.toString() ?? json['color']?.toString() ?? '#2C221E',
      accentColor: json['accentColor']?.toString() ?? '#D4AF37',
      icon: json['icon']?.toString() ?? 'shelves',
      backgroundStyle: json['backgroundStyle']?.toString() ?? 'solid',
      layoutStyle: json['layoutStyle']?.toString() ?? 'shelf',
      isFavorite: json['isFavorite'] == true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      bookCount: (json['bookCount'] as num?)?.toInt() ?? ((json['bookIds'] as List?)?.length ?? 0),
      bookIds: (json['bookIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (color != null) 'color': color,
        'themeColor': themeColor,
        'accentColor': accentColor,
        'icon': icon,
        'backgroundStyle': backgroundStyle,
        'layoutStyle': layoutStyle,
        'isFavorite': isFavorite,
        'sortOrder': sortOrder,
        'bookCount': bookCount,
        'bookIds': bookIds,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  IconData resolveIcon() {
    switch (icon.toLowerCase()) {
      case 'shelves':
        return Icons.shelves;
      case 'auto_stories':
      case 'book':
        return Icons.auto_stories_rounded;
      case 'favorite':
      case 'heart':
        return Icons.favorite_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'bookmark':
        return Icons.bookmark_rounded;
      case 'fire':
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'trophy':
      case 'crown':
        return Icons.emoji_events_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'magic':
      case 'wand':
        return Icons.auto_awesome_rounded;
      case 'coffee':
        return Icons.coffee_rounded;
      case 'feather':
      case 'quill':
        return Icons.draw_rounded;
      case 'moon':
        return Icons.nightlight_round;
      case 'cottage':
        return Icons.cottage_rounded;
      default:
        return Icons.shelves;
    }
  }
}

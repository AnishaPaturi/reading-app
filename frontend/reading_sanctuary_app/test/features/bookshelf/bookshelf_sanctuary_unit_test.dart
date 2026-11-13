import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/bookshelf/data/models/bookshelf_model.dart';
import 'package:reading_sanctuary_app/features/bookshelf/utils/bookshelf_layouts.dart';
import 'package:reading_sanctuary_app/features/bookshelf/utils/bookshelf_themes.dart';

void main() {
  group('BookshelfModel Unit Tests', () {
    test('fromJson parses full JSON correctly', () {
      final json = {
        'id': 'shelf-123',
        'name': 'Gothic Romance Sanctuary',
        'description': 'Dark castles and immortal love',
        'color': '#1C1520',
        'themeColor': '#1C1520',
        'accentColor': '#8E2845',
        'icon': 'favorite',
        'backgroundStyle': 'gradient',
        'layoutStyle': 'gallery',
        'isFavorite': true,
        'sortOrder': 3,
        'bookCount': 5,
        'bookIds': ['b1', 'b2', 'b3', 'b4', 'b5'],
        'createdAt': '2026-11-13T10:00:00.000Z',
      };

      final model = BookshelfModel.fromJson(json);

      expect(model.id, 'shelf-123');
      expect(model.name, 'Gothic Romance Sanctuary');
      expect(model.description, 'Dark castles and immortal love');
      expect(model.themeColor, '#1C1520');
      expect(model.accentColor, '#8E2845');
      expect(model.icon, 'favorite');
      expect(model.backgroundStyle, 'gradient');
      expect(model.layoutStyle, 'gallery');
      expect(model.isFavorite, isTrue);
      expect(model.sortOrder, 3);
      expect(model.bookCount, 5);
      expect(model.bookIds, ['b1', 'b2', 'b3', 'b4', 'b5']);
      expect(model.createdAt, isNotNull);
    });

    test('fromJson provides safe defaults for null/missing fields', () {
      final json = {
        'id': 'shelf-defaults',
        'name': 'Minimal Shelf',
      };

      final model = BookshelfModel.fromJson(json);

      expect(model.id, 'shelf-defaults');
      expect(model.name, 'Minimal Shelf');
      expect(model.description, isNull);
      expect(model.themeColor, '#2C221E');
      expect(model.accentColor, '#D4AF37');
      expect(model.icon, 'shelves');
      expect(model.backgroundStyle, 'solid');
      expect(model.layoutStyle, 'shelf');
      expect(model.isFavorite, isFalse);
      expect(model.sortOrder, 0);
      expect(model.bookCount, 0);
      expect(model.bookIds, isEmpty);
    });

    test('toJson serializes model correctly', () {
      const model = BookshelfModel(
        id: 'shelf-456',
        name: 'Fantasy Realms',
        description: 'Dragons & Magic',
        themeColor: '#1A2A20',
        accentColor: '#4CAF50',
        icon: 'magic',
        backgroundStyle: 'wood',
        layoutStyle: 'compact',
        isFavorite: true,
        sortOrder: 1,
        bookCount: 2,
        bookIds: ['f1', 'f2'],
      );

      final json = model.toJson();

      expect(json['id'], 'shelf-456');
      expect(json['name'], 'Fantasy Realms');
      expect(json['themeColor'], '#1A2A20');
      expect(json['accentColor'], '#4CAF50');
      expect(json['icon'], 'magic');
      expect(json['backgroundStyle'], 'wood');
      expect(json['layoutStyle'], 'compact');
      expect(json['isFavorite'], isTrue);
      expect(json['sortOrder'], 1);
      expect(json['bookCount'], 2);
      expect(json['bookIds'], ['f1', 'f2']);
    });

    test('copyWith modifies designated fields while keeping others intact', () {
      const original = BookshelfModel(
        id: 'shelf-orig',
        name: 'Original Name',
        themeColor: '#000000',
        accentColor: '#FFFFFF',
      );

      final modified = original.copyWith(
        name: 'Updated Name',
        accentColor: '#D4AF37',
        bookCount: 10,
      );

      expect(modified.id, 'shelf-orig');
      expect(modified.name, 'Updated Name');
      expect(modified.themeColor, '#000000');
      expect(modified.accentColor, '#D4AF37');
      expect(modified.bookCount, 10);
    });

    test('resolveIcon correctly maps icon names to IconData', () {
      expect(const BookshelfModel(id: '1', name: 'A', icon: 'favorite').resolveIcon(), Icons.favorite_rounded);
      expect(const BookshelfModel(id: '2', name: 'B', icon: 'star').resolveIcon(), Icons.star_rounded);
      expect(const BookshelfModel(id: '3', name: 'C', icon: 'book').resolveIcon(), Icons.auto_stories_rounded);
      expect(const BookshelfModel(id: '4', name: 'D', icon: 'fire').resolveIcon(), Icons.local_fire_department_rounded);
      expect(const BookshelfModel(id: '5', name: 'E', icon: 'magic').resolveIcon(), Icons.auto_awesome_rounded);
      expect(const BookshelfModel(id: '6', name: 'F', icon: 'unknown_icon').resolveIcon(), Icons.shelves);
    });
  });

  group('BookshelfThemes Unit Tests', () {
    test('parseHex handles 6-digit hex and with/without leading hash', () {
      final c1 = BookshelfThemes.parseHex('#D4AF37');
      expect(c1.r, closeTo(0xD4 / 255.0, 0.01));
      expect(c1.g, closeTo(0xAF / 255.0, 0.01));
      expect(c1.b, closeTo(0x37 / 255.0, 0.01));

      final c2 = BookshelfThemes.parseHex('2C221E');
      expect(c2.r, closeTo(0x2C / 255.0, 0.01));
      expect(c2.g, closeTo(0x22 / 255.0, 0.01));
      expect(c2.b, closeTo(0x1E / 255.0, 0.01));
    });

    test('parseHex returns fallback on invalid format', () {
      const fallback = Color(0xFF123456);
      expect(BookshelfThemes.parseHex('invalid', fallback: fallback), fallback);
      expect(BookshelfThemes.parseHex('', fallback: fallback), fallback);
      expect(BookshelfThemes.parseHex(null, fallback: fallback), fallback);
    });

    test('toHex formats color to uppercase hex string', () {
      const color = Color(0xFFD4AF37);
      expect(BookshelfThemes.toHex(color), '#D4AF37');
    });

    test('findById retrieves known themes and falls back to darkAcademia', () {
      final darkAcademia = BookshelfThemes.findById('dark_academia');
      expect(darkAcademia.name, 'Dark Academia');

      final warmParchment = BookshelfThemes.findById('warm_parchment');
      expect(warmParchment.name, 'Warm Parchment');

      final fallback = BookshelfThemes.findById('non_existent');
      expect(fallback.id, 'dark_academia');
    });

    test('all 6 aesthetic themes exist', () {
      expect(BookshelfThemes.all.length, 6);
      final ids = BookshelfThemes.all.map((t) => t.id).toList();
      expect(ids, containsAll([
        'dark_academia',
        'warm_parchment',
        'enchanted_forest',
        'gothic_romance',
        'midnight_stars',
        'blush_rose',
      ]));
    });
  });

  group('BookshelfLayoutStyle & BookshelfBackgroundStyle Unit Tests', () {
    test('BookshelfLayoutStyle.fromKey resolves valid and default keys', () {
      expect(BookshelfLayoutStyle.fromKey('shelf'), BookshelfLayoutStyle.shelf);
      expect(BookshelfLayoutStyle.fromKey('gallery'), BookshelfLayoutStyle.gallery);
      expect(BookshelfLayoutStyle.fromKey('compact'), BookshelfLayoutStyle.compact);
      expect(BookshelfLayoutStyle.fromKey('UNKNOWN'), BookshelfLayoutStyle.shelf);
      expect(BookshelfLayoutStyle.fromKey(null), BookshelfLayoutStyle.shelf);
    });

    test('BookshelfBackgroundStyle.fromKey resolves valid and default keys', () {
      expect(BookshelfBackgroundStyle.fromKey('solid'), BookshelfBackgroundStyle.solid);
      expect(BookshelfBackgroundStyle.fromKey('gradient'), BookshelfBackgroundStyle.gradient);
      expect(BookshelfBackgroundStyle.fromKey('wood'), BookshelfBackgroundStyle.wood);
      expect(BookshelfBackgroundStyle.fromKey('parchment'), BookshelfBackgroundStyle.parchment);
      expect(BookshelfBackgroundStyle.fromKey('UNKNOWN'), BookshelfBackgroundStyle.solid);
      expect(BookshelfBackgroundStyle.fromKey(null), BookshelfBackgroundStyle.solid);
    });
  });
}

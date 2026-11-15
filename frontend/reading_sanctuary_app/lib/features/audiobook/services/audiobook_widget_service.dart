import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class AudiobookWidgetService {
  static const String appGroupId = 'group.com.readingsanctuary.audiobooks';
  static const String androidWidgetProvider = 'AudiobookNowPlayingWidgetProvider';

  static Future<void> initialize() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidget init notice: $e');
    }
  }

  static Future<void> updateNowPlaying({
    required String title,
    required String author,
    String? coverPath,
    required bool isPlaying,
    required int positionMs,
    required int durationMs,
    required String audiobookId,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await HomeWidget.saveWidgetData<String>('now_playing_title', title);
      await HomeWidget.saveWidgetData<String>('now_playing_author', author);
      await HomeWidget.saveWidgetData<String>('now_playing_cover', coverPath ?? '');
      await HomeWidget.saveWidgetData<bool>('is_playing', isPlaying);
      await HomeWidget.saveWidgetData<int>('position_ms', positionMs);
      await HomeWidget.saveWidgetData<int>('duration_ms', durationMs);
      await HomeWidget.saveWidgetData<String>('audiobook_id', audiobookId);

      await HomeWidget.updateWidget(
        androidName: androidWidgetProvider,
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  static Future<void> updateShelfWidget({
    required List<Map<String, String>> recentBooks,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      for (var i = 0; i < recentBooks.length && i < 3; i++) {
        final b = recentBooks[i];
        await HomeWidget.saveWidgetData<String>('shelf_${i}_id', b['id'] ?? '');
        await HomeWidget.saveWidgetData<String>('shelf_${i}_title', b['title'] ?? '');
        await HomeWidget.saveWidgetData<String>('shelf_${i}_cover', b['cover'] ?? '');
      }

      await HomeWidget.updateWidget(
        androidName: 'AudiobookShelfWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating shelf widget: $e');
    }
  }
}

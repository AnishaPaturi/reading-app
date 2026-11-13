import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final int iconCodePoint;
  final int colorValue;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.iconCodePoint,
    required this.colorValue,
    this.isRead = false,
    required this.createdAt,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? timeAgo,
    int? iconCodePoint,
    int? colorValue,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timeAgo': timeAgo,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timeAgo: json['timeAgo'] as String? ?? 'Just now',
      iconCodePoint: json['iconCodePoint'] as int? ?? Icons.notifications_rounded.codePoint,
      colorValue: json['colorValue'] as int? ?? 0xFF8C7CD6,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
    );
  }
}

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  static const _prefKey = 'sanctuary_notifications';

  NotificationsNotifier() : super([]) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(savedJson) as List<dynamic>;
        state = list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
        return;
      }
    } catch (_) {}

    // Initial default notifications if none stored
    state = [
      AppNotification(
        id: '1',
        title: 'Welcome to your Reading Sanctuary',
        message: 'Explore curated books, track your reading sessions, and customize your bookshelf.',
        timeAgo: 'Just now',
        iconCodePoint: Icons.auto_stories_rounded.codePoint,
        colorValue: 0xFF8C7CD6,
        isRead: false,
        createdAt: DateTime.now(),
      ),
      AppNotification(
        id: '2',
        title: 'Reading Goal Milestone',
        message: 'Your reading goals and streaks are ready. Begin reading to track your pace.',
        timeAgo: '1h ago',
        iconCodePoint: Icons.emoji_events_rounded.codePoint,
        colorValue: 0xFFFBBF24,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: '3',
        title: 'New Books Available',
        message: 'Browse the Discover tab to find trending titles tailored to your preferences.',
        timeAgo: '3h ago',
        iconCodePoint: Icons.bookmark_added_rounded.codePoint,
        colorValue: 0xFF10B981,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ];
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(state.map((n) => n.toJson()).toList());
      await prefs.setString(_prefKey, jsonStr);
    } catch (_) {}
  }

  void addNotification({
    required String title,
    required String message,
    IconData icon = Icons.notifications_rounded,
    Color color = const Color(0xFF8C7CD6),
  }) {
    final newNotif = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timeAgo: 'Just now',
      iconCodePoint: icon.codePoint,
      colorValue: (color.r * 255).round() << 16 | (color.g * 255).round() << 8 | (color.b * 255).round() | ((color.a * 255).round() << 24),
      isRead: false,
      createdAt: DateTime.now(),
    );
    state = [newNotif, ...state];
    _saveToPrefs();
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
    _saveToPrefs();
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
    _saveToPrefs();
  }

  void deleteNotification(String id) {
    state = state.where((n) => n.id != id).toList();
    _saveToPrefs();
  }

  void clearAll() {
    state = [];
    _saveToPrefs();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>((ref) {
  return NotificationsNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((n) => !n.isRead).length;
});

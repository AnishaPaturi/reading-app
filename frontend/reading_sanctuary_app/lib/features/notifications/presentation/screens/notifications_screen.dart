import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color color;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.color,
    this.isRead = false,
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late List<NotificationItem> _notifications;
  int _activeFilter = 0; // 0: All, 1: Unread, 2: Goals

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: '1',
        title: 'Goal Milestone Achieved!',
        message: 'You have read for 4 consecutive days! Keep up the momentum.',
        timeAgo: '10m ago',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFBBF24),
      ),
      NotificationItem(
        id: '2',
        title: 'Cloud Sync Completed',
        message: 'Your bookmarks, notes, and reading positions are fully backed up.',
        timeAgo: '1h ago',
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF4379EE),
      ),
      NotificationItem(
        id: '3',
        title: 'Book Recommendation',
        message: 'Based on your recent reads, you might love "The Psychology of Money".',
        timeAgo: '3h ago',
        icon: Icons.auto_awesome_rounded,
        color: ClayColors.primaryPurple,
      ),
      NotificationItem(
        id: '4',
        title: 'Daily Reading Reminder',
        message: 'Take 15 minutes today to enjoy a quiet reading break.',
        timeAgo: 'Yesterday',
        icon: Icons.alarm_rounded,
        color: const Color(0xFFF87171),
        isRead: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notifications.where((n) {
      if (_activeFilter == 1) return !n.isRead;
      if (_activeFilter == 2) return n.title.contains('Goal') || n.title.contains('Streak');
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ClayColors.textDark,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (final n in _notifications) {
                  n.isRead = true;
                }
              });
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(
                color: ClayColors.primaryPurple,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _filterChip('All (${_notifications.length})', 0),
                  const SizedBox(width: 8),
                  _filterChip(
                    'Unread (${_notifications.where((n) => !n.isRead).length})',
                    1,
                  ),
                  const SizedBox(width: 8),
                  _filterChip('Goals', 2),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Notifications List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_rounded, size: 54, color: ClayColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications found',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: ClayColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return InkWell(
                          onTap: () {
                            setState(() => item.isRead = true);
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.isRead ? Colors.white.withValues(alpha: 0.8) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: item.isRead ? const Color(0xFFECE7F4) : ClayColors.primaryPurple.withValues(alpha: 0.4),
                                width: item.isRead ? 1 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.icon, color: item.color, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                                color: ClayColors.textDark,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            item.timeAgo,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: ClayColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.message,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          color: const Color(0xFF6E6280),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: ClayColors.coral,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int index) {
    final active = _activeFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? ClayColors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? ClayColors.deepPurple : const Color(0xFFE2DCF0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w600,
            color: active ? Colors.white : ClayColors.textDark,
          ),
        ),
      ),
    );
  }
}

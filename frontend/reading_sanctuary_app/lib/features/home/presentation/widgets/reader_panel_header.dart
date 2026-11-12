import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../notifications/application/notifications_provider.dart';

class ReaderPanelHeader extends ConsumerWidget {
  final VoidCallback? onMenuPressed;
  final bool showMenuButton;

  const ReaderPanelHeader({
    super.key,
    this.onMenuPressed,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userName = ref.watch(userDisplayNameProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final avatarAsset = ref.watch(userAvatarAssetProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Row(
          children: [
            if (showMenuButton) ...[
              IconButton(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF2D234A), size: 26),
                tooltip: 'Open menu',
              ),
              const SizedBox(width: 4),
            ],

            // Title
            if (isCompact)
              Expanded(
                child: Text(
                  '$userName\'s Sanctuary',
                  style: const TextStyle(
                    color: Color(0xFF2D234A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else ...[
              Text(
                '$userName\'s Sanctuary',
                style: const TextStyle(
                  color: Color(0xFF2D234A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 18),
              // Search Bar
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFEA),
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: const Color(0xFFEBE4DC), width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF9E95A8), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onSubmitted: (_) => context.push('/search'),
                          style: const TextStyle(
                            color: Color(0xFF2D234A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search books, authors, genres...',
                            hintStyle: TextStyle(
                              color: Color(0xFFA59BAE),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],

            if (isCompact) ...[
              IconButton(
                onPressed: () => context.push('/search'),
                icon: const Icon(Icons.search_rounded, color: Color(0xFF2D234A)),
                tooltip: 'Search',
              ),
              const SizedBox(width: 4),
            ],

            // Notification Bell with Badge
            InkWell(
              onTap: () => context.push('/notifications'),
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEBE4DC)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Color(0xFF8C7CD6),
                      size: 20,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEE7186),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // User Profile Section in Menu Bar
            PopupMenuButton<String>(
              tooltip: 'Profile options',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              elevation: 4,
              onSelected: (value) {
                if (value == 'profile') {
                  context.go('/profile');
                } else if (value == 'settings') {
                  context.go('/sync/settings');
                } else if (value == 'logout') {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go('/login');
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            avatarAsset,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Color(0xFF2D234A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              authState.user?.email ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF9E95A8),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded, size: 18, color: Color(0xFF8C7CD6)),
                      SizedBox(width: 10),
                      Text('Profile', style: TextStyle(color: Color(0xFF2D234A), fontSize: 13.5)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded, size: 18, color: Color(0xFF8C7CD6)),
                      SizedBox(width: 10),
                      Text('Settings', style: TextStyle(color: Color(0xFF2D234A), fontSize: 13.5)),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontSize: 13.5)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: isCompact ? Colors.transparent : const Color(0xFFFAF7F5),
                  border: isCompact ? null : Border.all(color: const Color(0xFFEBE4DC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF9482E6), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          avatarAsset,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 8),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Color(0xFF2D234A),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF9E95A8),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

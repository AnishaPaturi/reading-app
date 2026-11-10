import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ReaderSidebar extends ConsumerWidget {
  final VoidCallback? onItemTapped;
  final double? width;

  const ReaderSidebar({super.key, this.onItemTapped, this.width});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.user?.displayName ?? 'Mia';

    return Container(
      width: width ?? 210,
      decoration: const BoxDecoration(
        color: Color(0xFF9482E6),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Avatar & Greeting
            Center(
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/dashboard/avatar_mia.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hello, $userName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Items
            _SidebarNavItem(
              icon: Icons.home_rounded,
              label: 'Panel',
              isActive: true,
              onTap: () {
                onItemTapped?.call();
                context.go('/home');
              },
            ),
            const SizedBox(height: 8),
            _SidebarNavItem(
              icon: Icons.auto_stories_rounded,
              label: 'My Library',
              onTap: () {
                onItemTapped?.call();
                context.go('/library');
              },
            ),
            const SizedBox(height: 8),
            _SidebarNavItem(
              icon: Icons.favorite_rounded,
              label: 'Favorites',
              onTap: () {
                onItemTapped?.call();
                context.go('/library');
              },
            ),
            const SizedBox(height: 8),
            _SidebarNavItem(
              icon: Icons.grid_view_rounded,
              label: 'Booklists',
              onTap: () {
                onItemTapped?.call();
                context.go('/bookshelves');
              },
            ),
            const SizedBox(height: 8),
            _SidebarNavItem(
              icon: Icons.headphones_rounded,
              label: 'Audiobooks',
              onTap: () {
                onItemTapped?.call();
                context.go('/reading');
              },
            ),
            const SizedBox(height: 8),
            _SidebarNavItem(
              icon: Icons.trending_up_rounded,
              label: 'My Progress',
              onTap: () {
                onItemTapped?.call();
                context.go('/statistics');
              },
            ),
            const SizedBox(height: 8),
            _SidebarNavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              onTap: () {
                onItemTapped?.call();
                context.go('/sync/settings');
              },
            ),

            const Spacer(),

            // Logout / Sign Out link
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go('/login');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sign Out',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF9482E6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9482E6),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

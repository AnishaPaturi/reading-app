import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../shared/services/providers.dart';
import '../authentication/presentation/providers/auth_provider.dart';
import 'destinations.dart';

bool _selected(String location, String path) =>
    location == path ||
    location.startsWith('$path/') ||
    (path == '/home' && location == '/dashboard');

class Sidebar extends ConsumerWidget {
  const Sidebar({
    super.key,
    required this.location,
    required this.collapsed,
    this.showToggle = true,
    this.onNavigated,
  });
  final String location;
  final bool collapsed;
  final bool showToggle;
  final VoidCallback? onNavigated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: collapsed ? 76 : 260,
      decoration: const BoxDecoration(
        color: Color(0xFF9482E6),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 8, 12),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reading Sanctuary',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (showToggle)
                    IconButton(
                      tooltip: 'Collapse sidebar',
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                      onPressed: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
                    ),
                ],
              ],
            ),
          ),
          if (collapsed && showToggle)
            IconButton(
              tooltip: 'Expand sidebar',
              icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
              onPressed: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              children: [
                for (final d in sidebarDestinations)
                  _NavItem(
                    dest: d,
                    selected: _selected(location, d.path),
                    collapsed: collapsed,
                    onTap: () {
                      context.go(d.path);
                      onNavigated?.call();
                    },
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          _Footer(collapsed: collapsed),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.dest,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });
  final NavDest dest;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.85);
    return Tooltip(
      message: collapsed ? dest.label : '',
      child: Semantics(
        button: true,
        selected: selected,
        label: dest.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(vertical: 2.5),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.22) : null,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2)
                  : null,
            ),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(dest.icon, size: 22, color: color),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dest.label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: color,
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.collapsed});
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helpBtn = IconButton(
      tooltip: 'Help and support',
      icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
      onPressed: () => context.go('/help'),
    );
    final displayName = ref.watch(userDisplayNameProvider);
    final avatarAsset = ref.watch(userAvatarAssetProvider);

    final avatar = InkWell(
      onTap: () => context.go('/profile'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.asset(avatarAsset, fit: BoxFit.cover),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: collapsed
          ? Column(children: [avatar, const SizedBox(height: 8), helpBtn])
          : Row(children: [
              avatar,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13.5,
                  ),
                ),
              ),
              helpBtn,
            ]),
    );
  }
}

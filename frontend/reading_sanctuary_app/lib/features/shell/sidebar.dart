import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/services/providers.dart';
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: collapsed ? 76 : 268,
      color: dark ? AppColors.walnut : AppColors.parchment,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 8, 12),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                const Icon(Icons.auto_stories, color: AppColors.gold, size: 28),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Reading Sanctuary',
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.serif(Theme.of(context).textTheme.titleLarge)),
                  ),
                  if (showToggle)
                    IconButton(
                      tooltip: 'Collapse sidebar',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
                    ),
                ],
              ],
            ),
          ),
          if (collapsed && showToggle)
            IconButton(
              tooltip: 'Expand sidebar',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => ref.read(sidebarCollapsedProvider.notifier).toggle(),
            ),
          Expanded(
            child: ListView(children: [
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
            ]),
          ),
          const Divider(height: 1),
          _Footer(collapsed: collapsed),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.dest, required this.selected, required this.collapsed, required this.onTap});
  final NavDest dest;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : Theme.of(context).colorScheme.onSurface;
    return Tooltip(
      message: collapsed ? dest.label : '',
      child: Semantics(
        button: true,
        selected: selected,
        label: dest.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.gold.withAlpha(35) : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(dest.icon, size: 22, color: color),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(dest.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color, fontWeight: selected ? FontWeight.w600 : null))),
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
    final isDark = ref.watch(themeProvider) == AppThemeChoice.dark;
    final themeBtn = IconButton(
      tooltip: isDark ? 'Switch to Warm Parchment' : 'Switch to Dark Academia',
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => ref.read(themeProvider.notifier).toggle(),
    );
    final helpBtn = IconButton(
      tooltip: 'Help and support',
      icon: const Icon(Icons.help_outline),
      onPressed: () => context.go('/help'),
    );
    final avatar = InkWell(
      onTap: () => context.go('/profile'),
      child: const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.bronze,
          child: Text('R', style: TextStyle(color: AppColors.ivory))),
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: collapsed
          ? Column(children: [avatar, themeBtn, helpBtn])
          : Row(children: [
              avatar,
              const SizedBox(width: 10),
              const Expanded(child: Text('Reader', overflow: TextOverflow.ellipsis)),
              themeBtn,
              helpBtn,
            ]),
    );
  }
}

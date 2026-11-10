import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/breakpoints.dart';
import '../../shared/services/providers.dart';
import '../audiobook/presentation/widgets/mini_audio_player.dart';
import '../../core/sync/presentation/widgets/sync_status_indicator.dart';
import 'destinations.dart';
import 'sidebar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (location == '/home') {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F0FB),
        body: Column(
          children: [
            Expanded(child: child),
            const MiniAudioPlayer(),
          ],
        ),
      );
    }

    final size = Breakpoints.of(MediaQuery.sizeOf(context).width);
    final isDetail = isDetailRoute(location);
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280), child: child),
    );

    if (size == ScreenSize.mobile) {
      return Scaffold(
        appBar: AppBar(
          leading: isDetail ? const _Back() : null,
          title: Text(titleFor(location)),
          actions: const [_HeaderActions()],
        ),
        drawer: Drawer(
          width: 268,
          child: Builder(
            builder: (ctx) => Sidebar(
              location: location,
              collapsed: false,
              showToggle: false,
              onNavigated: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
        body: content,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniAudioPlayer(),
            _BottomNav(location: location),
          ],
        ),
      );
    }

    final collapsed = size == ScreenSize.tablet || ref.watch(sidebarCollapsedProvider);
    return Scaffold(
      body: Row(children: [
        Sidebar(location: location, collapsed: collapsed, showToggle: size == ScreenSize.desktop),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                if (isDetail) const _Back(),
                Expanded(
                    child: Text(titleFor(location),
                        style: Theme.of(context).textTheme.headlineSmall)),
                const _HeaderActions(),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: content),
            const MiniAudioPlayer(),
          ]),
        ),
      ]),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.canPop() ? context.pop() : context.go('/library'),
      );
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const SyncStatusIndicator(),
        IconButton(
            tooltip: 'Search', icon: const Icon(Icons.search), onPressed: () => context.push('/search')),
        IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications')),
        const SizedBox(width: 4),
      ]);
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? AppColors.walnut : AppColors.parchment,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            for (var i = 0; i < primaryDestinations.length; i++)
              Expanded(
                child: _BottomItem(
                  dest: primaryDestinations[i],
                  selected: location == primaryDestinations[i].path ||
                      location.startsWith('${primaryDestinations[i].path}/'),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.dest, required this.selected});
  final NavDest dest;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : Theme.of(context).colorScheme.onSurface.withAlpha(170);
    return Semantics(
      button: true,
      selected: selected,
      label: dest.label,
      child: InkWell(
        onTap: () => context.go(dest.path),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52,
            height: 30,
            decoration: BoxDecoration(
              color: selected ? AppColors.gold.withAlpha(40) : null,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(dest.icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          Text(dest.label, style: TextStyle(fontSize: 11, color: color)),
        ]),
      ),
    );
  }
}

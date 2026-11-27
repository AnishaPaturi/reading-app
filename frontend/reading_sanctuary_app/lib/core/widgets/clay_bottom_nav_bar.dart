import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClayBottomNavBar extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int>? onTabSelected;
  final String? currentRoute;

  const ClayBottomNavBar({
    super.key,
    this.initialIndex = 1,
    this.onTabSelected,
    this.currentRoute,
  });

  @override
  State<ClayBottomNavBar> createState() => _ClayBottomNavBarState();
}

class _ClayBottomNavBarState extends State<ClayBottomNavBar> {
  late int _currentIndex;

  static const List<_NavItem> _items = [
    _NavItem(
      route: '/home',
      icon: Icons.home_rounded,
      tooltip: 'Home',
    ),
    _NavItem(
      route: '/calendar',
      icon: Icons.calendar_today_rounded,
      tooltip: 'Calendar',
    ),
    _NavItem(
      route: '/library',
      icon: Icons.auto_stories_rounded,
      tooltip: 'Library',
    ),
    _NavItem(
      route: '/profile',
      icon: Icons.person_rounded,
      tooltip: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _resolveIndex(widget.currentRoute) ?? widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant ClayBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentRoute != oldWidget.currentRoute) {
      final idx = _resolveIndex(widget.currentRoute);
      if (idx != null && idx != _currentIndex) {
        setState(() => _currentIndex = idx);
      }
    }
  }

  int? _resolveIndex(String? route) {
    if (route == null) return null;
    if (route.startsWith('/home') || route.startsWith('/dashboard')) return 0;
    if (route.startsWith('/calendar')) return 1;
    if (route.startsWith('/library')) return 2;
    if (route.startsWith('/profile')) return 3;
    return null;
  }

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    widget.onTabSelected?.call(index);

    final targetRoute = _items[index].route;
    try {
      context.go(targetRoute);
    } catch (_) {
      Navigator.of(context).pushNamed(targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF2B1956),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B0E3D).withValues(alpha: 0.45),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isActive = (_currentIndex == index);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onItemTapped(index),
                  borderRadius: BorderRadius.circular(14),
                  splashColor: const Color(0xFFF79C81).withValues(alpha: 0.2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOutCubic,
                    width: isActive ? 52 : 44,
                    height: isActive ? 38 : 36,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFF79C81) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFFD6775E).withValues(alpha: 0.6),
                                offset: const Offset(0, 2.5),
                                blurRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: isActive ? const Color(0xFF2B1956) : const Color(0xFF9E8CD0),
                        size: isActive ? 22 : 24,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          // Sparkle star on bottom-right corner of the bar
          const Positioned(
            right: 14,
            bottom: 8,
            child: _NavSparkle(size: 11, color: Color(0xFF6B55A8)),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String tooltip;

  const _NavItem({
    required this.route,
    required this.icon,
    required this.tooltip,
  });
}

class _NavSparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _NavSparkle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NavSparklePainter(color: color),
    );
  }
}

class _NavSparklePainter extends CustomPainter {
  final Color color;

  _NavSparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy, w, cy);
    path.quadraticBezierTo(cx, cy, cx, h);
    path.quadraticBezierTo(cx, cy, 0, cy);
    path.quadraticBezierTo(cx, cy, cx, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NavSparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

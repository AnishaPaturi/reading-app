import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized 3D Clay Palette matching the reference designs
abstract final class ClayColors {
  static const Color background = Color(0xFFEDE5F8);
  static const Color backgroundEnd = Color(0xFFE4DCF6);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFECE5F8), Color(0xFFE4DCF6)],
  );

  static const Color primaryPurple = Color(0xFF6B45B3);
  static const Color deepPurple = Color(0xFF382761);
  static const Color darkNavy = Color(0xFF281B47);
  static const Color softLilac = Color(0xFFC7B2F0);
  static const Color lightLilac = Color(0xFFDDD2F5);
  static const Color cardBg = Color(0xFFF9F6FE);

  // Clay Accent Tiles
  static const Color peach = Color(0xFFFFC3A6);
  static const Color peachDark = Color(0xFFE89874);
  static const Color coral = Color(0xFFFF926B);
  static const Color coralDark = Color(0xFFE06E45);
  static const Color mint = Color(0xFFA4DFD0);
  static const Color mintDark = Color(0xFF78BAA9);
  static const Color lavender = Color(0xFFC4B1EB);
  static const Color lavenderDark = Color(0xFFA189CE);
  static const Color skyBlue = Color(0xFFB4D8F8);
  static const Color skyBlueDark = Color(0xFF88B3DA);
  static const Color amber = Color(0xFFF2C265);
  static const Color amberDark = Color(0xFFD49E3B);

  // Typography
  static const Color textDark = Color(0xFF2E1A48);
  static const Color textMuted = Color(0xFF7A6894);
  static const Color textLight = Colors.white;
}

/// Floating 3D Purple Bottom Navigation Bar (as seen on every reference screen)
class ClayBottomNav extends StatelessWidget {
  final String activeRoute;

  const ClayBottomNav({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF6246AA),
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF432C82).withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            route: '/home',
            activeRoute: activeRoute,
            tooltip: 'Home',
          ),
          _NavItem(
            icon: Icons.search_rounded,
            route: '/discover',
            activeRoute: activeRoute,
            tooltip: 'Discover',
          ),
          _NavItem(
            icon: Icons.favorite_rounded,
            route: '/favorites',
            activeRoute: activeRoute,
            tooltip: 'Favorites',
          ),
          _NavItem(
            icon: Icons.person_rounded,
            route: '/profile',
            activeRoute: activeRoute,
            tooltip: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String route;
  final String activeRoute;
  final String tooltip;

  const _NavItem({
    required this.icon,
    required this.route,
    required this.activeRoute,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = activeRoute == route ||
        (route == '/favorites' && activeRoute == '/reading') ||
        (route == '/profile' && activeRoute == '/settings') ||
        (route == '/home' && activeRoute == '/library');

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          if (activeRoute != route) {
            context.go(route);
          }
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 26,
            color: isSelected ? const Color(0xFFFFB28D) : Colors.white.withValues(alpha: 0.82),
          ),
        ),
      ),
    );
  }
}

/// 3D Tactile Clay Card
class ClayCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final BoxBorder? border;

  const ClayCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius = 22,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? ClayColors.cardBg;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ??
              Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5791).withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.7),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// 3D Clay Action Tile (for Folders, Genres, Settings items)
class ClayTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? iconWidget;
  final IconData? icon;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;
  final double height;
  final Widget? trailing;

  const ClayTile({
    super.key,
    required this.title,
    this.subtitle,
    this.iconWidget,
    this.icon,
    required this.color,
    this.textColor,
    required this.onTap,
    this.height = 72,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final txtColor = textColor ?? (color.computeLuminance() > 0.5 ? const Color(0xFF382352) : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 3,
              offset: const Offset(0, -1),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: txtColor,
                      height: 1.15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: txtColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (iconWidget != null) iconWidget!,
            if (iconWidget == null && icon != null)
              Icon(icon, size: 28, color: txtColor),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Cute 3D Mini Book representation (for Trending, Quick Access, Mia's Library)
class ClayBookMini extends StatelessWidget {
  final String title;
  final Color color;
  final Widget? motif;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool hasHeart;
  final bool hasStar;
  final bool hasCheck;

  const ClayBookMini({
    super.key,
    required this.title,
    required this.color,
    this.motif,
    this.onTap,
    this.width = 62,
    this.height = 86,
    this.hasHeart = false,
    this.hasStar = false,
    this.hasCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(color, Colors.white, 0.22)!,
                  color,
                  Color.lerp(color, Colors.black, 0.18)!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.45),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                if (motif != null) ...[
                  const SizedBox(height: 4),
                  motif!,
                ],
              ],
            ),
          ),
          if (hasHeart)
            const Positioned(
              top: -8,
              right: 6,
              child: Icon(Icons.favorite_rounded, color: Color(0xFFFF6B6B), size: 16),
            ),
          if (hasStar)
            const Positioned(
              top: -8,
              left: 6,
              child: Icon(Icons.star_rounded, color: Color(0xFFFFD460), size: 16),
            ),
          if (hasCheck)
            Positioned(
              top: -6,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF6ECB98),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// 3D Heart Button (with toggle)
class ClayHeartButton extends StatefulWidget {
  final bool initialFav;
  final ValueChanged<bool>? onToggle;

  const ClayHeartButton({super.key, this.initialFav = true, this.onToggle});

  @override
  State<ClayHeartButton> createState() => _ClayHeartButtonState();
}

class _ClayHeartButtonState extends State<ClayHeartButton> {
  late bool _fav;

  @override
  void initState() {
    super.initState();
    _fav = widget.initialFav;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() => _fav = !_fav);
        widget.onToggle?.call(_fav);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _fav ? const Color(0xFFFF7E67) : const Color(0xFFDDD4ED),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_fav ? const Color(0xFFFF7E67) : Colors.black).withValues(alpha: 0.28),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

/// 3D Pill Action Button
class ClayPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final IconData? icon;
  final double height;
  final double fontSize;

  const ClayPillButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color = ClayColors.primaryPurple,
    this.textColor = Colors.white,
    this.icon,
    this.height = 42,
    this.fontSize = 13.5,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.35),
              blurRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3D Toggle Switch (for Reading Reminders, Settings)
class ClaySwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const ClaySwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? ClayColors.deepPurple : const Color(0xFFDDD2F0),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

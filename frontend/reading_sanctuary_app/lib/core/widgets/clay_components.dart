import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/models/book.dart';
import 'book_cover.dart';

/// Centralized 3D Clay Palette matching the reference designs
abstract final class ClayColors {
  // Canvas Background
  static const Color background = Color(0xFFF4F0FA); // Soft Lavender Milk
  static const Color backgroundEnd = Color(0xFFEDE5F8);
  static const Color canvasBackground = Color(0xFFF4F0FA);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4F0FA), Color(0xFFEDE5F8)],
  );

  // Card Surface (Base)
  static const Color cardBg = Color(0xFFFAF8FF); // Whisper Cream / Off-White
  static const Color cardSurface = Color(0xFFFAF8FF);
  static const Color clayBorder = Color(0xFFDDD6FE); // Pastel Muted Violet border

  // Primary Brand Accent (Royal Lilac / Deep Lavender)
  static const Color royalLilac = Color(0xFF6C5CE7);
  static const Color deepLavender = Color(0xFF5E4BCE);
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color deepPurple = Color(0xFF5E4BCE);
  static const Color darkNavy = Color(0xFF2B234A);

  // Primary Container (Pastel Muted Violet)
  static const Color pastelMutedViolet = Color(0xFFDDD6FE);
  static const Color primaryContainer = Color(0xFFDDD6FE);
  static const Color softLilac = Color(0xFFDDD6FE);
  static const Color lightLilac = Color(0xFFD4C7F5);
  static const Color lilac = Color(0xFFDDD6FE);

  // Warm Accent (Orange) - Soft Creamsicle Coral
  static const Color creamsicleCoral = Color(0xFFFF9E7D);
  static const Color coral = Color(0xFFFF9E7D);
  static const Color coralDark = Color(0xFFFF8A65);
  static const Color peach = Color(0xFFFF9E7D);
  static const Color peachDark = Color(0xFFFF8A65);

  // Warm Accent (Yellow) - Sunny Buttercup
  static const Color sunnyButtercup = Color(0xFFFFD166);
  static const Color buttercup = Color(0xFFFFD166);
  static const Color amber = Color(0xFFFFD166);
  static const Color amberDark = Color(0xFFF8C868);
  static const Color butter = Color(0xFFFFD166);
  static const Color butterDark = Color(0xFFF8C868);

  // Secondary Accent (Teal) - Soft Sage Mint
  static const Color sageMint = Color(0xFF8BD3C7);
  static const Color mint = Color(0xFF8BD3C7);
  static const Color mintDark = Color(0xFF94D2BD);
  static const Color skyBlue = Color(0xFF8BD3C7);
  static const Color skyBlueDark = Color(0xFF94D2BD);
  static const Color sky = Color(0xFF8BD3C7);

  // Secondary Accent (Pink) - Muted Pastel Blush
  static const Color pastelBlush = Color(0xFFF7A8B8);
  static const Color blush = Color(0xFFF7A8B8);
  static const Color rose = Color(0xFFF7A8B8);
  static const Color roseDark = Color(0xFFF4B3C2);
  static const Color lavender = Color(0xFFD4C7F5);
  static const Color lavenderDark = Color(0xFFB8A4E8);

  // Primary Text & Headings (Deep Blackberry Slate)
  static const Color textDark = Color(0xFF2B234A);
  static const Color textHeading = Color(0xFF231C38);
  static const Color blackberrySlate = Color(0xFF2B234A);

  // Secondary Text (Dusty Plum / Muted Mauve)
  static const Color textMuted = Color(0xFF6E6685);
  static const Color dustyPlum = Color(0xFF6E6685);
  static const Color mutedMauve = Color(0xFF7A7292);
  static const Color textSub = Color(0xFF7A7292);
  static const Color textLight = Colors.white;
}

/// Floating 3D Purple Bottom Navigation Bar (as seen on every reference screen)
class ClayBottomNav extends StatelessWidget {
  final String activeRoute;

  const ClayBottomNav({super.key, required this.activeRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5E4BCE), // Rich royal violet base (#5E4BCE)
        borderRadius: BorderRadius.circular(999), // Fully pill-shaped
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E4BCE).withValues(alpha: 0.38),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.25),
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
            icon: Icons.calendar_today_rounded,
            route: '/calendar',
            activeRoute: activeRoute,
            tooltip: 'Calendar',
          ),
          _NavItem(
            icon: Icons.auto_stories_rounded,
            route: '/library',
            activeRoute: activeRoute,
            tooltip: 'Library',
          ),
          _NavItem(
            icon: Icons.headphones_rounded,
            route: '/audiobooks',
            activeRoute: activeRoute,
            tooltip: 'Audiobooks',
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
        (route == '/home' && activeRoute == '/dashboard') ||
        (route == '/settings' && activeRoute == '/sync/settings');

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          if (activeRoute != route) {
            context.go(route);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isSelected ? 48 : 40,
          height: isSelected ? 36 : 36,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF9E7D) : Colors.transparent, // Glowing pastel active state (Creamsicle Coral)
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF9E7D).withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: 21,
              color: isSelected ? const Color(0xFF2B234A) : Colors.white.withValues(alpha: 0.85),
            ),
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
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final BoxBorder? border;

  const ClayCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.margin,
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
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: border ??
              Border.all(
                color: const Color(0xFFDDD6FE).withValues(alpha: 0.6),
                width: 1.2,
              ),
          boxShadow: [
            // Outer Shadow: box-shadow: 0 10px 20px rgba(108, 92, 231, 0.10), 0 4px 6px rgba(0, 0, 0, 0.04);
            BoxShadow(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
            // Specular top highlight
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.8),
              blurRadius: 3,
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
  final Book? book;
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
    this.book,
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
    final Widget bookChild;
    if (book != null) {
      bookChild = SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              BookCover(
                book: book!,
                borderRadius: 10,
                fit: BoxFit.cover,
                elevation: 4,
                aspectRatio: null,
              ),
              if (motif != null)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: motif!,
                ),
            ],
          ),
        ),
      );
    } else {
      bookChild = Container(
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
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          bookChild,
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
        child: const Icon(
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/book.dart';
import '../theme/bookshelf_theme.dart';

class ClayBookSpine extends StatefulWidget {
  final Book book;
  final VoidCallback onTap;
  final double? customHeight;
  final double? customWidth;

  const ClayBookSpine({
    super.key,
    required this.book,
    required this.onTap,
    this.customHeight,
    this.customWidth,
  });

  @override
  State<ClayBookSpine> createState() => _ClayBookSpineState();
}

class _ClayBookSpineState extends State<ClayBookSpine> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final hash = book.id.hashCode.abs();
    final palette = BookshelfTheme.paletteForId(book.id);

    // Dynamic width & height to provide natural variety as seen in the reference image
    final width = widget.customWidth ?? (36.0 + (hash % 3) * 5.0);
    final height = widget.customHeight ?? (130.0 + (hash % 4) * 9.0);

    return Semantics(
      button: true,
      label: '${book.title} by ${book.author}, ${book.status.label}',
      child: Tooltip(
        message: '${book.title}\nby ${book.author}\n${book.status.label}',
        preferBelow: false,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              width: width,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    palette.highlight,
                    palette.base,
                    palette.shadow,
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
                boxShadow: [
                  // Tactile bottom-right 3D clay shadow
                  BoxShadow(
                    color: palette.shadow.withValues(alpha: 0.38),
                    blurRadius: 6,
                    offset: const Offset(1.5, 4),
                  ),
                  // Soft shelf reflection
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.8,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle top light sheen
                  Positioned(
                    top: 0,
                    left: 2,
                    right: 2,
                    height: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                      ),
                    ),
                  ),
                  // Title text rotated 90 degrees (running top to bottom)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: palette.textColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: palette.shadow.withValues(alpha: 0.4),
                              offset: const Offset(0.5, 0.5),
                              blurRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

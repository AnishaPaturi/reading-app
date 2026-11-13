import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../shared/models/book.dart';

/// Renders the dramatic book with dynamic flaming aura, molten burning edge,
/// and disintegration into glowing embers.
class BurningBookEffect extends StatelessWidget {
  final Book book;
  final double ignitionProgress; // 0.0 (unignited) -> 1.0 (fully on fire)
  final double burnProgress; // 0.0 (intact) -> 1.0 (disintegrated)
  final double pulseValue;

  const BurningBookEffect({
    super.key,
    required this.book,
    required this.ignitionProgress,
    required this.burnProgress,
    required this.pulseValue,
  });

  @override
  Widget build(BuildContext context) {
    final auraOpacity = ignitionProgress.clamp(0.0, 1.0);
    final isBurning = burnProgress > 0.01;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Fiery back-light aura & ambient heat glow
          if (auraOpacity > 0.01)
            Positioned.fill(
              child: Transform.scale(
                scale: 1.25 + 0.08 * math.sin(pulseValue * math.pi * 2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(32),
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFF5722).withValues(alpha: 0.6 * auraOpacity),
                        const Color(0xFFFF9800).withValues(alpha: 0.45 * auraOpacity),
                        const Color(0xFFFFC107).withValues(alpha: 0.25 * auraOpacity),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 0.45, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // 2. Animated licking flame tongues around edges
          if (auraOpacity > 0.1)
            Positioned.fill(
              child: CustomPaint(
                painter: _FlameAuraPainter(
                  progress: ignitionProgress,
                  pulse: pulseValue,
                ),
              ),
            ),

          // 3. The Book with burn erosion mask & molten edge
          Transform.scale(
            scale: math.max(0.05, 1.0 - (burnProgress * 0.25)),
            child: Transform.translate(
              offset: Offset(
                math.sin(pulseValue * math.pi * 3) * (ignitionProgress * 2.0),
                -burnProgress * 40.0,
              ),
              child: Opacity(
                opacity: (1.0 - (burnProgress * 1.1)).clamp(0.0, 1.0),
                child: ClipPath(
                  clipper: _BurnClipper(burnProgress: burnProgress),
                  child: Stack(
                    children: [
                      // The real dynamic book cover
                      SizedBox(
                        width: 170,
                        height: 255,
                        child: BookCover(
                          book: book,
                          elevation: 12,
                          borderRadius: 8,
                        ),
                      ),

                      // Dark char / ash gradient encroaching upwards
                      if (isBurning)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CharOverlayPainter(burnProgress: burnProgress),
                          ),
                        ),

                      // Fiery molten burning edge along the erosion line
                      if (isBurning && burnProgress < 0.98)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MoltenEdgePainter(
                              burnProgress: burnProgress,
                              pulse: pulseValue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Creates a jagged, organic rising burn line that erodes the book from bottom to top
class _BurnClipper extends CustomClipper<Path> {
  final double burnProgress;

  _BurnClipper({required this.burnProgress});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (burnProgress <= 0.001) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }
    if (burnProgress >= 0.999) {
      return path; // completely clipped away
    }

    // Burn moves upwards: the bottom portion disappears first
    final burnLineY = size.height * (1.0 - burnProgress);

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // Jagged burn boundary
    const segments = 16;
    final dx = size.width / segments;
    for (int i = segments; i >= 0; i--) {
      final x = i * dx;
      final wave = math.sin((i * 1.3) + (burnProgress * 6.0)) * 10.0 +
          math.cos((i * 2.1) + (burnProgress * 4.0)) * 6.0;
      final y = (burnLineY + wave).clamp(0.0, size.height);
      path.lineTo(x, y);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _BurnClipper oldClipper) =>
      oldClipper.burnProgress != burnProgress;
}

/// Paints burnt carbonized blackening right above the combustion front
class _CharOverlayPainter extends CustomPainter {
  final double burnProgress;

  _CharOverlayPainter({required this.burnProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (burnProgress <= 0.01) return;
    final burnLineY = size.height * (1.0 - burnProgress);
    final charHeight = size.height * 0.28;

    final charGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.45),
        const Color(0xFF1A0A05).withValues(alpha: 0.85),
        const Color(0xFF2E0902).withValues(alpha: 0.95),
      ],
      stops: const [0.0, 0.4, 0.75, 1.0],
    );

    final rect = Rect.fromLTWH(0, math.max(0, burnLineY - charHeight), size.width, charHeight + 10);
    final paint = Paint()..shader = charGradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _CharOverlayPainter oldDelegate) =>
      oldDelegate.burnProgress != burnProgress;
}

/// Paints the bright incandescence and molten orange/gold edge where fire eats paper
class _MoltenEdgePainter extends CustomPainter {
  final double burnProgress;
  final double pulse;

  _MoltenEdgePainter({required this.burnProgress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final burnLineY = size.height * (1.0 - burnProgress);
    const segments = 16;
    final dx = size.width / segments;

    final path = Path();
    for (int i = 0; i <= segments; i++) {
      final x = i * dx;
      final wave = math.sin((i * 1.3) + (burnProgress * 6.0)) * 10.0 +
          math.cos((i * 2.1) + (burnProgress * 4.0)) * 6.0;
      final y = (burnLineY + wave).clamp(0.0, size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Outer flame glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF5722).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0 + math.sin(pulse * math.pi * 4) * 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);

    // Warm golden middle flame
    final midPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(path, midPaint);

    // Incandescent white hot center
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _MoltenEdgePainter oldDelegate) =>
      oldDelegate.burnProgress != burnProgress || oldDelegate.pulse != pulse;
}

/// Paints animated licking flames surrounding the book
class _FlameAuraPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _FlameAuraPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    const flameCount = 18;
    final flamePaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (int i = 0; i < flameCount; i++) {
      final t = i / flameCount;
      final angle = t * math.pi * 2;
      final baseDistance = (size.width / 2) + 12;
      final flameLength = 22.0 * progress +
          math.sin((pulse * math.pi * 3) + (i * 1.5)) * 12.0;

      final cx = size.width / 2 + math.cos(angle) * (baseDistance + flameLength * 0.4);
      final cy = size.height / 2 + math.sin(angle) * (baseDistance + flameLength * 0.4);

      final color = random.nextBool()
          ? const Color(0xFFFF6D00).withValues(alpha: 0.65 * progress)
          : const Color(0xFFFFD54F).withValues(alpha: 0.5 * progress);

      flamePaint.color = color;
      canvas.drawCircle(Offset(cx, cy), 14.0 * progress, flamePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FlameAuraPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pulse != pulse;
}

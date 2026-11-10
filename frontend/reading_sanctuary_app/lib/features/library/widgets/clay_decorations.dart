import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/bookshelf_theme.dart';

/// Adorable 3D Clay flower in a terracotta pot (as seen on the top shelf).
class ClayFlowerPot extends StatelessWidget {
  const ClayFlowerPot({super.key, this.scale = 1.0});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58 * scale,
      height: 96 * scale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Flower on top
          Positioned(
            top: 2 * scale,
            child: _ClayFlower(scale: scale),
          ),
          // Stem & Leaves
          Positioned(
            bottom: 34 * scale,
            child: _StemAndLeaves(scale: scale),
          ),
          // Terracotta Pot
          Positioned(
            bottom: 0,
            child: _TerracottaPot(
              width: 44 * scale,
              height: 38 * scale,
              rimHeight: 11 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClayFlower extends StatelessWidget {
  const _ClayFlower({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = 38.0 * scale;
    final petalSize = 14.0 * scale;
    final centerSize = 12.0 * scale;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 5 petals arranged in circle
          for (var i = 0; i < 5; i++)
            Transform.translate(
              offset: Offset(
                11 * scale * math.cos(i * 2 * math.pi / 5 - math.pi / 2),
                11 * scale * math.sin(i * 2 * math.pi / 5 - math.pi / 2),
              ),
              child: Container(
                width: petalSize,
                height: petalSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.2, -0.2),
                    colors: [
                      Color(0xFF98C3F5),
                      BookshelfTheme.flowerBlue,
                      Color(0xFF6F9DDC),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5D88C5).withValues(alpha: 0.4),
                      blurRadius: 3,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          // Center yellow button
          Container(
            width: centerSize,
            height: centerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.25, -0.25),
                colors: [
                  Color(0xFFFFDF78),
                  BookshelfTheme.flowerYellow,
                  Color(0xFFE2AD3C),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StemAndLeaves extends StatelessWidget {
  const _StemAndLeaves({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44 * scale,
      height: 28 * scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Green stem
          Container(
            width: 4 * scale,
            height: 24 * scale,
            decoration: BoxDecoration(
              color: BookshelfTheme.plantGreen,
              borderRadius: BorderRadius.circular(2 * scale),
            ),
          ),
          // Left leaf
          Positioned(
            left: 6 * scale,
            bottom: 4 * scale,
            child: Transform.rotate(
              angle: -0.6,
              child: Container(
                width: 14 * scale,
                height: 7 * scale,
                decoration: BoxDecoration(
                  color: BookshelfTheme.plantGreen,
                  borderRadius: BorderRadius.circular(7 * scale),
                ),
              ),
            ),
          ),
          // Right leaf
          Positioned(
            right: 6 * scale,
            bottom: 4 * scale,
            child: Transform.rotate(
              angle: 0.6,
              child: Container(
                width: 14 * scale,
                height: 7 * scale,
                decoration: BoxDecoration(
                  color: BookshelfTheme.plantGreen,
                  borderRadius: BorderRadius.circular(7 * scale),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hanging macrame string-of-pearls planter (top shelf left).
class ClayHangingPlant extends StatelessWidget {
  const ClayHangingPlant({super.key, this.scale = 1.0});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52 * scale,
      height: 98 * scale,
      child: CustomPaint(
        painter: _HangingPlantPainter(scale: scale),
      ),
    );
  }
}

class _HangingPlantPainter extends CustomPainter {
  final double scale;
  _HangingPlantPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw macrame rope hanger
    final ropePaint = Paint()
      ..color = const Color(0xFFC79E78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;

    final potTopY = 36.0 * scale;
    final potBottomY = 56.0 * scale;
    final potLeftX = 10.0 * scale;
    final potRightX = w - 10.0 * scale;
    final potCenterX = w / 2;

    // Hanging hook ring
    canvas.drawCircle(
      Offset(potCenterX, 8 * scale),
      3 * scale,
      ropePaint,
    );

    // Left and right cords
    final cordPath = Path()
      ..moveTo(potCenterX, 11 * scale)
      ..lineTo(potLeftX + 3 * scale, potTopY + 2 * scale)
      ..moveTo(potCenterX, 11 * scale)
      ..lineTo(potRightX - 3 * scale, potTopY + 2 * scale)
      ..moveTo(potCenterX, 11 * scale)
      ..lineTo(potCenterX, potTopY + 2 * scale);
    canvas.drawPath(cordPath, ropePaint);

    // Clay Pot
    final potRRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(potLeftX, potTopY, potRightX, potBottomY),
      bottomLeft: Radius.circular(12 * scale),
      bottomRight: Radius.circular(12 * scale),
      topLeft: Radius.circular(4 * scale),
      topRight: Radius.circular(4 * scale),
    );

    final potPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFF1D4B3),
          Color(0xFFE2BE97),
          Color(0xFFCBA176),
        ],
      ).createShader(potRRect.outerRect);

    // Drop shadow
    canvas.drawRRect(
      potRRect.shift(Offset(0, 3 * scale)),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );
    canvas.drawRRect(potRRect, potPaint);

    // Hanging pearl strings (vines)
    final pearlPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.2),
        colors: [
          BookshelfTheme.plantGreenLight,
          BookshelfTheme.plantGreen,
          Color(0xFF5D977A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    void drawPearlChain(double startX, double startY, int count, double spacing) {
      for (var i = 0; i < count; i++) {
        final cx = startX + math.sin(i * 0.8) * (2 * scale);
        final cy = startY + i * spacing;
        final r = (3.2 - (i == count - 1 ? 0.8 : 0)) * scale;
        canvas.drawCircle(Offset(cx, cy), r, pearlPaint);
      }
    }

    drawPearlChain(potLeftX + 5 * scale, potBottomY - 2 * scale, 5, 6.0 * scale);
    drawPearlChain(potLeftX + 11 * scale, potBottomY + 1 * scale, 7, 5.5 * scale);
    drawPearlChain(potCenterX, potBottomY, 6, 6.0 * scale);
    drawPearlChain(potRightX - 11 * scale, potBottomY + 1 * scale, 7, 5.5 * scale);
    drawPearlChain(potRightX - 5 * scale, potBottomY - 2 * scale, 5, 6.0 * scale);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Adorable potted succulent / snake plant (shelf 3 right).
class ClayAloePot extends StatelessWidget {
  const ClayAloePot({super.key, this.scale = 1.0});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52 * scale,
      height: 72 * scale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 4 succulent leaves
          Positioned(
            bottom: 30 * scale,
            child: _AloeLeaves(scale: scale),
          ),
          // Terracotta Pot
          Positioned(
            bottom: 0,
            child: _TerracottaPot(
              width: 44 * scale,
              height: 35 * scale,
              rimHeight: 10 * scale,
            ),
          ),
        ],
      ),
    );
  }
}

class _AloeLeaves extends StatelessWidget {
  const _AloeLeaves({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44 * scale,
      height: 38 * scale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Center tall leaf
          Positioned(
            bottom: 0,
            child: Container(
              width: 10 * scale,
              height: 36 * scale,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    BookshelfTheme.plantGreenLight,
                    BookshelfTheme.plantGreen,
                    Color(0xFF5E9A7B),
                  ],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5 * scale)),
              ),
            ),
          ),
          // Left leaf
          Positioned(
            left: 5 * scale,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.38,
              alignment: Alignment.bottomRight,
              child: Container(
                width: 9 * scale,
                height: 28 * scale,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BookshelfTheme.plantGreenLight, BookshelfTheme.plantGreen],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(5 * scale)),
                ),
              ),
            ),
          ),
          // Right leaf
          Positioned(
            right: 5 * scale,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.38,
              alignment: Alignment.bottomLeft,
              child: Container(
                width: 9 * scale,
                height: 28 * scale,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BookshelfTheme.plantGreenLight, BookshelfTheme.plantGreen],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(5 * scale)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Creeping string-of-pearls in shallow bowl pot (shelf 3 left).
class ClayBowlSucculent extends StatelessWidget {
  const ClayBowlSucculent({super.key, this.scale = 1.0});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54 * scale,
      height: 52 * scale,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Terracotta low pot
          Positioned(
            bottom: 0,
            child: _TerracottaPot(
              width: 48 * scale,
              height: 28 * scale,
              rimHeight: 8 * scale,
            ),
          ),
          // Cascading pearl beads
          Positioned(
            bottom: 6 * scale,
            child: SizedBox(
              width: 50 * scale,
              height: 42 * scale,
              child: CustomPaint(
                painter: _CascadingPearlsPainter(scale: scale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CascadingPearlsPainter extends CustomPainter {
  final double scale;
  _CascadingPearlsPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final pearlPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        colors: [
          BookshelfTheme.plantGreenLight,
          BookshelfTheme.plantGreen,
          Color(0xFF5A9477),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Clustered top mound
    const topPositions = [
      Offset(12, 16),
      Offset(18, 12),
      Offset(24, 10),
      Offset(30, 12),
      Offset(36, 16),
      Offset(16, 20),
      Offset(22, 17),
      Offset(28, 17),
      Offset(34, 20),
    ];

    for (final pos in topPositions) {
      canvas.drawCircle(Offset(pos.dx * scale, pos.dy * scale), 4.2 * scale, pearlPaint);
    }

    // Trailing draped vines over the rim
    void drawVine(double x, double startY, List<double> yOffsets) {
      for (final y in yOffsets) {
        canvas.drawCircle(Offset(x * scale, (startY + y) * scale), 3.5 * scale, pearlPaint);
      }
    }

    drawVine(10, 22, [0, 5, 10, 15]);
    drawVine(16, 24, [0, 5, 11]);
    drawVine(24, 25, [0, 6]);
    drawVine(34, 24, [0, 5, 10]);
    drawVine(40, 22, [0, 5, 11, 16]);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Generic Terracotta Pot component with 3D rolled rim and clay shading.
class _TerracottaPot extends StatelessWidget {
  final double width;
  final double height;
  final double rimHeight;

  const _TerracottaPot({
    required this.width,
    required this.height,
    required this.rimHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rolled Rim
        Container(
          width: width,
          height: rimHeight,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BookshelfTheme.potHighlight,
                BookshelfTheme.potBase,
                BookshelfTheme.potShadow,
              ],
            ),
            borderRadius: BorderRadius.circular(rimHeight / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        // Pot Body (tapered)
        Container(
          width: width * 0.84,
          height: height - rimHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                BookshelfTheme.potHighlight,
                BookshelfTheme.potBase,
                BookshelfTheme.potShadow,
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

/// 4-pointed Sparkle Star ✦ as seen on the bottom right of the reference image.
class ClaySparkleStar extends StatelessWidget {
  const ClaySparkleStar({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SparklePainter(),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, w, cy)
      ..quadraticBezierTo(cx, cy, cx, h)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.75),
          const Color(0xFFDED3F4).withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

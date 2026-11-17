import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';

class BookDeleteDialog extends StatefulWidget {
  final Book book;

  const BookDeleteDialog({super.key, required this.book});

  static Future<bool?> show(BuildContext context, Book book) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BookDeleteDialog(book: book),
    );
  }

  @override
  State<BookDeleteDialog> createState() => _BookDeleteDialogState();
}

class _BookDeleteDialogState extends State<BookDeleteDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _particleProgress;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _particleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() => _isAnimating = true);
    await _controller.forward();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2), // Warm Parchment
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE4DAD1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Cover Container with Particle Effects
                SizedBox(
                  height: 190,
                  width: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isAnimating)
                        AnimatedBuilder(
                          animation: _particleProgress,
                          builder: (context, _) {
                            return CustomPaint(
                              size: const Size(220, 190),
                              painter: _ParticlePainter(
                                progress: _particleProgress.value,
                              ),
                            );
                          },
                        ),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: SizedBox(
                            width: 105,
                            height: 155,
                            child: BookCover(
                              book: widget.book,
                              borderRadius: 8,
                              elevation: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Title & Subtitle
                Text(
                  'Move to Deleted?',
                  style: GoogleFonts.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C221E),
                    letterSpacing: -0.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '"${widget.book.title}" will be placed on the Forgotten Shelf. You can restore it or permanently delete it later.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF75675F),
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isAnimating ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B584C),
                          side: const BorderSide(color: Color(0xFFD6C8BC)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAnimating ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B2635), // Dark Academia Crimson
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isAnimating
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.delete_outline_rounded, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Delete',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_ParticleData> _particles = _generateParticles(36);

  _ParticlePainter({required this.progress});

  static List<_ParticleData> _generateParticles(int count) {
    final list = <_ParticleData>[];
    final random = math.Random(42);
    for (int i = 0; i < count; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = 40.0 + random.nextDouble() * 70.0;
      final size = 2.5 + random.nextDouble() * 4.0;
      final isGold = random.nextBool();
      list.add(_ParticleData(
        angle: angle,
        speed: speed,
        size: size,
        color: isGold
            ? const Color(0xFFD4AF37) // Antique Gold
            : const Color(0xFF7B3FA0), // Mystical Deep Purple
      ));
    }
    return list;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      final currentDist = p.speed * progress;
      final x = center.dx + currentDist * math.cos(p.angle);
      final y = center.dy + currentDist * math.sin(p.angle);

      final currentAlpha = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: currentAlpha);

      final currentRadius = p.size * (1.0 - progress * 0.4);
      canvas.drawCircle(Offset(x, y), currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ParticleData {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _ParticleData({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

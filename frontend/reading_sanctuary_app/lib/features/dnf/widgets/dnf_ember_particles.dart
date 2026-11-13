import 'dart:math' as math;
import 'package:flutter/material.dart';

class DnfEmberParticles extends StatefulWidget {
  final double intensity; // 0.0 (calm ambient embers) to 1.0 (roaring disintegration)
  final bool spawnFromCenter;

  const DnfEmberParticles({
    super.key,
    this.intensity = 0.5,
    this.spawnFromCenter = false,
  });

  @override
  State<DnfEmberParticles> createState() => _DnfEmberParticlesState();
}

class _DnfEmberParticlesState extends State<DnfEmberParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Ember> _embers = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_tick);

    _controller.repeat();
  }

  void _tick() {
    if (!mounted) return;
    final count = (widget.intensity * 45).round() + 15;
    while (_embers.length < count) {
      _embers.add(_Ember.spawn(
        _random,
        fromCenter: widget.spawnFromCenter,
        highEnergy: widget.intensity > 0.5,
      ));
    }

    for (int i = _embers.length - 1; i >= 0; i--) {
      final ember = _embers[i];
      ember.update(widget.intensity);
      if (ember.isDead) {
        _embers.removeAt(i);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _EmberPainter(embers: _embers),
        size: Size.infinite,
      ),
    );
  }
}

class _Ember {
  double x; // 0..1 normalized or absolute
  double y;
  double vx;
  double vy;
  double radius;
  double alpha;
  double maxLife;
  double age;
  Color color;
  double wobbleSpeed;
  double wobbleOffset;

  _Ember({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.alpha,
    required this.maxLife,
    required this.age,
    required this.color,
    required this.wobbleSpeed,
    required this.wobbleOffset,
  });

  bool get isDead => age >= maxLife;

  factory _Ember.spawn(math.Random random, {bool fromCenter = false, bool highEnergy = false}) {
    final colors = [
      const Color(0xFFFFE082), // pale gold
      const Color(0xFFFFB300), // warm amber
      const Color(0xFFFF6F00), // deep orange
      const Color(0xFFFF3D00), // hot fire red
      const Color(0xFFFFF9C4), // sparkling white-gold
    ];

    double spawnX;
    double spawnY;

    if (fromCenter) {
      spawnX = 0.5 + (random.nextDouble() - 0.5) * 0.45;
      spawnY = 0.5 + (random.nextDouble() - 0.5) * 0.45;
    } else {
      spawnX = random.nextDouble();
      spawnY = 0.85 + random.nextDouble() * 0.2;
    }

    final speedMultiplier = highEnergy ? 1.5 : 1.0;

    return _Ember(
      x: spawnX,
      y: spawnY,
      vx: (random.nextDouble() - 0.5) * 0.003 * speedMultiplier,
      vy: -(0.003 + random.nextDouble() * 0.008) * speedMultiplier,
      radius: 1.2 + random.nextDouble() * (highEnergy ? 3.5 : 2.0),
      alpha: 0.6 + random.nextDouble() * 0.4,
      maxLife: 40 + random.nextDouble() * 80,
      age: 0,
      color: colors[random.nextInt(colors.length)],
      wobbleSpeed: 0.05 + random.nextDouble() * 0.1,
      wobbleOffset: random.nextDouble() * math.pi * 2,
    );
  }

  void update(double intensity) {
    age += 1;
    final lifeRatio = age / maxLife;

    // Upward acceleration with gentle sinusoidal drift
    y += vy * (1.0 + intensity * 0.5);
    x += vx + math.sin(age * wobbleSpeed + wobbleOffset) * 0.0015;

    // Fade out as life ends
    if (lifeRatio > 0.6) {
      alpha = math.max(0.0, (1.0 - lifeRatio) / 0.4);
    }
  }
}

class _EmberPainter extends CustomPainter {
  final List<_Ember> embers;

  _EmberPainter({required this.embers});

  @override
  void paint(Canvas canvas, Size size) {
    for (final ember in embers) {
      final cx = ember.x * size.width;
      final cy = ember.y * size.height;

      final paint = Paint()
        ..color = ember.color.withValues(alpha: ember.alpha.clamp(0.0, 1.0))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ember.radius * 0.8);

      canvas.drawCircle(Offset(cx, cy), ember.radius, paint);

      // Bright incandescent core
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: (ember.alpha * 0.8).clamp(0.0, 1.0));
      canvas.drawCircle(Offset(cx, cy), ember.radius * 0.45, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) => true;
}

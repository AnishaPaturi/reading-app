import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/book.dart';
import '../../../shared/services/providers.dart';
import '../models/dnf_completion_data.dart';
import '../widgets/burning_book_effect.dart';
import '../widgets/dnf_completion_card.dart';
import '../widgets/dnf_ember_particles.dart';

/// The 5-Phase Cinematic Book-Retirement Experience
class DnfCinematicScreen extends ConsumerStatefulWidget {
  final Book book;
  final ReadingStatus? previousStatus;
  final String? initialReason;
  final String? initialNotes;

  const DnfCinematicScreen({
    super.key,
    required this.book,
    this.previousStatus,
    this.initialReason,
    this.initialNotes,
  });

  /// Static helper to trigger the cinematic experience
  static Future<void> trigger(
    BuildContext context, {
    required Book book,
    ReadingStatus? previousStatus,
    String? initialReason,
    String? initialNotes,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: DnfCinematicScreen(
              book: book,
              previousStatus: previousStatus,
              initialReason: initialReason,
              initialNotes: initialNotes,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  ConsumerState<DnfCinematicScreen> createState() => _DnfCinematicScreenState();
}

class _DnfCinematicScreenState extends ConsumerState<DnfCinematicScreen>
    with TickerProviderStateMixin {
  late final AnimationController _cinematicController;
  late final AnimationController _pulseController;

  // Phase Animations
  late final Animation<double> _extractionScale;
  late final Animation<double> _backgroundDarken;
  late final Animation<double> _ignitionProgress;
  late final Animation<double> _burnProgress;
  late final Animation<double> _revealOpacity;

  bool _hasTriggeredHaptic = false;
  bool _hasPersistedStatus = false;
  late DnfCompletionData _completionData;

  @override
  void initState() {
    super.initState();

    _completionData = DnfCompletionData.fromBook(
      widget.book,
      reason: widget.initialReason,
      notes: widget.initialNotes,
    );

    // 4.5 second cinematic progression
    _cinematicController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Phase 1: 0.0 -> 0.15 (0.0s - 0.7s) Book Extraction
    _extractionScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _cinematicController,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOutCubic),
      ),
    );

    // Phase 2: 0.15 -> 0.35 (0.7s - 1.6s) Background Darkening & Vignette
    _backgroundDarken = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cinematicController,
        curve: const Interval(0.12, 0.35, curve: Curves.easeInOut),
      ),
    );

    // Phase 3: 0.30 -> 0.55 (1.4s - 2.5s) Ignition of Flames
    _ignitionProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cinematicController,
        curve: const Interval(0.28, 0.52, curve: Curves.easeInCubic),
      ),
    );

    // Phase 4: 0.52 -> 0.85 (2.3s - 3.8s) Book Disintegration into Embers
    _burnProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cinematicController,
        curve: const Interval(0.50, 0.85, curve: Curves.easeInOutQuad),
      ),
    );

    // Phase 5: 0.82 -> 1.00 (3.7s - 4.5s) Reveal of DNF Completion Screen
    _revealOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cinematicController,
        curve: const Interval(0.82, 1.0, curve: Curves.easeOut),
      ),
    );

    _cinematicController.addListener(_onTick);
    _cinematicController.forward();

    // Persist the DNF status to database & repository
    _persistDnf();
  }

  void _persistDnf() {
    if (_hasPersistedStatus) return;
    _hasPersistedStatus = true;
    ref.read(booksProvider.notifier).setStatus(
          widget.book.id,
          ReadingStatus.dnf,
          dnfDate: _completionData.dnfDate,
          dnfReason: _completionData.dnfReason,
          dnfNotes: _completionData.dnfNotes,
        );
  }

  void _onTick() {
    final progress = _cinematicController.value;

    // Haptic feedback at ignition
    if (progress >= 0.30 && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticFeedback.mediumImpact();
    }

    if (progress >= 0.65 && progress < 0.68) {
      HapticFeedback.lightImpact();
    }
  }

  void _skipToEnd() {
    _cinematicController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _handleBackToShelf() {
    Navigator.of(context).pop();
  }

  void _handleGoToDnfShelf() {
    Navigator.of(context).pop();
    context.go('/tracker/dnf');
  }

  Future<void> _handleUndo() async {
    final revertStatus = widget.previousStatus ??
        (_completionData.previousStatus == ReadingStatus.dnf
            ? ReadingStatus.currentlyReading
            : _completionData.previousStatus);

    await ref.read(booksProvider.notifier).setStatus(
          widget.book.id,
          revertStatus,
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.book.title}" restored to ${revertStatus.label}.'),
          backgroundColor: const Color(0xFF2C2434),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cinematicController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: Listenable.merge([_cinematicController, _pulseController]),
        builder: (context, _) {
          final isRevealed = _revealOpacity.value > 0.95;
          final isBurningActive = _burnProgress.value < 0.99;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Dark Academia Deep Backdrop & Blur
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 12.0 * _backgroundDarken.value,
                  sigmaY: 12.0 * _backgroundDarken.value,
                ),
                child: Container(
                  color: Colors.black.withValues(
                    alpha: 0.85 + (0.12 * _backgroundDarken.value),
                  ),
                ),
              ),

              // 2. Ambient Dark Academia vignette & candle glow
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.1),
                      radius: 1.2,
                      colors: [
                        const Color(0xFF2E1912).withValues(alpha: 0.45 * _ignitionProgress.value),
                        const Color(0xFF0F0B13).withValues(alpha: 0.85),
                        const Color(0xFF060408),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Embers and Sparks rising across the sanctuary
              Positioned.fill(
                child: DnfEmberParticles(
                  intensity: math.max(
                    0.2,
                    _ignitionProgress.value * 0.4 + _burnProgress.value * 0.6,
                  ),
                  spawnFromCenter: isBurningActive && _burnProgress.value > 0.1,
                ),
              ),

              // 4. Burning Book in the Center (Phases 1 - 4)
              if (!isRevealed)
                Center(
                  child: Transform.scale(
                    scale: _extractionScale.value,
                    child: BurningBookEffect(
                      book: widget.book,
                      ignitionProgress: _ignitionProgress.value,
                      burnProgress: _burnProgress.value,
                      pulseValue: _pulseController.value,
                    ),
                  ),
                ),

              // 5. Revealed Completion Screen (Phase 5)
              if (_revealOpacity.value > 0.01)
                Positioned.fill(
                  child: Opacity(
                    opacity: _revealOpacity.value,
                    child: SafeArea(
                      child: DnfCompletionCard(
                        data: _completionData,
                        onBackToShelf: _handleBackToShelf,
                        onDnfShelf: _handleGoToDnfShelf,
                        onUndo: _handleUndo,
                      ),
                    ),
                  ),
                ),

              // 6. Discreet "Skip Ceremony" button during animation
              if (!isRevealed && _cinematicController.value < 0.8)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 20,
                  child: TextButton.icon(
                    onPressed: _skipToEnd,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.fast_forward_rounded, size: 16),
                    label: Text(
                      'Skip Ceremony',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/clay_components.dart';
import '../authentication/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _splashTimer;
  bool _delayElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(milliseconds: 1600), () {
      _delayElapsed = true;
      _tryNavigate();
    });
    if (!ref.read(authSessionRestoredProvider)) {
      ref.read(authNotifierProvider.notifier).restoreSession().then((_) {
        _tryNavigate();
      });
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _tryNavigate() {
    if (!mounted || _navigated || !_delayElapsed) return;
    if (!ref.read(authSessionRestoredProvider)) return;
    if (GoRouterState.of(context).uri.path != '/') return;

    _navigated = true;
    final isAuthenticated = ref.read(authNotifierProvider).isAuthenticated;
    context.go(isAuthenticated ? '/home' : '/landing');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(authSessionRestoredProvider, (_, restored) {
      if (restored) {
        _tryNavigate();
      }
    });
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: ClayColors.backgroundGradient,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOut,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                          offset: Offset(0, 16 * (1 - t)), child: child),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Puffy Clay Mascot & Icon Container
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ClayColors.primaryPurple
                                    .withValues(alpha: 0.22),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                blurRadius: 4,
                                offset: Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/dashboard/star_mascot.png',
                              width: 56,
                              height: 56,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.auto_stories_rounded,
                                size: 48,
                                color: ClayColors.primaryPurple,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Reading Sanctuary',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: ClayColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                ClayColors.primaryPurple.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your books. Your thoughts. Your sanctuary.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

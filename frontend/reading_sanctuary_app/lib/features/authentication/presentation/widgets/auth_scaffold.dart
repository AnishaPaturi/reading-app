import 'package:flutter/material.dart';
import '../theme/auth_palette.dart';

class AuthScaffold extends StatelessWidget {
  final String headerAsset;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.headerAsset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 500;

    return Scaffold(
      backgroundColor: AuthPalette.backgroundDark,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AuthPalette.backgroundLight,
              AuthPalette.backgroundDark,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Ambient Decorative Plants on wider displays
            if (!isCompact) ...[
              Positioned(
                left: 0,
                bottom: 0,
                height: 280,
                child: Image.asset(
                  'assets/images/auth/plant_left.png',
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                height: 280,
                child: Image.asset(
                  'assets/images/auth/flower_right.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],

            // Main Centered Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 16 : 24,
                    vertical: isCompact ? 12 : 28,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AuthPalette.cardSurface,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AuthPalette.cardShadow,
                            blurRadius: 36,
                            offset: const Offset(0, 16),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 3D Header Illustration (Character, Clouds, Welcome Text)
                          Image.asset(
                            headerAsset,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),

                          // Inner Raised Form Container
                          Transform.translate(
                            // Slight negative offset to let the character's hand overlap naturally
                            offset: const Offset(0, -14),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 14),
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                              decoration: BoxDecoration(
                                color: AuthPalette.cardInner,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

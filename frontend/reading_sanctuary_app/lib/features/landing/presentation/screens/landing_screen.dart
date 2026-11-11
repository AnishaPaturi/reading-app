import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/theme/auth_palette.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _navigateToLogin(BuildContext context) {
    context.go('/login');
  }

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
            // Ambient Decorative Plants on wider displays (matching the 3D aesthetic)
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 430,
                    maxHeight: 860,
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isCompact ? 12 : 24,
                      vertical: isCompact ? 8 : 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6FC),
                      borderRadius: BorderRadius.circular(44),
                      boxShadow: const [
                        BoxShadow(
                          color: AuthPalette.cardShadow,
                          blurRadius: 36,
                          offset: Offset(0, 16),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Color(0x99FFFFFF),
                          blurRadius: 10,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        _buildSlide(context),

                        // Top Navigation Controls (Skip)
                        Positioned(
                          top: 14,
                          left: 18,
                          right: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => _navigateToLogin(context),
                                child: const Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: AuthPalette.textLink,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildSlide(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Slide Graphic
            Image.asset(
              'assets/images/landing/landing_slide_1.png',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),

            // Interactive Button Overlay for "Let's go ➔"
            Positioned(
              left: constraints.maxWidth * 0.10,
              right: constraints.maxWidth * 0.10,
              bottom: constraints.maxHeight * 0.08,
              height: constraints.maxHeight * 0.08,
              child: _InteractivePillButton(
                tooltip: "Let's go",
                onTap: () => _navigateToLogin(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InteractivePillButton extends StatefulWidget {
  final String tooltip;
  final VoidCallback onTap;

  const _InteractivePillButton({
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_InteractivePillButton> createState() => _InteractivePillButtonState();
}

class _InteractivePillButtonState extends State<_InteractivePillButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: _isPressed ? Colors.black.withValues(alpha: 0.08) : Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}

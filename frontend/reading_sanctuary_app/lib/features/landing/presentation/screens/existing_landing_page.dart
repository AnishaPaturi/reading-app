import 'package:flutter/material.dart';
import '../../../authentication/presentation/theme/auth_palette.dart';

class ExistingLandingPage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const ExistingLandingPage({
    super.key,
    required this.onGetStarted,
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
                    child: _buildSlide(context),
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

            // Interactive Button Overlay for "Let's go ➔" / "Get Started"
            Positioned(
              left: constraints.maxWidth * 0.10,
              right: constraints.maxWidth * 0.10,
              bottom: constraints.maxHeight * 0.02,
              height: constraints.maxHeight * 0.08,
              child: _InteractivePillButton(
                key: const Key('first_landing_get_started'),
                tooltip: "Let's go",
                onTap: onGetStarted,
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
    super.key,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: widget.onTap,
          onHighlightChanged: (pressed) {
            setState(() {
              _isPressed = pressed;
            });
          },
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: const Center(
              child: Opacity(
                opacity: 0.0,
                child: Text('Get Started'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

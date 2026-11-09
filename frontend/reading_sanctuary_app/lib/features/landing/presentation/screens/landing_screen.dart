import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/theme/auth_palette.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _goToNextPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  void _handleTurnOnNotifications() {
    // In a production build, permission_handler or flutter_local_notifications is invoked
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Notifications enabled!'),
          ],
        ),
        backgroundColor: AuthPalette.primaryPurpleDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _navigateToLogin();
    });
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
                        // PageView with Slides
                        PageView(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          children: [
                            _buildSlideOne(),
                            _buildSlideTwo(),
                          ],
                        ),

                        // Top Navigation Controls (Skip / Sign In)
                        Positioned(
                          top: 14,
                          left: 18,
                          right: 18,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentPage > 0)
                                _CircleNavButton(
                                  icon: Icons.arrow_back_ios_new_rounded,
                                  tooltip: 'Back',
                                  onTap: () {
                                    _pageController.animateToPage(
                                      0,
                                      duration: const Duration(milliseconds: 320),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                )
                              else
                                const SizedBox(width: 40),
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: _navigateToLogin,
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

                        // Bottom Page Indicator Dots
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(2, (index) {
                              final isActive = _currentPage == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 240),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isActive ? 22 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AuthPalette.primaryPurpleDark
                                      : AuthPalette.textMuted.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
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

  Widget _buildSlideOne() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Slide 1 Graphic
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
                onTap: _goToNextPage,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlideTwo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Slide 2 Graphic
            Image.asset(
              'assets/images/landing/landing_slide_2.png',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
            ),

            // Interactive Button Overlay for "Turn on notifications"
            Positioned(
              left: constraints.maxWidth * 0.10,
              right: constraints.maxWidth * 0.10,
              bottom: constraints.maxHeight * 0.09,
              height: constraints.maxHeight * 0.075,
              child: _InteractivePillButton(
                tooltip: 'Turn on notifications',
                onTap: _handleTurnOnNotifications,
              ),
            ),

            // Interactive Link Overlay for "Maybe later"
            Positioned(
              left: constraints.maxWidth * 0.25,
              right: constraints.maxWidth * 0.25,
              bottom: constraints.maxHeight * 0.035,
              height: constraints.maxHeight * 0.045,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _navigateToLogin,
                child: const SizedBox.expand(),
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

class _CircleNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.75),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 16,
              color: AuthPalette.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

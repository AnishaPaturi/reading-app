import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/theme/auth_palette.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  void _goToNextPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Horizontal Swipeable Landing Slides
                            PageView(
                              controller: _pageController,
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                              children: [
                                _buildSlide1(context, constraints),
                                _buildSlide2(context, constraints),
                              ],
                            ),

                            // Page Indicators placed neatly in the card
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: constraints.maxHeight * 0.108,
                              child: IgnorePointer(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(2, (index) {
                                    final isActive = _currentPage == index;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      height: 6,
                                      width: isActive ? 22 : 6,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? const Color(0xFF8B65C5)
                                            : const Color(0xFFD1C4E9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
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

  // SLIDE 1: Existing Landing Slide
  Widget _buildSlide1(BuildContext context, BoxConstraints constraints) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/landing/landing_slide_1.png',
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
        ),
        Positioned(
          left: constraints.maxWidth * 0.10,
          right: constraints.maxWidth * 0.10,
          bottom: constraints.maxHeight * 0.02,
          height: constraints.maxHeight * 0.08,
          child: _InteractivePillButton(
            key: const Key('first_landing_get_started'),
            tooltip: "Let's go",
            onTap: _goToNextPage,
          ),
        ),
      ],
    );
  }

  // SLIDE 2: New 3D Feature Cards Landing Slide
  Widget _buildSlide2(BuildContext context, BoxConstraints constraints) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/landing/landing_slide_2.png',
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
        ),
        Positioned(
          left: constraints.maxWidth * 0.10,
          right: constraints.maxWidth * 0.10,
          bottom: constraints.maxHeight * 0.02,
          height: constraints.maxHeight * 0.08,
          child: _InteractivePillButton(
            key: const Key('second_landing_get_started'),
            tooltip: "Get Started",
            onTap: _navigateToLogin,
          ),
        ),
      ],
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
            child: Center(
              child: Opacity(
                opacity: 0.0,
                child: Text(widget.tooltip),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

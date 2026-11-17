import 'package:flutter/material.dart';
import '../widgets/landing_feature_card.dart';

class NewLandingPage extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const NewLandingPage({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });

  static const Color purple = Color(0xFF6336A5);
  static const Color lavender = Color(0xFFE2D5F2);
  static const Color peach = Color(0xFFFFD6BB);
  static const Color coral = Color(0xFFF39580);
  static const Color teal = Color(0xFFB6DEDB);
  static const Color cream = Color(0xFFFFF8ED);
  static const Color pageBg = Color(0xFFE9E1F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1540),
                    child: Container(
                      color: cream,
                      child: Column(
                        children: [
                          // HERO SECTION
                          _buildHero(context, isDesktop),

                          // FEATURE SECTION
                          _buildFeatureSection(context, isDesktop),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: cream,
      padding: EdgeInsets.fromLTRB(
        24,
        isDesktop ? 60 : 24,
        24,
        isDesktop ? 30 : 16,
      ),
      child: Column(
        children: [
          // Open Book Graphic matching reference image
          Icon(
            Icons.menu_book_rounded,
            size: isDesktop ? 116 : 76,
            color: purple,
          ),

          SizedBox(height: isDesktop ? 24 : 14),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "We're Here For You 💜",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4C2A7A),
              ),
            ),
          ),

          SizedBox(height: isDesktop ? 18 : 10),

          // Title
          Text(
            'Why Choose Us?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 40 : 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF39205F),
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Your ultimate reading companion with smart tracking, custom shelves & stats.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 16 : 14,
              color: const Color(0xFF39313F),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 18,
        isDesktop ? 32 : 20,
        isDesktop ? 32 : 18,
        isDesktop ? 40 : 24,
      ),
      decoration: const BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(44),
        ),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, size) {
              final columns =
                  size.maxWidth >= 900 ? 4 : (size.maxWidth >= 550 ? 2 : 1);

              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio:
                    columns == 4 ? 0.95 : (columns == 2 ? 0.85 : 1.3),
                children: const [
                  LandingFeatureCard(
                    title: 'Reading Dashboard',
                    description: 'Keep your daily streaks alive!',
                    icon: Icons.local_fire_department,
                    color: lavender,
                  ),
                  LandingFeatureCard(
                    title: '3D Custom Bookshelves',
                    description: 'Organize your virtual shelves!',
                    icon: Icons.menu_book,
                    color: peach,
                  ),
                  LandingFeatureCard(
                    title: 'Smart Library',
                    description: 'Organize and explore your books!',
                    icon: Icons.library_books,
                    color: coral,
                  ),
                  LandingFeatureCard(
                    title: 'Reading Stats & Goals',
                    description: 'Track your pages and set goals!',
                    icon: Icons.bar_chart,
                    color: teal,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // GET STARTED BUTTON
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                key: const Key('second_landing_get_started'),
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // LOGIN OPTION
          TextButton(
            key: const Key('second_landing_login'),
            onPressed: onLogin,
            child: const Text(
              'Already have an account? Login',
              style: TextStyle(
                color: purple,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/discover/presentation/discover_screen.dart';
import 'package:reading_sanctuary_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/discover_banner.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/hero_reading_banner.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/metric_cards_row.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reading_overview_chart.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/recently_read_card.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/todays_picks_card.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/top_genres_chart.dart';
import 'package:reading_sanctuary_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:reading_sanctuary_app/features/reading/reading_screen.dart';
import 'package:reading_sanctuary_app/features/settings/presentation/screens/settings_screen.dart';

void main() {
  Widget testWrapper(Widget child, {Size size = const Size(400, 850)}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: child,
        ),
      ),
    );
  }

  group('Clay Theme Screens Tests', () {
    testWidgets('FavoritesScreen renders tabs, book cards, folders, and bottom nav', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testWrapper(const FavoritesScreen()));
      await tester.pumpAndSettle();

      // Verify header & tabs
      expect(find.text('My Favorites'), findsOneWidget);
      expect(find.text('Books'), findsOneWidget);
      expect(find.text('Authors'), findsOneWidget);
      expect(find.text('Folders'), findsOneWidget);

      // Verify book cards & heart buttons
      expect(find.byType(ClayHeartButton), findsWidgets);
      expect(find.text('Start Reading'), findsWidgets);

      // Switch to Folders tab
      await tester.tap(find.text('Folders'));
      await tester.pumpAndSettle();

      expect(find.text('Favorite Folders'), findsOneWidget);
      expect(find.textContaining('Currently'), findsOneWidget);
      expect(find.textContaining('Must'), findsOneWidget);
      expect(find.textContaining('Buy'), findsOneWidget);
      expect(find.text('Audiobooks'), findsOneWidget);
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Want to organize?'), findsOneWidget);
      expect(find.text('Create Folder +'), findsOneWidget);

      // Bottom nav is rendered
      expect(find.byType(ClayBottomNav), findsOneWidget);
    });

    testWidgets('DiscoverScreen renders Trending Now, Popular Genres, Recommended, and Spotlight', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testWrapper(const DiscoverScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Search books, authors, genres...'), findsOneWidget);
      expect(find.text('Trending Now'), findsOneWidget);
      expect(find.text('Popular Genres'), findsOneWidget);
      expect(find.text('Fantasy'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
      expect(find.text('Mystery'), findsOneWidget);
      expect(find.text('Romance'), findsOneWidget);
      expect(find.text('Recommended For You'), findsOneWidget);
      expect(find.text('Explore All'), findsOneWidget);
      expect(find.text('Author Spotlight'), findsOneWidget);
      expect(find.byType(ClayBottomNav), findsOneWidget);
    });

    testWidgets('ReadingScreen renders Hero Book, CTAs, Reading List, and Recently Finished', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testWrapper(const ReadingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Currently Reading'), findsOneWidget);
      expect(find.textContaining('Completed'), findsOneWidget);
      expect(find.text('Continue Reading  →'), findsOneWidget);
      expect(find.text('View Notes'), findsOneWidget);
      expect(find.text('Log Reading'), findsOneWidget);
      expect(find.text('Reading List'), findsOneWidget);
      expect(find.text('Recently Finished'), findsOneWidget);
      expect(find.byType(ClayBottomNav), findsOneWidget);
    });

    testWidgets('ProfileScreen renders Avatar, Stat cards, Achievements, and Mia\'s Library', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testWrapper(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Reader'), findsOneWidget);
      expect(find.text('Book Lover'), findsOneWidget);
      expect(find.textContaining('Books'), findsWidgets);
      expect(find.textContaining('Streak'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.text('Speed Reader'), findsOneWidget);
      expect(find.text('Night Owl'), findsOneWidget);

      // Verify all home dashboard widgets are in profile page
      expect(find.byType(HeroReadingBanner), findsOneWidget);
      expect(find.byType(MetricCardsRow), findsOneWidget);
      expect(find.byType(ReadingOverviewChart), findsOneWidget);
      expect(find.byType(TopGenresChart), findsOneWidget);
      expect(find.byType(RecentlyReadCard), findsOneWidget);
      expect(find.byType(TodaysPicksCard), findsOneWidget);
      expect(find.byType(DiscoverBanner), findsOneWidget);

      // Verify ProfileScreen is scrollable and has Scrollbar
      expect(find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollbar)), findsOneWidget);
      final profileScrollView = find.descendant(of: find.byType(ProfileScreen), matching: find.byType(SingleChildScrollView));
      expect(profileScrollView, findsOneWidget);

      // Scroll down Overview tab
      await tester.drag(profileScrollView, const Offset(0, -400));
      await tester.pumpAndSettle();

      // Switch to Shelves & Settings
      await tester.tap(find.text('Shelves & Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Favorites Shelf'), findsOneWidget);
      expect(find.text('To Read List'), findsOneWidget);
      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Reading Goals'), findsOneWidget);

      // Shelves & Settings tab is also scrollable
      await tester.drag(profileScrollView, const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('ProfileScreen toggles between girl and boy animated avatars', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testWrapper(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Initially Girl avatar with dynamic reader name
      expect(find.text('Girl'), findsOneWidget);
      expect(find.text('Boy'), findsOneWidget);
      expect(find.text('Reader'), findsOneWidget);

      // Tap 'Boy'
      await tester.tap(find.text('Boy'));
      await tester.pumpAndSettle();

      // Verified Boy character active while preserving real user name
      expect(find.text('Reader'), findsOneWidget);
      final boyImages = tester.widgetList<Image>(find.byType(Image)).where(
        (img) => img.image is AssetImage && (img.image as AssetImage).assetName.contains('avatar_boy'),
      );
      expect(boyImages, isNotEmpty);
      final boyBanner = tester.widgetList<Image>(find.byType(Image)).where(
        (img) => img.image is AssetImage && (img.image as AssetImage).assetName.contains('dash_banner_boy'),
      );
      expect(boyBanner, isNotEmpty);

      // Tap 'Girl' again
      await tester.tap(find.text('Girl'));
      await tester.pumpAndSettle();

      expect(find.text('Reader'), findsOneWidget);
      final girlImages = tester.widgetList<Image>(find.byType(Image)).where(
        (img) => img.image is AssetImage && (img.image as AssetImage).assetName.contains('avatar_mia'),
      );
      expect(girlImages, isNotEmpty);
      final girlBanner = tester.widgetList<Image>(find.byType(Image)).where(
        (img) => img.image is AssetImage && (img.image as AssetImage).assetName.endsWith('dash_banner.png'),
      );
      expect(girlBanner, isNotEmpty);
    });

    testWidgets('SettingsScreen renders Account & Privacy, Preferences with Switch, and Help', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(testWrapper(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account & Privacy'), findsOneWidget);
      expect(find.text('Profile Settings'), findsOneWidget);
      expect(find.textContaining('Linked'), findsOneWidget);
      expect(find.textContaining('Privacy &'), findsOneWidget);

      // Switch to Preferences & Support
      await tester.tap(find.text('Preferences & Support'));
      await tester.pumpAndSettle();

      expect(find.text('Reading Reminders'), findsOneWidget);
      expect(find.byType(ClaySwitch), findsOneWidget);
      expect(find.textContaining('Night'), findsOneWidget);
      expect(find.textContaining('Sync'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });
}

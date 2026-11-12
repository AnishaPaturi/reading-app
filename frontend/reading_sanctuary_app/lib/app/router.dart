import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../features/analytics/presentation/screens/reading_goals_screen.dart';
import '../features/analytics/presentation/screens/yearly_wrap_up_screen.dart';
import '../features/audiobook/presentation/screens/audiobook_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/signup_screen.dart';
import '../features/bookshelf/presentation/bookshelves_screen.dart';
import '../features/book_details/book_details_screen.dart';
import '../features/cloud_storage/presentation/screens/storage_management_screen.dart';
import '../core/sync/presentation/screens/sync_settings_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/favorites/presentation/screens/favorites_screen.dart';
import '../features/home/home_screen.dart';
import '../features/journal/presentation/journal_screen.dart';
import '../features/reading/reading_screen.dart';
import '../features/library/library_screen.dart';
import '../features/library/screens/add_book_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/help/presentation/screens/help_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/tracker/presentation/screens/reading_tracker_screen.dart';
import '../shared/models/book.dart';
import '../features/landing/presentation/screens/landing_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/reader/presentation/routes/reader_routes.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';

Page<void> _page(GoRouterState s, Widget w) => NoTransitionPage(key: s.pageKey, child: w);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/landing', builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
      ...readerRoutes,
      GoRoute(
        path: '/listen/:bookId/:fileId',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final fileId = state.pathParameters['fileId']!;
          final mode = state.uri.queryParameters['mode'];
          final isTts = mode == 'tts';

          return AudiobookScreen(
            bookId: bookId,
            fileId: fileId,
            bookTitle: state.uri.queryParameters['title'],
            author: state.uri.queryParameters['author'],
            format: state.uri.queryParameters['format'],
            isTtsMode: isTts,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (c, s) => _page(s, const HomeScreen())),
          GoRoute(path: '/dashboard', pageBuilder: (c, s) => _page(s, const HomeScreen())),
          GoRoute(path: '/library', pageBuilder: (c, s) => _page(s, const LibraryScreen())),
          GoRoute(path: '/library/add', pageBuilder: (c, s) => _page(s, const AddBookScreen())),
          GoRoute(path: '/library/add-manual', pageBuilder: (c, s) => _page(s, const AddBookScreen())),
          GoRoute(path: '/favorites', pageBuilder: (c, s) => _page(s, const FavoritesScreen())),
          GoRoute(path: '/discover', pageBuilder: (c, s) => _page(s, const DiscoverScreen())),
          GoRoute(path: '/reading', pageBuilder: (c, s) => _page(s, const ReadingScreen())),
          GoRoute(path: '/profile', pageBuilder: (c, s) => _page(s, const ProfileScreen())),
          GoRoute(path: '/settings', pageBuilder: (c, s) => _page(s, const SettingsScreen())),
          GoRoute(path: '/journal', pageBuilder: (c, s) => _page(s, const JournalScreen())),
          GoRoute(path: '/journal/new', pageBuilder: (c, s) => _page(s, const JournalScreen(openNew: true))),
          GoRoute(
            path: '/book/:id',
            pageBuilder: (c, s) =>
                _page(s, BookDetailsScreen(bookId: s.pathParameters['id']!)),
          ),
          GoRoute(
            path: '/statistics',
            pageBuilder: (c, s) => _page(s, const AnalyticsDashboardScreen()),
            routes: [
              GoRoute(
                path: 'goals',
                pageBuilder: (c, s) => _page(s, const ReadingGoalsScreen()),
              ),
              GoRoute(
                path: 'wrap-up',
                pageBuilder: (c, s) {
                  final yearStr = s.uri.queryParameters['year'];
                  final year = yearStr != null ? int.tryParse(yearStr) : null;
                  return _page(s, YearlyWrapUpScreen(year: year));
                },
              ),
            ],
          ),
          GoRoute(
            path: '/analytics',
            pageBuilder: (c, s) => _page(s, const AnalyticsDashboardScreen()),
          ),
          GoRoute(
            path: '/sync/settings',
            pageBuilder: (c, s) => _page(s, const SyncSettingsScreen()),
          ),
          GoRoute(
            path: '/storage/manage',
            pageBuilder: (c, s) => _page(s, const StorageManagementScreen()),
          ),
          GoRoute(path: '/notifications', pageBuilder: (c, s) => _page(s, const NotificationsScreen())),
          GoRoute(path: '/help', pageBuilder: (c, s) => _page(s, const HelpScreen())),
          GoRoute(path: '/search', pageBuilder: (c, s) => _page(s, const SearchScreen())),
          GoRoute(
            path: '/tracker/reading',
            pageBuilder: (c, s) => _page(s, const ReadingTrackerScreen(
              title: 'Currently Reading',
              statusFilter: ReadingStatus.currentlyReading,
            )),
          ),
          GoRoute(
            path: '/tracker/tbr',
            pageBuilder: (c, s) => _page(s, const ReadingTrackerScreen(
              title: 'Want to Read',
              statusFilter: ReadingStatus.wantToRead,
            )),
          ),
          GoRoute(
            path: '/tracker/completed',
            pageBuilder: (c, s) => _page(s, const ReadingTrackerScreen(
              title: 'Completed Books',
              statusFilter: ReadingStatus.completed,
            )),
          ),
          GoRoute(
            path: '/tracker/dnf',
            pageBuilder: (c, s) => _page(s, const ReadingTrackerScreen(
              title: 'Did Not Finish',
              statusFilter: ReadingStatus.dnf,
            )),
          ),
          GoRoute(
            path: '/bookshelves',
            pageBuilder: (c, s) => _page(s, const BookshelvesScreen()),
          ),
          GoRoute(
            path: '/highlights',
            pageBuilder: (c, s) => _page(s, const ReadingTrackerScreen(title: 'Saved Highlights', isHighlightsMode: true)),
          ),
          GoRoute(
            path: '/quotes',
            pageBuilder: (c, s) => _page(s, const ReadingTrackerScreen(title: 'Favorite Quotes', isQuotesMode: true)),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
});

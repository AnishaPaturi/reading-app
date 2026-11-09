import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../features/analytics/presentation/screens/reading_goals_screen.dart';
import '../features/analytics/presentation/screens/yearly_wrap_up_screen.dart';
import '../features/audiobook/presentation/screens/audiobook_screen.dart';
import '../features/book_details/book_details_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/home/home_screen.dart';
import '../features/reading/reading_screen.dart';
import '../features/library/library_screen.dart';
import '../features/placeholder/placeholder_screen.dart';
import '../features/reader/presentation/routes/reader_routes.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/destinations.dart';
import '../features/splash/splash_screen.dart';

Page<void> _page(GoRouterState s, Widget w) => NoTransitionPage(key: s.pageKey, child: w);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
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
      // Reader / audiobook player will live OUTSIDE the shell (immersive) in Milestone 4/6.
      ShellRoute(
        builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/home', pageBuilder: (c, s) => _page(s, const HomeScreen())),
          GoRoute(path: '/library', pageBuilder: (c, s) => _page(s, const LibraryScreen())),
          GoRoute(path: '/discover', pageBuilder: (c, s) => _page(s, const DiscoverScreen())),
          GoRoute(path: '/reading', pageBuilder: (c, s) => _page(s, const ReadingScreen())),
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
          for (final e in placeholders.entries)
            GoRoute(
              path: e.key,
              pageBuilder: (c, s) => _page(s, PlaceholderScreen(info: e.value)),
            ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
});

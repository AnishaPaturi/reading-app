import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../screens/reader_screen.dart';
import '../widgets/reader_loading.dart';

final readerRoutes = [
  GoRoute(
    path: '/reader/:bookId/:fileId',
    builder: (context, state) {
      final bookId = state.pathParameters['bookId']!;
      final fileId = state.pathParameters['fileId']!;
      final title = state.uri.queryParameters['title'] ?? 'Untitled Book';
      final format = state.uri.queryParameters['format'] ?? 'PDF';

      return Consumer(
        builder: (context, ref, _) {
          final isRestored = ref.watch(authSessionRestoredProvider);
          final isAuthenticated = ref.watch(authNotifierProvider).isAuthenticated;
          if (!isRestored || !isAuthenticated) {
            return Scaffold(body: ReaderLoadingView(title: title));
          }
          return ReaderScreen(
            bookId: bookId,
            fileId: fileId,
            bookTitle: title,
            fileFormat: format,
          );
        },
      );
    },
  ),
];

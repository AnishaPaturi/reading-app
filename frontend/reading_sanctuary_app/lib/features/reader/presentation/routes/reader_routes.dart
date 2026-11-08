import 'package:go_router/go_router.dart';
import '../screens/reader_screen.dart';

final readerRoutes = [
  GoRoute(
    path: '/reader/:bookId/:fileId',
    builder: (context, state) {
      final bookId = state.pathParameters['bookId']!;
      final fileId = state.pathParameters['fileId']!;
      final title = state.uri.queryParameters['title'] ?? 'Reader';
      final format = state.uri.queryParameters['format'] ?? 'PDF';

      return ReaderScreen(
        bookId: bookId,
        fileId: fileId,
        bookTitle: title,
        fileFormat: format,
      );
    },
  ),
];

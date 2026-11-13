import 'package:flutter/material.dart';
import '../bookshelf/presentation/screens/bookshelves_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookshelvesScreen(activeRoute: '/library');
  }
}

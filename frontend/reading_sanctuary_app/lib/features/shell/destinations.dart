import 'package:flutter/material.dart';

class NavDest {
  const NavDest(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}

const primaryDestinations = [
  NavDest('Home', '/home', Icons.home_outlined),
  NavDest('Library', '/library', Icons.local_library_outlined),
  NavDest('Discover', '/discover', Icons.explore_outlined),
  NavDest('Reading', '/reading', Icons.auto_stories_outlined),
  NavDest('Profile', '/profile', Icons.person_outline),
];

/// Desktop sidebar order (per spec).
const sidebarDestinations = [
  NavDest('Home', '/home', Icons.home_outlined),
  NavDest('My Library', '/library', Icons.local_library_outlined),
  NavDest('Discover', '/discover', Icons.explore_outlined),
  NavDest('Bookshelves', '/bookshelves', Icons.view_week_outlined),
  NavDest('Currently Reading', '/tracker/reading', Icons.auto_stories_outlined),
  NavDest('Want to Read', '/tracker/tbr', Icons.bookmark_add_outlined),
  NavDest('Completed', '/tracker/completed', Icons.check_circle_outline),
  NavDest('DNF', '/tracker/dnf', Icons.do_not_disturb_alt_outlined),
  NavDest('Journal', '/journal', Icons.edit_note),
  NavDest('Highlights', '/highlights', Icons.highlight_outlined),
  NavDest('Quotes', '/quotes', Icons.format_quote),
  NavDest('Reading Statistics', '/statistics', Icons.insights_outlined),
  NavDest('Settings', '/settings', Icons.settings_outlined),
];

class PlaceholderInfo {
  const PlaceholderInfo(this.title, this.milestone, this.blurb);
  final String title;
  final int milestone;
  final String blurb;
}

const placeholders = <String, PlaceholderInfo>{
  '/read': PlaceholderInfo('Reader', 4, 'The PDF / EPUB / DOCX reader with highlights and bookmarks.'),
  '/journal': PlaceholderInfo('Journal', 5, 'Your reading journal and book notes.'),
  '/profile': PlaceholderInfo('Profile', 7, 'Profile, preferences and sign out.'),
  '/bookshelves': PlaceholderInfo('Bookshelves', 3, 'Collections and the bookshelf view.'),
  '/tracker/reading': PlaceholderInfo('Currently Reading', 5, 'Reading tracker.'),
  '/tracker/tbr': PlaceholderInfo('Want to Read', 5, 'TBR list with priorities.'),
  '/tracker/completed': PlaceholderInfo('Completed', 5, 'Completed books.'),
  '/tracker/dnf': PlaceholderInfo('DNF', 5, 'Did-not-finish books (notes are always preserved).'),
  '/highlights': PlaceholderInfo('Highlights', 4, 'All highlights across books.'),
  '/quotes': PlaceholderInfo('Quotes', 5, 'Your quotes collection.'),
  '/settings': PlaceholderInfo('Settings', 7, 'Appearance, reading, audio, privacy, sync.'),
  '/help': PlaceholderInfo('Help & About', 7, 'FAQ, support, policies.'),
  '/search': PlaceholderInfo('Search', 3, 'Global search across books, notes, quotes.'),
  '/notifications': PlaceholderInfo('Notifications', 7, 'Goal reminders and sync status.'),
  '/library/add': PlaceholderInfo('Add Book', 3, 'Upload files or add a book manually.'),
  '/library/add-manual': PlaceholderInfo('Add Book Manually', 3, 'Create a record without a file.'),
  '/journal/new': PlaceholderInfo('New Journal Entry', 5, 'Write a journal entry.'),
};

String titleFor(String location) {
  if (location.startsWith('/book/')) return 'Book Details';
  if (location == '/sync/settings') return 'Sync & Devices';
  if (location == '/storage/manage') return 'Storage & Offline';
  final p = placeholders[location];
  if (p != null) return p.title;
  for (final d in [...sidebarDestinations, ...primaryDestinations]) {
    if (d.path == location) return d.label;
  }
  return 'Reading Sanctuary';
}

/// Top-level screens show the menu; everything else shows a back button.
const _detailPaths = {
  '/library/add',
  '/library/add-manual',
  '/journal/new',
  '/search',
  '/notifications',
  '/sync/settings',
  '/storage/manage',
};

bool isDetailRoute(String location) => location.startsWith('/book/') || _detailPaths.contains(location);

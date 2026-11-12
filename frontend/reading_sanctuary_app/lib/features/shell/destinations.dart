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
  NavDest('Favourites', '/favorites', Icons.favorite_outline),
  NavDest('Audiobooks', '/reading', Icons.headphones_outlined),
  NavDest('Profile', '/profile', Icons.person_outline),
  NavDest('Settings', '/settings', Icons.settings_outlined),
];

/// Desktop sidebar order.
const sidebarDestinations = [
  NavDest('Home', '/home', Icons.home_outlined),
  NavDest('Library', '/library', Icons.local_library_outlined),
  NavDest('Favourites', '/favorites', Icons.favorite_outline),
  NavDest('Audiobooks', '/reading', Icons.headphones_outlined),
  NavDest('Profile', '/profile', Icons.person_outline),
  NavDest('Settings', '/settings', Icons.settings_outlined),
];

final Map<String, String> _routeTitles = {
  '/dashboard': 'Home',
  '/home': 'Home',
  '/library': 'Library',
  '/favorites': 'Favorites',
  '/reading': 'Audiobooks',
  '/profile': 'Profile',
  '/settings': 'Settings',
  '/sync/settings': 'Sync & Devices',
  '/storage/manage': 'Storage & Offline',
  '/journal': 'Reading Journal',
  '/journal/new': 'New Journal Entry',
  '/bookshelves': 'My Bookshelves',
  '/tracker/reading': 'Currently Reading',
  '/tracker/tbr': 'Want to Read',
  '/tracker/completed': 'Completed Books',
  '/tracker/dnf': 'Did Not Finish',
  '/highlights': 'Saved Highlights',
  '/quotes': 'Favorite Quotes',
  '/search': 'Search',
  '/notifications': 'Notifications',
  '/help': 'Help & Support',
  '/library/add': 'Add Book',
  '/library/add-manual': 'Add Book',
};

String titleFor(String location) {
  if (location.startsWith('/book/')) return 'Book Details';
  if (_routeTitles.containsKey(location)) return _routeTitles[location]!;
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

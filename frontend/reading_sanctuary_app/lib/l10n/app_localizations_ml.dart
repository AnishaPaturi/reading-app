// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'Reading Sanctuary';

  @override
  String get audiobooks => 'Audiobooks';

  @override
  String get audiobookSubtitle => 'Your personal listening library';

  @override
  String get searchAudiobooksHint => 'Search books and authors...';

  @override
  String get statusAll => 'All';

  @override
  String get statusCurrent => 'Current';

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get continueListening => 'Continue listening';

  @override
  String get allAudiobooks => 'All audiobooks';

  @override
  String get import => 'Import';

  @override
  String get importAudiobook => 'Import audiobook';

  @override
  String get importDescription =>
      'Bring your own DRM-free audiobooks. Supports MP3, M4B, M4A, OGG, OPUS.';

  @override
  String get scanFolder => 'Scan Folder';

  @override
  String get pickFiles => 'Pick Files';

  @override
  String get proposedAudiobooks => 'Proposed Audiobooks';

  @override
  String get nowPlaying => 'NOW PLAYING';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get rewind15s => 'Rewind 15 seconds';

  @override
  String get forward30s => 'Forward 30 seconds';

  @override
  String get previousTrack => 'Previous track';

  @override
  String get nextTrack => 'Next track';

  @override
  String get playbackSpeed => 'Playback Speed';

  @override
  String get skipSilence => 'Skip Silence';

  @override
  String get volumeBoost => 'Volume Boost';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get cancelTimer => 'Cancel';

  @override
  String get extend5min => '+5 min';

  @override
  String get stopEndOfChapter => 'End of chapter';

  @override
  String get stopEndOfTrack => 'End of track';

  @override
  String get shakeToExtend => 'Shake to extend';

  @override
  String get nightAppearance => 'Night appearance';

  @override
  String get fadeoutVolume => 'Fade-out volume smoothly';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get addBookmark => 'Add Bookmark';

  @override
  String get saveBookmark => 'Save Bookmark';

  @override
  String get bookmarkTitle => 'Title';

  @override
  String get bookmarkNote => 'Notes or quote (optional)';

  @override
  String get category => 'Category';

  @override
  String get categoryNote => 'Note';

  @override
  String get categoryQuote => 'Quote';

  @override
  String get categoryRevisit => 'Revisit';

  @override
  String get listeningHistory => 'Listening History';

  @override
  String get totalListeningHours => 'Total active listening hours';

  @override
  String get recentSessions => 'Recent Sessions';

  @override
  String get audiobookSettings => 'Audiobook Settings';

  @override
  String get playbackPreferences => 'Playback Preferences';

  @override
  String get autoRewindOnResume => 'Auto Rewind on Resume';

  @override
  String get playerAccentColor => 'Player Accent Color';

  @override
  String get errorFolderNotFound => 'Selected folder does not exist.';

  @override
  String get errorUnsupportedAudio =>
      'Unsupported audio format or file is corrupt.';

  @override
  String get permissionStorageRequired =>
      'Storage access is required to read audiobook files.';

  @override
  String get noAudiobooksFound => 'No audiobooks found in your library.';
}

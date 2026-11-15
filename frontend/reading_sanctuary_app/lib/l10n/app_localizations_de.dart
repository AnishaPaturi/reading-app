// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Reading Sanctuary';

  @override
  String get audiobooks => 'Hörbücher';

  @override
  String get audiobookSubtitle => 'Ihre persönliche Hörbibliothek';

  @override
  String get searchAudiobooksHint => 'Bücher und Autoren suchen...';

  @override
  String get statusAll => 'Alle';

  @override
  String get statusCurrent => 'Aktuell';

  @override
  String get statusNotStarted => 'Nicht begonnen';

  @override
  String get statusCompleted => 'Abgeschlossen';

  @override
  String get continueListening => 'Weiterhören';

  @override
  String get allAudiobooks => 'Alle Hörbücher';

  @override
  String get import => 'Importieren';

  @override
  String get importAudiobook => 'Hörbuch importieren';

  @override
  String get importDescription =>
      'Bringen Sie Ihre eigenen DRM-freien Hörbücher mit. Unterstützt MP3, M4B, M4A, OGG, OPUS.';

  @override
  String get scanFolder => 'Ordner scannen';

  @override
  String get pickFiles => 'Dateien auswählen';

  @override
  String get proposedAudiobooks => 'Vorgeschlagene Hörbücher';

  @override
  String get nowPlaying => 'JETZT WIEDERGEGEBEN';

  @override
  String get play => 'Wiedergabe';

  @override
  String get pause => 'Pause';

  @override
  String get rewind15s => '15 Sekunden zurück';

  @override
  String get forward30s => '30 Sekunden vor';

  @override
  String get previousTrack => 'Vorheriger Titel';

  @override
  String get nextTrack => 'Nächster Titel';

  @override
  String get playbackSpeed => 'Wiedergabegeschwindigkeit';

  @override
  String get skipSilence => 'Stille überspringen';

  @override
  String get volumeBoost => 'Lautstärke-Boost';

  @override
  String get sleepTimer => 'Schlummerfunktion';

  @override
  String get cancelTimer => 'Abbrechen';

  @override
  String get extend5min => '+5 Min.';

  @override
  String get stopEndOfChapter => 'Ende des Kapitels';

  @override
  String get stopEndOfTrack => 'Ende des Titels';

  @override
  String get shakeToExtend => 'Schütteln zum Verlängern';

  @override
  String get nightAppearance => 'Nachtdarstellung';

  @override
  String get fadeoutVolume => 'Sanftes Ausblenden der Lautstärke';

  @override
  String get bookmarks => 'Lesezeichen';

  @override
  String get addBookmark => 'Lesezeichen hinzufügen';

  @override
  String get saveBookmark => 'Lesezeichen speichern';

  @override
  String get bookmarkTitle => 'Titel';

  @override
  String get bookmarkNote => 'Notizen oder Zitat (optional)';

  @override
  String get category => 'Kategorie';

  @override
  String get categoryNote => 'Notiz';

  @override
  String get categoryQuote => 'Zitat';

  @override
  String get categoryRevisit => 'Erneut anhören';

  @override
  String get listeningHistory => 'Hörverlauf';

  @override
  String get totalListeningHours => 'Aktive Hörstunden insgesamt';

  @override
  String get recentSessions => 'Kürzliche Sitzungen';

  @override
  String get audiobookSettings => 'Hörbuch-Einstellungen';

  @override
  String get playbackPreferences => 'Wiedergabeeinstellungen';

  @override
  String get autoRewindOnResume => 'Automatischer Rücklauf beim Fortsetzen';

  @override
  String get playerAccentColor => 'Player-Akzentfarbe';

  @override
  String get errorFolderNotFound => 'Ausgewählter Ordner existiert nicht.';

  @override
  String get errorUnsupportedAudio =>
      'Nicht unterstütztes Audioformat oder Datei beschädigt.';

  @override
  String get permissionStorageRequired =>
      'Speicherzugriff erforderlich, um Hörbücher zu lesen.';

  @override
  String get noAudiobooksFound =>
      'Keine Hörbücher in Ihrer Bibliothek gefunden.';
}

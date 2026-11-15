// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Reading Sanctuary';

  @override
  String get audiobooks => 'Livres audio';

  @override
  String get audiobookSubtitle => 'Votre bibliothèque d\'écoute personnelle';

  @override
  String get searchAudiobooksHint => 'Rechercher des livres et des auteurs...';

  @override
  String get statusAll => 'Tous';

  @override
  String get statusCurrent => 'En cours';

  @override
  String get statusNotStarted => 'Non commencé';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get continueListening => 'Continuer l\'écoute';

  @override
  String get allAudiobooks => 'Tous les livres audio';

  @override
  String get import => 'Importer';

  @override
  String get importAudiobook => 'Importer un livre audio';

  @override
  String get importDescription =>
      'Apportez vos livres audio sans DRM. Formats supportés: MP3, M4B, M4A, OGG, OPUS.';

  @override
  String get scanFolder => 'Scanner un dossier';

  @override
  String get pickFiles => 'Sélectionner des fichiers';

  @override
  String get proposedAudiobooks => 'Livres audio proposés';

  @override
  String get nowPlaying => 'EN LECTURE';

  @override
  String get play => 'Lecture';

  @override
  String get pause => 'Pause';

  @override
  String get rewind15s => 'Reculer de 15 secondes';

  @override
  String get forward30s => 'Avancer de 30 secondes';

  @override
  String get previousTrack => 'Piste précédente';

  @override
  String get nextTrack => 'Piste suivante';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String get skipSilence => 'Sauter le silence';

  @override
  String get volumeBoost => 'Amplification du volume';

  @override
  String get sleepTimer => 'Minuteur de sommeil';

  @override
  String get cancelTimer => 'Annuler';

  @override
  String get extend5min => '+5 min';

  @override
  String get stopEndOfChapter => 'Fin du chapitre';

  @override
  String get stopEndOfTrack => 'Fin de la piste';

  @override
  String get shakeToExtend => 'Secouer pour prolonger';

  @override
  String get nightAppearance => 'Apparence de nuit';

  @override
  String get fadeoutVolume => 'Diminution douce du volume';

  @override
  String get bookmarks => 'Signets';

  @override
  String get addBookmark => 'Ajouter un signet';

  @override
  String get saveBookmark => 'Enregistrer le signet';

  @override
  String get bookmarkTitle => 'Titre';

  @override
  String get bookmarkNote => 'Notes ou citation (optionnel)';

  @override
  String get category => 'Catégorie';

  @override
  String get categoryNote => 'Note';

  @override
  String get categoryQuote => 'Citation';

  @override
  String get categoryRevisit => 'À revisiter';

  @override
  String get listeningHistory => 'Historique d\'écoute';

  @override
  String get totalListeningHours => 'Total des heures d\'écoute actives';

  @override
  String get recentSessions => 'Sessions récentes';

  @override
  String get audiobookSettings => 'Paramètres des livres audio';

  @override
  String get playbackPreferences => 'Préférences de lecture';

  @override
  String get autoRewindOnResume => 'Rembobinage automatique à la reprise';

  @override
  String get playerAccentColor => 'Couleur d\'accentuation du lecteur';

  @override
  String get errorFolderNotFound => 'Le dossier sélectionné n\'existe pas.';

  @override
  String get errorUnsupportedAudio =>
      'Format audio non supporté ou fichier corrompu.';

  @override
  String get permissionStorageRequired =>
      'L\'accès au stockage est requis pour lire les livres audio.';

  @override
  String get noAudiobooksFound =>
      'Aucun livre audio trouvé dans votre bibliothèque.';
}

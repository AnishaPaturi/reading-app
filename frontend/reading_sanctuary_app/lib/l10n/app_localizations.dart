import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('gu'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('kn'),
    Locale('ko'),
    Locale('ml'),
    Locale('mr'),
    Locale('nl'),
    Locale('pa'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('ta'),
    Locale('te'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Sanctuary'**
  String get appTitle;

  /// No description provided for @audiobooks.
  ///
  /// In en, this message translates to:
  /// **'Audiobooks'**
  String get audiobooks;

  /// No description provided for @audiobookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your personal listening library'**
  String get audiobookSubtitle;

  /// No description provided for @searchAudiobooksHint.
  ///
  /// In en, this message translates to:
  /// **'Search books and authors...'**
  String get searchAudiobooksHint;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @statusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get statusCurrent;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statusNotStarted;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @continueListening.
  ///
  /// In en, this message translates to:
  /// **'Continue listening'**
  String get continueListening;

  /// No description provided for @allAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'All audiobooks'**
  String get allAudiobooks;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @importAudiobook.
  ///
  /// In en, this message translates to:
  /// **'Import audiobook'**
  String get importAudiobook;

  /// No description provided for @importDescription.
  ///
  /// In en, this message translates to:
  /// **'Bring your own DRM-free audiobooks. Supports MP3, M4B, M4A, OGG, OPUS.'**
  String get importDescription;

  /// No description provided for @scanFolder.
  ///
  /// In en, this message translates to:
  /// **'Scan Folder'**
  String get scanFolder;

  /// No description provided for @pickFiles.
  ///
  /// In en, this message translates to:
  /// **'Pick Files'**
  String get pickFiles;

  /// No description provided for @proposedAudiobooks.
  ///
  /// In en, this message translates to:
  /// **'Proposed Audiobooks'**
  String get proposedAudiobooks;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlaying;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @rewind15s.
  ///
  /// In en, this message translates to:
  /// **'Rewind 15 seconds'**
  String get rewind15s;

  /// No description provided for @forward30s.
  ///
  /// In en, this message translates to:
  /// **'Forward 30 seconds'**
  String get forward30s;

  /// No description provided for @previousTrack.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get previousTrack;

  /// No description provided for @nextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get nextTrack;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get playbackSpeed;

  /// No description provided for @skipSilence.
  ///
  /// In en, this message translates to:
  /// **'Skip Silence'**
  String get skipSilence;

  /// No description provided for @volumeBoost.
  ///
  /// In en, this message translates to:
  /// **'Volume Boost'**
  String get volumeBoost;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @cancelTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTimer;

  /// No description provided for @extend5min.
  ///
  /// In en, this message translates to:
  /// **'+5 min'**
  String get extend5min;

  /// No description provided for @stopEndOfChapter.
  ///
  /// In en, this message translates to:
  /// **'End of chapter'**
  String get stopEndOfChapter;

  /// No description provided for @stopEndOfTrack.
  ///
  /// In en, this message translates to:
  /// **'End of track'**
  String get stopEndOfTrack;

  /// No description provided for @shakeToExtend.
  ///
  /// In en, this message translates to:
  /// **'Shake to extend'**
  String get shakeToExtend;

  /// No description provided for @nightAppearance.
  ///
  /// In en, this message translates to:
  /// **'Night appearance'**
  String get nightAppearance;

  /// No description provided for @fadeoutVolume.
  ///
  /// In en, this message translates to:
  /// **'Fade-out volume smoothly'**
  String get fadeoutVolume;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add Bookmark'**
  String get addBookmark;

  /// No description provided for @saveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Save Bookmark'**
  String get saveBookmark;

  /// No description provided for @bookmarkTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bookmarkTitle;

  /// No description provided for @bookmarkNote.
  ///
  /// In en, this message translates to:
  /// **'Notes or quote (optional)'**
  String get bookmarkNote;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get categoryNote;

  /// No description provided for @categoryQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get categoryQuote;

  /// No description provided for @categoryRevisit.
  ///
  /// In en, this message translates to:
  /// **'Revisit'**
  String get categoryRevisit;

  /// No description provided for @listeningHistory.
  ///
  /// In en, this message translates to:
  /// **'Listening History'**
  String get listeningHistory;

  /// No description provided for @totalListeningHours.
  ///
  /// In en, this message translates to:
  /// **'Total active listening hours'**
  String get totalListeningHours;

  /// No description provided for @recentSessions.
  ///
  /// In en, this message translates to:
  /// **'Recent Sessions'**
  String get recentSessions;

  /// No description provided for @audiobookSettings.
  ///
  /// In en, this message translates to:
  /// **'Audiobook Settings'**
  String get audiobookSettings;

  /// No description provided for @playbackPreferences.
  ///
  /// In en, this message translates to:
  /// **'Playback Preferences'**
  String get playbackPreferences;

  /// No description provided for @autoRewindOnResume.
  ///
  /// In en, this message translates to:
  /// **'Auto Rewind on Resume'**
  String get autoRewindOnResume;

  /// No description provided for @playerAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Player Accent Color'**
  String get playerAccentColor;

  /// No description provided for @errorFolderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Selected folder does not exist.'**
  String get errorFolderNotFound;

  /// No description provided for @errorUnsupportedAudio.
  ///
  /// In en, this message translates to:
  /// **'Unsupported audio format or file is corrupt.'**
  String get errorUnsupportedAudio;

  /// No description provided for @permissionStorageRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage access is required to read audiobook files.'**
  String get permissionStorageRequired;

  /// No description provided for @noAudiobooksFound.
  ///
  /// In en, this message translates to:
  /// **'No audiobooks found in your library.'**
  String get noAudiobooksFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'bn',
        'de',
        'en',
        'es',
        'fr',
        'gu',
        'hi',
        'id',
        'it',
        'ja',
        'kn',
        'ko',
        'ml',
        'mr',
        'nl',
        'pa',
        'pl',
        'pt',
        'ru',
        'ta',
        'te',
        'tr',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'kn':
      return AppLocalizationsKn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'nl':
      return AppLocalizationsNl();
    case 'pa':
      return AppLocalizationsPa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

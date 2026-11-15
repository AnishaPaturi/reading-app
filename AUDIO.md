Complete Audiobook Module Implementation — All 11 Features
We’ll treat this as a complete audiobook system inside Reading Sanctuary, not as a separate mini-app. The goal is to make it feel like a polished audiobook application while keeping your existing library, reader, authentication, database, navigation, and Dark Academia / Warm Parchment themes intact.

One important distinction: all 11 feature groups need to be implemented, but they should not all be crammed into one screen or one service. We’ll build them as connected modules with shared audiobook data, a single playback engine, and persistent listening progress.

I’ll lay out the complete implementation in one guide, including the architecture, folder structure, database design, dependencies, implementation sequence, platform-specific work, and testing. The exact existing file names and classes in your repository must be checked before replacing anything; otherwise, we risk breaking features that already work.
1. What the finished audiobook system will contain










1. Personal audiobook library

Folder scanning, automatic book grouping, covers, metadata, Current / Not started / Completed sections, grid and list views, title and author search.













2. Importing and file management

Device files and folders, supported audio formats, folder scanning, metadata extraction, local and online covers, multi-track books.













3. Playback system

Play/pause, speed, silence skipping, volume boost, auto rewind, chapter navigation, chapter stop, quick rewind and resume.













4. Sleep timer

Timed stop, fade-out, chapter-end stop, shake-to-extend and a dedicated night appearance.













5. Bookmarks and listening notes

Named timestamps, notes, favorites, quotes and places to revisit.













6. Listening history

Listening sessions, pauses, playback jumps, previous positions and useful resume suggestions.













7. Book cover management

Embedded artwork, local images, online search, custom covers and cover-derived player colours.













8. Library search and discovery

Search your own books, filter by status and switch between grid and list.













9. Home screen widgets

Android Now Playing and audiobook shelf widgets.













10. Notifications and Android Auto

Persistent media notification, lock-screen controls, compatible-device controls and Android Auto integration.













11. Appearance and customization

Light and dark themes, custom colours, dynamic cover colours, sleep appearance and 25-language localization.



2. First, what your current repository already has
I checked the current GitHub versions of your frontend pubspec.yaml, Android manifest and main.dart.

Good news: your project already has the core audio packages:
Package	Already present?	Purpose
just_audio	Yes	Audio playback engine
audio_service	Yes	Background playback and media controls
audio_session	Yes	Audio focus and interruptions
file_picker	Yes	Selecting files and folders
path_provider	Yes	App-managed local storage
permission_handler	Yes	Runtime permissions
flutter_riverpod	Yes	State management
shared_preferences	Yes	Small local preferences

Your Android manifest also already declares the audio_service service and media button receiver. That is a useful starting point for background playback.

Do not add another audio engine or duplicate these dependencies. We should extend the existing setup. Your current main.dart also uses a ProviderScope, so the audiobook state can fit into your existing Riverpod architecture.

The rest of this guide assumes the existing packages stay in place. Some additional packages will be needed for metadata, local database access, dynamic artwork colours, shake detection and widgets. Add them only after checking whether your project already has an equivalent implementation.
3. Target architecture
The most important architectural decision is this:

One audiobook = one book record + one or more audio-file records + one playback-progress record.

For example, suppose the user imports:
My Audiobooks/
└── The Silent Patient/
    ├── cover.jpg
    ├── 01 - Chapter One.mp3
    ├── 02 - Chapter Two.mp3
    └── 03 - Chapter Three.mp3


The app must create:
- One audiobook: The Silent Patient
- Three audio tracks, ordered by filename.
- One cover image.
- One playback progress record.
- One chapter list.
It must not create three separate books.
Recommended folder structure
Keep the audiobook module independent from your existing ebook reader and general library.
lib/
├── features/
│   └── audiobooks/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── audiobook_local_datasource.dart
│       │   │   ├── audiobook_remote_datasource.dart
│       │   │   └── audio_file_datasource.dart
│       │   ├── models/
│       │   │   ├── audiobook.dart
│       │   │   ├── audio_track.dart
│       │   │   ├── audio_chapter.dart
│       │   │   ├── playback_progress.dart
│       │   │   ├── audiobook_bookmark.dart
│       │   │   └── listening_event.dart
│       │   └── repositories/
│       │       └── audiobook_repository_impl.dart
│       │
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       │       ├── import_audiobooks.dart
│       │       ├── scan_audiobook_folder.dart
│       │       ├── group_audio_tracks.dart
│       │       ├── update_progress.dart
│       │       └── get_listening_history.dart
│       │
│       ├── services/
│       │   ├── audiobook_import_service.dart
│       │   ├── audiobook_scanner_service.dart
│       │   ├── audiobook_metadata_service.dart
│       │   ├── audiobook_artwork_service.dart
│       │   ├── audiobook_player_handler.dart
│       │   ├── audiobook_playback_service.dart
│       │   ├── audiobook_chapter_service.dart
│       │   ├── audiobook_sleep_timer_service.dart
│       │   ├── audiobook_bookmark_service.dart
│       │   ├── audiobook_history_service.dart
│       │   ├── audiobook_widget_service.dart
│       │   └── audiobook_media_service.dart
│       │
│       ├── providers/
│       │   ├── audiobook_providers.dart
│       │   ├── audiobook_library_provider.dart
│       │   ├── audiobook_player_provider.dart
│       │   ├── audiobook_import_provider.dart
│       │   ├── audiobook_bookmark_provider.dart
│       │   ├── audiobook_history_provider.dart
│       │   └── audiobook_settings_provider.dart
│       │
│       ├── presentation/
│       │   ├── pages/
│       │   │   ├── audiobook_library_page.dart
│       │   │   ├── audiobook_player_page.dart
│       │   │   ├── audiobook_details_page.dart
│       │   │   ├── audiobook_import_page.dart
│       │   │   ├── audiobook_bookmarks_page.dart
│       │   │   ├── audiobook_history_page.dart
│       │   │   └── audiobook_settings_page.dart
│       │   └── widgets/
│       │       ├── audiobook_cover.dart
│       │       ├── audiobook_grid.dart
│       │       ├── audiobook_list_tile.dart
│       │       ├── audiobook_progress_bar.dart
│       │       ├── audiobook_player_controls.dart
│       │       ├── chapter_list.dart
│       │       ├── sleep_timer_sheet.dart
│       │       ├── bookmark_dialog.dart
│       │       └── mini_player.dart
│       │
│       └── utils/
│           ├── audio_format_utils.dart
│           ├── audiobook_grouping_utils.dart
│           └── audiobook_duration_utils.dart
│
└── app/
    ├── app.dart
    └── ...


This is the target structure. If your existing project already has audiobook files or services, extend or refactor those rather than creating duplicate classes.
How the modules communicate
Audiobook screens

Library · Player · Bookmarks · History · Settings


Riverpod providers

Shared state and UI updates


Audiobook services

Import · Metadata · Playback · Timer · History · Artwork


Local storage

Database, audio files, covers, progress


Spring Boot API

Account sync, metadata, bookmarks and history




Android media integration

Notification · Lock screen · Android Auto · Home widgets


The audio itself should remain on the user's device by default. Do not upload their entire audiobook collection to your backend. Sync metadata, progress, bookmarks and preferences instead.
4. Dependencies to add
You already have the core playback and file-picker packages. The following are candidates for the additional capabilities.
Package	Why it is needed
rxdart	Combine playback streams and player state
metadata_god	Read audio metadata and embedded artwork
sensors_plus	Detect phone shake
home_widget	Communicate with Android home-screen widgets
palette_generator	Extract colours from book covers
drift + sqlite3_flutter_libs	Structured local database, if you don't already have one
flutter_localizations	Flutter's localization support
flutter_launcher_icons	Only if you need widget/app icon asset generation

For 25 languages, you will also need translation files, not just a localization package.

From the frontend directory:
cd frontend/reading_sanctuary_app

flutter pub add rxdart
flutter pub add metadata_god
flutter pub add sensors_plus
flutter pub add home_widget
flutter pub add palette_generator


For a Drift database, first check whether your project already uses SQLite, Hive, Isar, ObjectBox or another structured local database. If it does, use that existing database instead of introducing a second one.

If no structured local database exists, add:
flutter pub add drift
flutter pub add sqlite3_flutter_libs
flutter pub add path
flutter pub add dev:drift_dev
flutter pub add dev:build_runner


Do not run flutter pub upgrade as part of this change. We want to avoid unrelated dependency upgrades.

5. Shared data models and database
This is the foundation for features 1–8. If the data model is wrong, the rest of the features will become difficult to maintain.
5.1 Audiobook model
Create lib/features/audiobooks/data/models/audiobook.dart.
enum AudiobookStatus {
  notStarted,
  current,
  completed,
}

class Audiobook {
  final String id;
  final String title;
  final String author;
  final String? narrator;
  final String? description;
  final String? coverPath;
  final String? folderPath;
  final int totalDurationMs;
  final int totalTracks;
  final AudiobookStatus status;
  final DateTime dateAdded;

  const Audiobook({
    required this.id,
    required this.title,
    required this.author,
    this.narrator,
    this.description,
    this.coverPath,
    this.folderPath,
    required this.totalDurationMs,
    required this.totalTracks,
    required this.status,
    required this.dateAdded,
  });
}


5.2 Audio track model
Create audio_track.dart.
class AudioTrack {
  final String id;
  final String audiobookId;
  final String filePath;
  final String fileName;
  final int trackOrder;
  final int durationMs;
  final String format;
  final String? chapterTitle;

  const AudioTrack({
    required this.id,
    required this.audiobookId,
    required this.filePath,
    required this.fileName,
    required this.trackOrder,
    required this.durationMs,
    required this.format,
    this.chapterTitle,
  });
}


5.3 Playback progress model
Create playback_progress.dart.
class PlaybackProgress {
  final String audiobookId;
  final String? currentTrackId;
  final int trackIndex;
  final int positionMs;
  final int totalDurationMs;
  final double playbackSpeed;
  final DateTime lastListenedAt;
  final bool completed;

  const PlaybackProgress({
    required this.audiobookId,
    this.currentTrackId,
    required this.trackIndex,
    required this.positionMs,
    required this.totalDurationMs,
    required this.playbackSpeed,
    required this.lastListenedAt,
    required this.completed,
  });
}


5.4 Database schema
Use the following logical tables. Adapt them to your existing database implementation and naming conventions.
Table	Purpose
audiobooks	One row per audiobook
audio_tracks	Individual audio files belonging to a book
audio_chapters	Chapter markers and chapter boundaries
playback_progress	Current track and saved position
audiobook_bookmarks	Named timestamps, notes and categories
listening_sessions	Listening session start/end and actual duration
listening_events	Meaningful play, pause and seek events
audiobook_settings	Per-user and global playback preferences
audiobook_folders	Selected folders and scan configuration

A simplified SQL structure:
CREATE TABLE audiobooks (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(300),
    narrator VARCHAR(300),
    description TEXT,
    cover_path TEXT,
    folder_path TEXT,
    total_duration_ms BIGINT DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'notStarted',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audio_tracks (
    id UUID PRIMARY KEY,
    audiobook_id UUID NOT NULL REFERENCES audiobooks(id)
        ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    file_name VARCHAR(500) NOT NULL,
    track_order INTEGER NOT NULL,
    duration_ms BIGINT DEFAULT 0,
    format VARCHAR(20) NOT NULL,
    UNIQUE(audiobook_id, track_order)
);

CREATE TABLE playback_progress (
    audiobook_id UUID PRIMARY KEY REFERENCES audiobooks(id)
        ON DELETE CASCADE,
    current_track_id UUID,
    track_index INTEGER DEFAULT 0,
    position_ms BIGINT DEFAULT 0,
    playback_speed DOUBLE PRECISION DEFAULT 1.0,
    completed BOOLEAN DEFAULT FALSE,
    last_listened_at TIMESTAMP
);

CREATE TABLE audiobook_bookmarks (
    id UUID PRIMARY KEY,
    audiobook_id UUID NOT NULL REFERENCES audiobooks(id)
        ON DELETE CASCADE,
    track_index INTEGER NOT NULL,
    position_ms BIGINT NOT NULL,
    title VARCHAR(250),
    note TEXT,
    category VARCHAR(30) NOT NULL DEFAULT 'note',
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE listening_sessions (
    id UUID PRIMARY KEY,
    audiobook_id UUID NOT NULL REFERENCES audiobooks(id)
        ON DELETE CASCADE,
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    actual_listening_ms BIGINT DEFAULT 0
);

CREATE TABLE listening_events (
    id UUID PRIMARY KEY,
    session_id UUID REFERENCES listening_sessions(id)
        ON DELETE CASCADE,
    event_type VARCHAR(30) NOT NULL,
    track_index INTEGER,
    position_ms BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


This is a starting schema, not a migration to blindly paste into your existing database. In particular:
- Your backend may already have a users table and a different UUID strategy.
- Local database IDs and server database IDs need a consistent mapping.
- Track paths should be local-only values. Do not expose a user's local filesystem paths through the public API.
- Add indexes for user_id, audiobook_id, last_listened_at and event timestamps.
- Add offline sync fields such as updated_at, deleted_at, sync_status and a server version where appropriate.
- Use a new Flyway migration such as V2__create_audiobook_module.sql only if V2 is actually the next unused version in your backend.
Critical: the local database is the playback source of truth while the user is listening. The backend should synchronize changes after they are safely stored locally.

6. Feature 1 and 2 — Audiobook library, importing and folder scanning
These two features should be implemented together because the library depends on imported audiobook records.
Step 6.1 — Add the supported formats
Create utils/audio_format_utils.dart.
class AudioFormatUtils {
  static const Set<String> supportedExtensions = {
    'm4b',
    'mp3',
    'm4a',
    'ogg',
    'oga',
    'opus',
  };

  static bool isSupported(String path) {
    final extension = path.split('.').last.toLowerCase();
    return supportedExtensions.contains(extension);
  }
}


This is an extension filter, not a guarantee that every file is playable. Validate the actual codec and container when opening a file. For example, a file with an .m4a extension can still contain an unsupported codec.
Step 6.2 — Allow users to import files
Use the existing file_picker package.

Create services/audiobook_import_service.dart.
import 'package:file_picker/file_picker.dart';

import '../utils/audio_format_utils.dart';

class AudiobookImportService {
  Future<List<PlatformFile>> pickAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions:
          AudioFormatUtils.supportedExtensions.toList(),
      allowMultiple: true,
      withData: false,
    );

    if (result == null) return [];

    return result.files
        .where((file) =>
            file.path != null &&
            AudioFormatUtils.isSupported(file.path!))
        .toList();
  }

  Future<String?> pickAudiobookFolder() async {
    return FilePicker.platform.getDirectoryPath();
  }
}


For selected individual files, the app should ask whether the user wants to:
1. Create a new audiobook.
2. Add the files to an existing audiobook.
3. Let the app attempt to group them automatically.
This avoids incorrectly treating a collection of unrelated MP3 files as one book.
Step 6.3 — Scan selected folders
Create services/audiobook_scanner_service.dart.

The scanner must:
1. Accept a folder path.
2. Enumerate files recursively.
3. Ignore unsupported extensions.
4. Group files by likely book folder.
5. Sort files naturally.
6. Read metadata.
7. Detect possible duplicate files.
8. Show the proposed book groups before importing.
The core scan can look like this:
import 'dart:io';

import '../utils/audio_format_utils.dart';

class AudiobookScannerService {
  Future<List<File>> scanFolder(String folderPath) async {
    final directory = Directory(folderPath);

    if (!await directory.exists()) {
      throw Exception('Selected folder does not exist.');
    }

    final results = <File>[];

    await for (final entity in directory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;

      if (AudioFormatUtils.isSupported(entity.path)) {
        results.add(entity);
      }
    }

    results.sort(
      (a, b) => a.path.toLowerCase().compareTo(
            b.path.toLowerCase(),
          ),
    );

    return results;
  }
}


For production, replace the simple alphabetical sorting with natural sorting. Otherwise, Chapter 10 can appear before Chapter 2.
Step 6.4 — Implement intelligent book grouping
Do not group everything by filename alone.

Use these grouping rules, in order:
Priority	Rule	Example
1	Files in the same explicit book folder	Books/Book A/01.mp3
2	Matching embedded album metadata	Album = Book A
3	Matching book title in filenames	Book A - Chapter 1.mp3
4	User-confirmed grouping	User selects files and assigns them to one book

If the scanner is uncertain, ask the user. Incorrectly grouping books is worse than asking for confirmation.

Store the original folder structure and each file's relative path so you can rescan later without losing track associations.
Step 6.5 — Extract metadata
For every file, attempt to read:
- Title
- Artist / author
- Album
- Narrator, if present
- Track number
- Duration
- Embedded artwork
Use a metadata reader compatible with your supported formats. Verify its actual format coverage before committing to it.

When metadata is absent, fall back to:
1. Folder name for book title.
2. Filename for chapter title.
3. User-entered author.
4. Unknown author if nothing is available.
Never block import simply because metadata is missing.
Step 6.6 — Create an import preview
Before saving the imported books, display:
- Detected audiobook title.
- Detected author.
- Selected cover.
- Number of tracks.
- Total duration.
- Track ordering.
- Any files that could not be read.
The user should be able to edit the title, author, cover and track grouping before pressing Import.
Step 6.7 — Implement library status
Use the saved playback position to calculate the status:
AudiobookStatus calculateStatus({
  required int positionMs,
  required int totalDurationMs,
  required bool explicitlyCompleted,
}) {
  if (explicitlyCompleted ||
      (totalDurationMs > 0 &&
       positionMs >= totalDurationMs)) {
    return AudiobookStatus.completed;
  }

  if (positionMs > 0) {
    return AudiobookStatus.current;
  }

  return AudiobookStatus.notStarted;
}


Do not automatically mark a book completed merely because the final track starts. Mark it completed only after playback reaches the end, with a small completion threshold and an option for the user to mark it manually.
Step 6.8 — Build the library page
Create presentation/pages/audiobook_library_page.dart.

The page should have:
- Header: Audiobooks.
- Import button.
- Search field.
- Grid/list toggle.
- Current.
- Not started.
- Completed.
- Book cover cards.
- Progress indicators.
- Sort and filter controls.
Suggested UI structure:
Audiobooks
Your personal listening library

[ Search books and authors... ] [Import +]

[Current] [Not started] [Completed]

Continue listening
[Cover] [Cover] [Cover]

All audiobooks
[Grid] [List]

[Cover]       [Cover]       [Cover]
Book title    Book title    Book title
Author        Author        Author
Progress      Progress      Progress


Use your existing BookCover, SanctuaryCard, typography and theme tokens wherever they fit. Do not create a new theme just for audiobooks.
Step 6.9 — Search and filtering
Create a Riverpod provider that derives the visible collection from:
- Search query.
- Selected status.
- Grid/list mode.
- Sort order.
Search should be case-insensitive and match both title and author.

The search must work against the locally stored audiobook collection, including when the user is offline.

7. Feature 3 — Complete audiobook playback engine
This is the heart of the module.

You already have just_audio, audio_service and audio_session. Keep just_audio as the playback engine and audio_service as the background media integration layer.
Step 7.1 — Build the audio handler
Create services/audiobook_player_handler.dart.

The handler should own the player instance and expose:
- Playback state.
- Current media item.
- Current position.
- Duration.
- Queue.
- Playback speed.
- Previous and next track.
- Seek.
- Play and pause.
Use the BaseAudioHandler interface from audio_service and connect its playback controls to your AudioPlayer.

A simplified handler structure:
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudiobookPlayerHandler extends BaseAudioHandler {
  final AudioPlayer player = AudioPlayer();

  AudiobookPlayerHandler() {
    player.playbackEventStream.listen((event) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            player.playing
                ? MediaControl.pause
                : MediaControl.play,
            MediaControl.skipToNext,
          ],
          playing: player.playing,
          processingState: _mapProcessingState(
            player.processingState,
          ),
          updatePosition: player.position,
          bufferedPosition: player.bufferedPosition,
          speed: player.speed,
          queueIndex: player.currentIndex,
        ),
      );
    });
  }

  AudioProcessingState _mapProcessingState(
    ProcessingState state,
  ) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) =>
      player.seek(position);

  @override
  Future<void> skipToNext() async {
    await player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    await player.seekToPrevious();
  }

  @override
  Future<void> setSpeed(double speed) =>
      player.setSpeed(speed);
}


This is the handler foundation. It still needs queue construction, media-item updates, track transitions, error handling and persistence before it is production-ready.
Step 7.2 — Initialize the audio service
Do not initialize the handler inside a screen's build() method. It must be a singleton or application-level service.

Initialize it once during app startup, after Flutter binding initialization.

Conceptually:
final handler = await AudioService.init(
  builder: () => AudiobookPlayerHandler(),
  config: const AudioServiceConfig(
    androidNotificationChannelId:
        'com.readingsanctuary.audiobooks',
    androidNotificationChannelName:
        'Audiobook Playback',
    androidNotificationOngoing: true,
  ),
);


Your existing main.dart currently calls runApp directly. Change startup carefully to initialize the service before launching the application, while retaining ProviderScope.
Step 7.3 — Build a multi-track queue
When a user opens an audiobook:
1. Load its tracks from the local database.
2. Sort by trackOrder.
3. Build a ConcatenatingAudioSource.
4. Restore the saved track index.
5. Restore the saved position.
6. Update the current media item.
7. Start playback only when the user presses Play.
The player must treat all tracks as a continuous book.
Step 7.4 — Save progress automatically
Save progress:
- Every 5–10 seconds while playing.
- When the user pauses.
- When the user seeks.
- When a track changes.
- When the app moves into the background.
- When playback completes.
Do not write to the database on every position-stream update. That will create unnecessary database writes.
Step 7.5 — Playback speed
Offer:
- 0.75x
- 1.0x
- 1.25x
- 1.5x
- 1.75x
- 2.0x
Persist the user's preferred speed.
Future<void> changeSpeed(
  AudioPlayer player,
  double speed,
) async {
  if (speed < 0.5 || speed > 3.0) {
    throw ArgumentError('Unsupported playback speed.');
  }

  await player.setSpeed(speed);
}


The player screen can offer your preferred range, while the service validates all incoming values.
Step 7.6 — Skip silence
This needs actual silence detection, not just a button that changes the UI.

Use an audio-processing approach that detects sustained low-volume regions and skips them only when:
- The detected section is longer than a configured threshold.
- The audio is not at the beginning or end of a track.
- The skip will not cross a chapter boundary unexpectedly.
If your selected audio library does not support silence skipping natively, implement a processing pipeline or a carefully tested analysis mechanism. Do not pretend the feature works by simply speeding up playback.
Step 7.7 — Volume boost
Normal player volume is usually constrained to a standard range. A volume boost above the normal maximum requires an audio-processing implementation or platform-specific audio effects.

Implement it as an optional enhancement with:
- A default disabled setting.
- A safe maximum gain.
- Clipping protection / limiter where possible.
- A warning that excessive amplification can distort audio.
Do not set the player's volume above its supported range and assume that creates a boost.
Step 7.8 — Auto rewind
When playback resumes after a pause, rewind a small amount to help the user remember where they left off.

Recommended initial behavior:
- Pause shorter than 10 seconds: no rewind.
- Pause 10–60 seconds: rewind 3 seconds.
- Pause longer than 60 seconds: rewind 5 seconds.
Make the amount configurable.
Step 7.9 — Quick jump-back
Provide a rewind button, such as 15 seconds.
Future<void> jumpBack(
  AudioPlayer player, {
  Duration amount = const Duration(seconds: 15),
}) async {
  final target = player.position - amount;

  await player.seek(
    target < Duration.zero ? Duration.zero : target,
  );
}


Also provide a configurable forward jump.
Step 7.10 — Chapter navigation and chapter stop
Store chapter records with:
- Track ID.
- Chapter title.
- Start position.
- End position.
For M4B files with embedded chapter metadata, extract chapters where the decoder supports them. For MP3 and other formats, allow users to create or edit chapter markers manually.

For Chapter Stop:
1. Find the current chapter's end position.
2. Set a stop target.
3. Listen to the position stream.
4. Pause when the target is reached.
5. Clear the stop target.
If a book has no chapter metadata, show a clear message and offer a stop-at-track-end alternative.

8. Feature 4 — Sleep timer
Create services/audiobook_sleep_timer_service.dart.

The timer needs three modes:
1. Stop after a chosen duration.
2. Stop at the end of the current chapter.
3. Stop at the end of the current track.
It also needs a fade-out option.
Step 8.1 — Duration timer
When the user selects 15, 30, 45 or 60 minutes:
- Store the target expiration time.
- Display the remaining time.
- Pause playback when the timer expires.
- Preserve the saved playback position.
Use a deadline-based timer rather than decrementing a counter blindly. This ensures the remaining time is calculated correctly after app lifecycle changes.
Step 8.2 — Fade-out
During the final 15–30 seconds:
- Gradually lower the volume.
- Reach zero at expiration.
- Pause the player.
- Restore the previous volume when the next listening session starts.
If the user has manually changed volume during playback, do not unexpectedly overwrite that choice.
Step 8.3 — Shake to extend
Use sensors_plus to detect a shake gesture.

Implement a threshold, debounce and cooldown so that ordinary phone movement does not accidentally extend playback.

After expiration:
1. Show a small extension window.
2. Detect a valid shake.
3. Add a configurable extension, such as 5 minutes.
4. Resume playback if the user has enabled this behavior.
Also provide an on-screen Extend 5 minutes button. Sensor permissions or device limitations should never make the feature unusable.
Step 8.4 — Night appearance
When a sleep timer is active, enable a dedicated player appearance:
- Very dark background.
- Reduced brightness where the platform permits.
- Minimal controls.
- No unnecessary animations.
- Warm, low-contrast text.
When the timer ends or is cancelled, restore the previous appearance.

9. Feature 5 — Bookmarks and listening notes
Create services/audiobook_bookmark_service.dart.

Every bookmark must store:
Bookmark
├── id
├── audiobookId
├── trackId
├── trackIndex
├── positionMs
├── title
├── note
├── category
├── isFavorite
└── createdAt


Categories:
- Quote
- Note
- Revisit
Step 9.1 — Save a bookmark
When the user taps the bookmark icon:
1. Read the current audiobook.
2. Read the current track.
3. Read the playback position.
4. Open a small dialog.
5. Allow the user to enter a name and note.
6. Save it locally.
7. Queue it for synchronization.
Step 9.2 — Bookmark screen
Show:
- Bookmark title.
- Book cover.
- Chapter.
- Timestamp.
- Note preview.
- Category.
- Favorite indicator.
Step 9.3 — Jump to bookmark
When a bookmark is selected:
1. Load the correct audiobook.
2. Load its track queue.
3. Select the saved track.
4. Seek to the exact saved timestamp.
5. Display the relevant chapter.
Make bookmarks stable even if track filenames change. Use persistent track IDs and a fallback remapping process when a user reimports files.
Step 9.4 — Favorites
A bookmark can be favorited independently of its category.

Allow filtering by:
- All.
- Favorites.
- Quotes.
- Notes.
- Revisit.

10. Feature 6 — Listening history
Create services/audiobook_history_service.dart.

History should record meaningful events, not every second of playback.
Step 10.1 — Listening sessions
Start a session when playback begins.

End it when:
- The user pauses for a long time.
- Playback completes.
- The audiobook changes.
- The app stops the session.
Track actual listening duration, not the difference between the first and last timestamps.

For example:
- Start playback at 7:00.
- Listen for 10 minutes.
- Pause for 20 minutes.
- Listen for another 5 minutes.
Actual listening time is 15 minutes, not 35 minutes.
Step 10.2 — Event recording
Record:
Event	Record?
Play	Yes
Pause	Yes
Seek backward	Yes
Seek forward	Yes
Track changed	Yes
Playback completed	Yes
Position update every second	No

This keeps history efficient.
Step 10.3 — History screen
Show:
- Recently listened audiobooks.
- Last played time.
- Total listening duration.
- Last chapter.
- Last saved position.
- Listening sessions.
Step 10.4 — Resume suggestions
A resume suggestion should appear when:
- A user opens an audiobook with unfinished progress.
- Playback starts from a supported media control.
- A device reconnects and playback is restored.
Do not automatically start audio just because headphones reconnect. Show a resume suggestion or restore the previous playback state according to the user's preference.

11. Feature 7 — Book cover management and dynamic player colours
Create services/audiobook_artwork_service.dart.

Artwork priority should be:
1. User-selected custom artwork.
2. Embedded audio artwork.
3. Local cover.jpg, folder.jpg or equivalent image.
4. Online cover search.
5. Default Reading Sanctuary cover.
Step 11.1 — Embedded artwork
When importing files, attempt to extract embedded cover art.

Store the resulting image in app-managed artwork storage. Do not rely on a temporary memory buffer or a file picker cache path.
Step 11.2 — Local artwork
Search the audiobook folder for common cover filenames:
cover.jpg
cover.png
folder.jpg
folder.png
front.jpg
front.png


Validate image dimensions and file size before using the image.
Step 11.3 — Online cover search
Online search should be optional.

Search using:
- Book title.
- Author.
- ISBN, if available.
Show results to the user and let them select the correct cover. Do not silently download the first matching image.

Use trusted artwork providers or a configured book metadata service. Sanitize URLs and validate the image response before caching.
Step 11.4 — Dynamic colours
Use palette_generator to extract:
- Dominant colour.
- Muted colour.
- Vibrant colour.
- Dark muted colour.
Use those colours as player-screen accents, not as replacements for your entire application theme.

For example:
- The library remains in your existing Dark Academia theme.
- The player takes a subtle accent from the current audiobook cover.
- The buttons and progress bar adapt.
- Text contrast remains readable.
Step 11.5 — Custom artwork
Allow users to:
- Select an image from device storage.
- Crop it.
- Preview it.
- Save it as the audiobook cover.
- Restore embedded or default artwork.

12. Feature 8 — Search and discovery
This should be part of the same library page, not a separate online book discovery engine.

Implement:
- Title search.
- Author search.
- Current filter.
- Not started filter.
- Completed filter.
- Grid view.
- List view.
- Sorting by title, author, recently added and recently played.
Keep all filters in Riverpod state so the UI updates immediately.

A useful search model:
class AudiobookLibraryFilter {
  final String query;
  final AudiobookStatus? status;
  final bool gridView;
  final String sortBy;

  const AudiobookLibraryFilter({
    this.query = '',
    this.status,
    this.gridView = true,
    this.sortBy = 'recentlyAdded',
  });
}


Do not duplicate your audiobook collection for each filter. Derive filtered lists from the original collection.

13. Feature 9 — Android home-screen widgets
This feature requires native Android work. Flutter alone cannot create a full Android launcher widget.

Use home_widget for communication between Flutter and native Android widget code.

Create two widgets:










Now Playing

Cover, title, author and playback controls.











Audiobook Shelf

A shortcut to the audiobook library and recent books.


Step 13.1 — Share widget data
Whenever playback changes, send a compact snapshot to the widget:
now_playing_title
now_playing_author
now_playing_cover
is_playing
position_ms
duration_ms
audiobook_id


Step 13.2 — Create Android widgets
Implement native Kotlin widget classes using Android's supported widget APIs, such as Jetpack Glance or RemoteViews.

The widget should:
- Display the current book.
- Display cover artwork.
- Open the correct audiobook screen.
- Trigger supported play/pause actions.
- Refresh when playback changes.
Step 13.3 — Widget limitations
- Android: implement native home-screen widgets.
- Web: no Android launcher widgets.
- Windows: use a suitable desktop integration only if separately supported.
- iOS: requires a separate WidgetKit implementation.
Do not show an Android widget setting on platforms where it cannot work.

14. Feature 10 — Notifications, lock-screen controls and Android Auto
Your Android manifest already contains the audio_service service and media button receiver. That is a good foundation, but the service configuration and Android Auto integration still need verification.
Step 14.1 — Persistent media notification
The notification should show:
- Audiobook cover.
- Book title.
- Author.
- Play/pause.
- Previous track.
- Next track.
- Playback progress where supported.
The notification should be updated whenever the media item or playback state changes.
Step 14.2 — Lock-screen controls
Use the audio_service media session.

Test:
- Screen locked while playing.
- Screen locked while paused.
- Headphones disconnected.
- Bluetooth controls.
- Phone call interruption.
- Another app requesting audio focus.
Step 14.3 — Audio focus
Configure audio_session for spoken audio.

When a phone call or another app interrupts playback:
- Pause or duck playback according to the interruption.
- Save the current position.
- Resume only when appropriate.
- Respect the user's manual pause.
Step 14.4 — Android Auto
Android Auto is not just the same notification shown on a car screen.

It requires the correct media browsing and session behavior, compatible metadata and Android Auto integration. Validate that your chosen audio_service setup exposes the media browser/session behavior Android Auto needs.

Implement:
- Audiobook library browsing.
- Current audiobook.
- Playback controls.
- Chapter or track navigation.
- Resume position.
- Stable metadata and artwork.
Test using the Android Auto Desktop Head Unit emulator and a compatible Android device.

Do not assume the Android Auto feature is complete simply because the notification works.
Step 14.5 — Resume suggestions for external devices
When a supported external device requests playback:
- Restore the correct audiobook.
- Check its saved position.
- Display the resume state.
- Respect the user's playback preference.
Avoid unexpected automatic playback.

15. Feature 11 — Appearance, themes and 25 languages
This is where we must be especially careful: your existing theme is already part of Reading Sanctuary's identity.

Do not replace app_colors.dart, app_theme.dart, app_shell.dart or your typography system.
Step 15.1 — Theme settings
Support:
- Light theme.
- Dark theme.
- System theme.
- Custom accent colour.
- Cover-derived player colours.
- Night appearance.
Store the user's choice in your existing settings mechanism.
Step 15.2 — Theme integration
Your audiobook screens should consume existing theme values:
final theme = Theme.of(context);
final colors = theme.colorScheme;


Use the app's existing design tokens for:
- Backgrounds.
- Cards.
- Borders.
- Primary text.
- Secondary text.
- Accent colours.
- Buttons.
- Typography.
The cover-derived palette should be applied only to the player accent layer.
Step 15.3 — Night appearance
When the sleep timer is active, apply a separate player theme with:
- Near-black background.
- Dimmed controls.
- Warm ivory text.
- No bright cover glow.
- Minimal visual distraction.
Restore the previous theme after the session ends.
Step 15.4 — Localization for 25 languages
Use Flutter's localization infrastructure.

Create:
lib/
└── l10n/
    ├── app_en.arb
    ├── app_hi.arb
    ├── app_te.arb
    ├── app_ta.arb
    ├── app_fr.arb
    ├── app_de.arb
    └── ...


The final set should contain 25 complete locale files, including translations for:
- Audiobook library.
- Import.
- Search.
- Playback.
- Sleep timer.
- Bookmarks.
- Listening history.
- Settings.
- Errors.
- Permissions.
- Accessibility labels.
Example:
{
  "audiobooks": "Audiobooks",
  "currentlyListening": "Currently listening",
  "notStarted": "Not started",
  "completed": "Completed",
  "importAudiobook": "Import audiobook",
  "sleepTimer": "Sleep timer",
  "bookmarks": "Bookmarks",
  "listeningHistory": "Listening history"
}


Do not translate only the main screen and call the localization complete. Every user-visible string must come from localization resources, including dialogs, validation errors, buttons and notifications where possible.

Generate the localization code using Flutter's localization tooling and test text overflow for long translations.

16. Backend implementation — Spring Boot
The backend should synchronize audiobook information across devices without becoming an audiobook file-hosting service.

Your current backend uses Spring Boot, PostgreSQL and Flyway. Add the audiobook module to that existing application.
Step 16.1 — Backend package structure
Inside your existing backend source directory:
com.readingsanctuary
└── audiobook/
    ├── controller/
    │   ├── AudiobookController.java
    │   ├── AudiobookProgressController.java
    │   ├── AudiobookBookmarkController.java
    │   └── AudiobookHistoryController.java
    ├── service/
    │   ├── AudiobookService.java
    │   ├── AudiobookProgressService.java
    │   ├── AudiobookBookmarkService.java
    │   └── AudiobookHistoryService.java
    ├── repository/
    │   ├── AudiobookRepository.java
    │   ├── AudiobookProgressRepository.java
    │   ├── AudiobookBookmarkRepository.java
    │   └── ListeningSessionRepository.java
    ├── entity/
    ├── dto/
    └── mapper/


Use your existing authentication and authorization system. Every request must be scoped to the authenticated user.
Step 16.2 — API endpoints
Method	Endpoint	Purpose
POST	/api/v1/audiobooks/sync	Sync imported book metadata
GET	/api/v1/audiobooks	Fetch audiobook library
GET	/api/v1/audiobooks/{id}	Fetch audiobook details
DELETE	/api/v1/audiobooks/{id}	Remove synchronized audiobook metadata
PUT	/api/v1/audiobooks/{id}/progress	Update listening progress
GET	/api/v1/audiobooks/{id}/progress	Retrieve listening progress
POST	/api/v1/audiobooks/{id}/bookmarks	Add bookmark
GET	/api/v1/audiobooks/{id}/bookmarks	Get bookmarks
PUT	/api/v1/audiobooks/bookmarks/{bookmarkId}	Edit bookmark
DELETE	/api/v1/audiobooks/bookmarks/{bookmarkId}	Delete bookmark
POST	/api/v1/audiobooks/{id}/sessions	Save listening session
GET	/api/v1/audiobooks/history	Retrieve listening history
GET	/api/v1/audiobooks/sync/changes	Fetch changes since last sync

Step 16.3 — Offline synchronization
Use this flow:
User imports or listens to an audiobook


Save locally first

Audiobook, tracks, progress and bookmarks


Add changes to sync queue


Internet available?

Yes

Send changes to Spring Boot API and reconcile server response.


No

Keep local data and retry later.




Important synchronization rules:
- Every local change gets a stable UUID.
- Track synchronization status separately from playback status.
- Use timestamps or version numbers to identify newer changes.
- Use idempotency so retries do not create duplicate bookmarks or sessions.
- Resolve progress conflicts using a clearly defined policy, preferably the most recent valid progress update.
- Do not delete local audio files when a user removes synchronized metadata from the server.
- Keep the original files accessible even if the user signs out, according to your app's existing local-data policy.

17. Navigation integration
Add audiobook destinations to your existing GoRouter configuration.

Recommended routes:
/audiobooks
/audiobooks/import
/audiobooks/:id
/audiobooks/:id/player
/audiobooks/bookmarks
/audiobooks/history
/audiobooks/settings


Connect these to your existing application shell.

Do not introduce a separate MaterialApp, separate ProviderScope or second navigation system.

Your app should continue to use:
- Existing sidebar on wider screens.
- Existing mobile navigation on narrow screens.
- Existing route guards.
- Existing authentication flow.
- Existing theme.
The mini-player should be available throughout the app when an audiobook is active, without covering important navigation controls.
18. Player screen design
The player should be the most polished screen in the audiobook module.






















8











Recommended layout:
┌─────────────────────────────────┐
│  ← Back              ⋮          │
│                                 │
│        NOW PLAYING              │
│                                 │
│        [BOOK COVER]             │
│                                 │
│        The Silent Patient       │
│        Alex Michaelides         │
│                                 │
│        Chapter 08               │
│                                 │
│  ━━━━━━━━━●━━━━━━━━━━━━         │
│  01:25:30           08:45:20    │
│                                 │
│       -15s  ▶  +30s             │
│                                 │
│  Chapters   Sleep   Bookmark    │
│                                 │
│  Speed: 1.25x                   │
│  Skip silence: ON               │
│  Volume boost: OFF              │
│                                 │
└─────────────────────────────────┘


The player should also include:
- Queue and chapter selection.
- Playback speed selection.
- Bookmark shortcut.
- Sleep timer shortcut.
- Auto rewind preference.
- Chapter-stop toggle.
- Audio output controls where supported.
On desktop and web, adapt the player layout to the available width rather than stretching the mobile layout.

19. Android configuration and platform work
Your current Android manifest already includes several useful declarations. Do not blindly add duplicate entries.

Review the following areas.
Permissions
You need to review:
- Internet access for online artwork.
- Foreground service.
- Media playback foreground service.
- Wake lock.
- Audio access through the system file picker.
- Notification permission where required by the Android version.
Avoid requesting broad storage access when the Android system file picker can grant access to the chosen files or folder.

READ_MEDIA_AUDIO is not a substitute for every folder-selection permission. Use the Storage Access Framework / system picker where possible.
Manifest and service
Your existing manifest has:
- AudioService.
- MediaButtonReceiver.
- FOREGROUND_SERVICE.
- FOREGROUND_SERVICE_MEDIA_PLAYBACK.
Check the manifest against the exact audio_service package version and Android target SDK before modifying it.
Native code
Additional native work will be required for:
Feature	Native/platform work
Background playback	Android media service configuration
Media notification	Media session and notification configuration
Android Auto	Media browser/session integration and validation
Home widgets	Kotlin widget implementation
Shake timer	Sensor integration and lifecycle handling
Widget refresh	Flutter-to-Android data communication

For iOS, background audio and WidgetKit need their own implementation. Web and Windows need their own supported file access and playback behavior.

20. Complete implementation order
All 11 features are included in this roadmap. The order matters because later features depend on earlier ones.
Implementation checklist
0/55 tasks



Phase 1 — Foundation

0/5

Data models, local database, repository, folder and file permissions, storage management.
[ ] Audit existing audiobook code and dependencies
[ ] Create audiobook, track, chapter and progress models
[ ] Create database tables and migrations
[ ] Implement repository and Riverpod providers
[ ] Add import and storage abstractions


Phase 2 — Import and library

0/7

Features 1, 2 and 8.
[ ] Import individual audio files
[ ] Select and scan folders recursively
[ ] Implement multi-track book grouping
[ ] Read metadata and duration
[ ] Create import preview and confirmation
[ ] Implement Current / Not started / Completed
[ ] Implement search, filters, grid and list views


Phase 3 — Playback

0/9

Feature 3.
[ ] Initialize one application-level audio handler
[ ] Build multi-track playback queue
[ ] Implement play, pause, seek and skip
[ ] Implement playback speed
[ ] Persist and restore progress
[ ] Implement chapters and chapter navigation
[ ] Implement chapter stop and quick rewind
[ ] Implement auto rewind
[ ] Implement silence detection and volume boost


Phase 4 — Listening tools

0/6

Features 4, 5 and 6.
[ ] Implement sleep timer and fade-out
[ ] Implement shake-to-extend and night appearance
[ ] Implement timestamp bookmarks and notes
[ ] Implement bookmark categories and favorites
[ ] Implement listening sessions and events
[ ] Implement history and resume suggestions


Phase 5 — Artwork

0/6

Feature 7.
[ ] Extract embedded artwork
[ ] Find local cover images
[ ] Implement online cover search and selection
[ ] Implement custom artwork
[ ] Cache covers safely
[ ] Implement dynamic player colours


Phase 6 — Android integration

0/5

Features 9 and 10.
[ ] Complete media notification and lock-screen controls
[ ] Implement Android home-screen widgets
[ ] Implement Android Auto media integration
[ ] Test Bluetooth and headphone controls
[ ] Test audio interruptions and restoration


Phase 7 — Appearance and localization

0/5

Feature 11.
[ ] Integrate existing dark and light themes
[ ] Implement custom and dynamic accents
[ ] Implement sleep appearance
[ ] Create 25 localization resources
[ ] Translate and test every user-visible string


Phase 8 — Backend and synchronization

0/6

Cloud sync across the module.
[ ] Create Flyway migration
[ ] Add backend entities, repositories and DTOs
[ ] Add authenticated REST endpoints
[ ] Implement local-first synchronization
[ ] Handle conflicts and retries
[ ] Test multi-device restoration


Phase 9 — Full validation

0/6

Regression, performance and release readiness.
[ ] Run Flutter analyze and tests
[ ] Run backend tests and migrations
[ ] Test Android background playback
[ ] Test file import and multi-track grouping
[ ] Test offline behavior and synchronization
[ ] Test accessibility, responsiveness and localization

Reset checklist

21. Testing requirements
Do not consider the audiobook module finished merely because the screens render.
Import tests
- Import one MP3.
- Import one M4B.
- Import a folder with 20 tracks.
- Import a folder with multiple books.
- Import files with missing metadata.
- Import duplicate files.
- Import files with incorrect extensions.
- Cancel an import halfway through.
- Restart the app and verify the library remains intact.
Playback tests
- Play and pause.
- Switch between tracks.
- Seek forwards and backwards.
- Restore position after restarting the app.
- Change speed.
- Handle an unsupported or corrupt audio file.
- Receive a phone call during playback.
- Lock the phone during playback.
- Disconnect headphones.
- Test sleep timer expiration.
- Test chapter-stop behavior.
- Test background playback for an extended period.
Bookmark and history tests
- Save a bookmark in the middle of a track.
- Close and reopen the app.
- Jump to the saved bookmark.
- Edit the bookmark.
- Favorite it.
- Verify the correct audiobook and chapter are restored.
- Check actual listening time against pauses and seeks.
UI tests
- Small Android phone.
- Large Android phone.
- Tablet.
- Desktop browser.
- Narrow browser window.
- Light theme.
- Dark theme.
- Long book titles.
- Missing artwork.
- Long translations.
Backend tests
- Authenticated audiobook synchronization.
- User A cannot access User B's audiobooks.
- Duplicate sync requests do not create duplicate records.
- Offline progress synchronization.
- Concurrent progress updates.
- Bookmark update and deletion.
- Database migration from the current schema.
Final commands
Frontend:
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test


Only run the build-runner command if your selected database/code-generation packages require it.

Backend:
cd backend/reading-sanctuary-api
mvn clean test


Then run the backend against a development database and verify all Flyway migrations.

22. Important design and engineering decisions
These are the decisions I would keep fixed throughout development:
Area	Decision
Audio engine	Existing just_audio
Background playback	Existing audio_service
Audio focus	Existing audio_session
State management	Existing Riverpod
Navigation	Existing GoRouter
Import model	Bring your own DRM-free audiobooks
Book structure	One book, multiple tracks
Local audio storage	Keep user-selected files accessible; don't duplicate unnecessarily
Progress	Persist locally and sync to server
Artwork	Embedded → local → online → fallback
Themes	Extend existing Reading Sanctuary themes
Android widgets	Native Android implementation
Android Auto	Media browser/session integration
Localization	25 complete locale resources
Backend	Existing Spring Boot and PostgreSQL

There are a few features that deserve particular attention:
1. DRM: This system is designed for DRM-free audio files. It will not bypass DRM or copy protected audiobook content.
2. Folder access: Some Android and web file-picker selections provide temporary access rather than a permanent filesystem path. Store persistent permissions where the platform supports them, or copy the files into app-managed storage when the user explicitly chooses that option.
3. Silence skipping and volume boost: These need genuine audio-processing behavior, not cosmetic toggles.
4. Android Auto: A working notification does not prove Android Auto compatibility.
5. Widgets: Native Android and iOS widgets are separate platform implementations.
6. 25 languages: Translation files and layout testing are required; machine-translated labels alone are not a finished localization system.
23. What I recommend doing with your actual repository
The guide above is the complete implementation blueprint, but I want to be precise about one limitation: I checked your current pubspec.yaml, AndroidManifest.xml and main.dart, not every source file in the repository. I therefore haven't verified whether you already have an audiobook handler, local database, import service, routes or player screen that should be extended.

Do not replace your existing audiobook implementation with the skeletons above. In particular, the sample audio handler is a foundation, not a complete production implementation.

To turn this into exact, file-by-file implementation instructions, use your current repository:
Reading Sanctuary repository

Before changing anything, create a Git branch:
git checkout -b feature/complete-audiobook-module


Then share the latest ZIP of your project, containing:
reading-app/
├── frontend/
│   └── reading_sanctuary_app/
│       ├── lib/
│       ├── android/
│       ├── test/
│       └── pubspec.yaml
└── backend/
    └── reading-sanctuary-api/
        ├── src/
        └── pom.xml


Exclude .env, passwords, signing keys, build, .dart_tool, target and .gradle.

With the actual source, the next implementation can specify the exact existing files to modify, the complete code for each new file, the precise changes to existing files, and the commands and tests to run after each step. That is how we can add all 11 feature groups without accidentally breaking your existing Reading Sanctuary functionality or losing its theme.
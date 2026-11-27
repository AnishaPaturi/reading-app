# 📚 Reading Sanctuary
### Your Personal Digital Reading & Listening Ecosystem

**Read. Listen. Annotate. Organize. Remember.**

Reading Sanctuary is a cross-platform personal reading and audiobook application designed to bring an entire reading life into one organized, customizable, and private digital space.

It unifies a multi-format ebook reader (`EPUB`, `PDF`, `DOCX`), a dedicated audiobook player (`MP3`, `M4B`, `M4A`, `OGG`, `OGA`, `OPUS`), device-native Text-to-Speech (`TTS`), customizable visual bookshelves (covers & spines with smart shelves and per-book sizing), a monthly Reading Calendar & streak tracker, highlights/annotations/journal workflows, offline downloads, and delta cloud synchronization.

---

## 1. Project Overview

| Attribute | Details |
|---|---|
| **Project Name** | Reading Sanctuary |
| **Project Type** | Cross-platform Personal Reading & Audiobook Management Platform |
| **Frontend** | Flutter & Dart (Riverpod, GoRouter, Claymorphism + Dark Academia / Warm Parchment themes) |
| **Localization** | **25 languages** via Flutter `l10n` (`lib/l10n/app_*.arb`) |
| **Backend** | Java 25 & Spring Boot (modular monolith, 31 REST controllers across 24 domain packages) |
| **Database** | PostgreSQL 18 (versioned via **22 Flyway migrations**, `V1`–`V22`) |
| **Local Persistence** | SharedPreferences / SQLite outbox cache (Mobile & Desktop) + IndexedDB (Flutter Web audiobooks) |
| **Authentication** | JWT Bearer Auth + Spring Security + Google OAuth 2.0 ID/userinfo verification |
| **File Storage** | Local disk object storage (`LocalStorageService`) & private AWS S3 presigned storage (`S3StorageService`) |
| **API Documentation** | Swagger / OpenAPI (`/swagger-ui.html`) |
| **Target Platforms** | Android, Web, Windows Desktop, and iOS |

---

## 2. The Problem Statement & Vision

Readers typically split their reading life across separate reader apps, audiobook players, note-taking tools, spreadsheets, and cloud folders. **Reading Sanctuary** consolidates all reading and listening into one private, user-owned ecosystem built around six priorities:

1. **Distraction-free Reading & Listening** across ebooks, audiobooks, and Text-to-Speech.
2. **Privacy & Data Ownership** with private-by-default libraries and strict per-user backend isolation.
3. **Deep Personalization** with custom shelves, smart shelf rules, book spine/cover size controls, themes, and 25 locales.
4. **Separate Book vs. File Modeling** so `EPUB`, `PDF`, `DOCX`, and audio formats stay attached to a single book record without duplicate entries.
5. **Non-destructive Reading History**, preserving progress, sessions, and notes even when marking a book **Did Not Finish (DNF)** or moving it to the Forgotten Shelf (Trash).
6. **Offline-First & Multi-Device Sync** using monotonic sequence cursors, idempotent client outbox operations, and SHA-256 checksum verification.

---

## 3. Feature Ecosystem Overview

Reading Sanctuary synthesizes capabilities documented across:
- [Features.md](Features.md) — Reading Calendar, Analytics, Library Management, My Bookshelf, Smart Shelves, Individual Book Sizing, and Rich Book Metadata.
- [BOOK.md](BOOK.md) — Ebook library organization, multi-format reader architecture (`EPUB`, `PDF`, `DOCX`), highlights, quotes, notes, bookmarks, reading customization, TTS, file discovery, and offline reading.
- [AUDIO.md](AUDIO.md) — Complete 11-module Audiobook subsystem covering library management, import/metadata extraction, playback, sleep timer, bookmarks, history, artwork palettes, widgets, background audio, and 25-language localization.

### 3.1 Book Library, Reader & Ebook Capabilities ([BOOK.md](BOOK.md))
- **Unified Book & File Model:** Separate `Book` and `BookFile` entities allow attaching multiple digital formats (`EPUB`, `PDF`, `DOCX`, `MP3`, `M4B`, `M4A`) under one book without duplication.
- **Integrated Readers:**
  - **EPUB (`flutter_epub_viewer`):** Reflowable chapters, Table of Contents drawer, chapter/CFI reading progress persistence, in-book search, font/reader preferences, and reading themes.
  - **PDF (`pdfrx`):** Page-by-page navigation slider, page count tracking, and progress sync.
  - **DOCX (`docx_viewer`):** Structured Word document reading and progress tracking.
- **Book Discovery & Duplicate Detection:** Platform-aware `BookDiscovery` module (`DiscoverBooksScreen`) with Android Storage Access Framework (`SAF`) folder registration, desktop directory scanning, in-browser Web scanning, file-signature validation, SHA-256 duplicate reconciliation (`V22`), and batch upload.
- **Annotations, Highlights, Bookmarks & Journal:** Color-coded text highlights (`HighlightColorPicker`), anchored chapter notes, favorite quotes (`V19`), reading bookmarks (`V4`, `V18`), centralized annotation panel, and a dedicated Reading Journal screen.
- **Text-to-Speech (TTS):** On-device narration fallback (`flutter_tts`) backed by extracted document text chunks (`DocumentTextController`), adjustable speed, voice selection, and server/offline position tracking (`V7`).
- **Reading Lists, DNF & Trash:** `Want to Read`, `Currently Reading`, `Completed`, `On Hold`, `DNF` (with cinematic DNF screen preserving progress & notes), `Favorites`, and recoverable **Forgotten Shelf / Trash** (`V20`).

### 3.2 Complete Audiobook System — All 11 Feature Groups ([AUDIO.md](AUDIO.md))
1. **Personal Audiobook Library:** `Current`, `Not started`, and `Completed` sections with cover art, narrator/author metadata, completion percentages, and Grid / List view switcher.
2. **Importing & Multi-Track Grouping:** Supports DRM-free `M4B`, `MP3`, `M4A`, `OGG`, `OGA`, and `OPUS`; extracts tags (`TIT2`, `TPE1`, `TALB`, `TRCK`), durations, and embedded cover art via `audio_metadata_reader`; groups multi-file chapters into a single `Audiobook` record (`AudiobookGroupingUtils`) with duplicate checks.
3. **Playback Engine (`just_audio` + `audio_service` + `audio_session`):** Play/pause, variable playback speed, `-15s` / `+30s` jump controls, chapter list navigation, chapter rollover, silence skipping & volume boost settings UI, and `Resume Playback`.
4. **Sleep Timer:** Timed duration presets (`15`, `30`, `45`, `60 min`), `End of chapter` and `End of track` boundary stops, smooth volume fade-out, shake-to-extend (`sensors_plus`), and Night appearance mode.
5. **Bookmarks & Listening Notes:** Timestamped bookmarks organized by category (`Note`, `Quote`, `Revisit`) and favorites, viewable per-book and on a global `All Bookmarks` screen.
6. **Listening History:** Records listening sessions, pauses, jumps, and previous resume positions (`AudiobookHistoryPage`).
7. **Cover Management & Dynamic Player Colors:** Uses embedded audio artwork, user-selected custom covers (`Change Cover`), or fallback generated covers; derives adaptive player colors via `palette_generator`.
8. **Search & Discovery:** Instant title/author search and completion-status filtering across the audiobook collection.
9. **Android Home-Screen Widgets:** Native Kotlin app widgets (`AudiobookNowPlayingWidgetProvider.kt` and `AudiobookShelfWidgetProvider.kt`) integrated via `home_widget`.
10. **Background Audio & Media Integration:** Android foreground service (`AudioService`) and `MediaButtonReceiver` declarations for background playback and headset/Bluetooth media buttons *(see §11 for Phase 8 release-APK media notification bug note)*.
11. **Appearance & 25-Language Localization:** Dark Academia, Warm Parchment, and Clay themes plus localized ARB resources for **25 languages** (`ar`, `bn`, `de`, `en`, `es`, `fr`, `gu`, `hi`, `id`, `it`, `ja`, `kn`, `ko`, `ml`, `mr`, `nl`, `pa`, `pl`, `pt`, `ru`, `ta`, `te`, `tr`, `vi`, `zh`).

---

## 4. Reading Sanctuary — Complete Feature Checklist (8 Categories / 99+ Checklist Items)

Master checklist aligned with [Features.md](Features.md):

### 4.1 Reading Dashboard & Tracker
- [x] **Daily Greeting & Date** — Personalized time-of-day greeting and formatted current date on the Home dashboard.
- [x] **Reading Momentum** — 7-day consistency indicator showing active reading days and momentum tier.
- [x] **Daily Reading Streak** — Consecutive daily reading streak counter backed by reading-session analytics.
- [x] **Personal Best Streak** — Displays the user's longest recorded reading streak.
- [x] **Weekly Streak Calendar** — Seven-day (`MON`–`SUN`) strip highlighting completed reading days.
- [x] **Mark Today Complete** — One-tap action to log daily reading completion.
- [x] **Streak Freeze** — Protects an active reading streak across a missed day (`V8` streak freeze records).
- [x] **Streak Freeze Availability** — Displays remaining and previously consumed streak freezes.
- [x] **Currently Reading Section** — Dedicated Home carousel highlighting active reads.
- [x] **Multiple Currently Reading Books** — Horizontal carousel navigation across multiple active books.
- [x] **Book Cover & Title** — Displays cover art and book title on dashboard cards.
- [x] **Author & Genre** — Displays author name and genre metadata on active reading cards.
- [x] **Reading Format** — Displays associated format pills (`eBook`, `EPUB`, `PDF`, `DOCX`, `Audiobook`).
- [x] **Reading Progress Slider** — Visual slider and percentage bar synced with `reading_progress`.
- [x] **Current Page Controls** — Controls to increment, decrement, or jump directly to the current page.
- [x] **Total Page Count** — Displays total book page count alongside current page.
- [x] **Reading Start Date** — Records and displays when reading began (`started_at`).
- [x] **Days Spent Reading** — Calculates elapsed days since starting the book.
- [x] **Average Pages Per Day** — Calculates average daily reading pace from session history.
- [x] **Estimated Days Remaining** — Projects remaining days to finish based on current pace and remaining pages.
- [x] **Expandable Book Description** — Expand/collapse synopses cleanly without cluttering cards.

### 4.2 Reading Calendar — Additional Feature
- [x] **Monthly Calendar View** — Proper calendar grid displaying exact dates aligned by day of week (`ReadingCalendarScreen`).
- [x] **Weekday Headings** — Monday through Sunday column headers above the monthly grid.
- [x] **Green Reading Indicator** — Marks dates with recorded reading/listening activity in green.
- [x] **Red Missed-Day Indicator** — Marks elapsed past dates without reading activity in red.
- [x] **Future Date Indicators** — Keeps upcoming dates visually neutral rather than marking them missed.
- [x] **Today's Highlight** — Visually distinguishes the current date cell.
- [x] **Month Navigation** — Previous/next month controls to browse historical and current months.
- [x] **Daily Reading Details** — Tapping any date displays pages read, time spent, and books read on that day.
- [x] **Monthly Reading Summary** — Summarizes total days read, days missed, and streak metrics for the month.
- [x] **Monthly Pages & Reading Time** — Totals pages read and reading/listening duration for the selected month.

### 4.3 Library Management
- [x] **Select / Import Books** — Device file picker import (`AddBookScreen`) for `EPUB`, `PDF`, `DOCX`, and audio formats with server upload (`BookUploadController`).
- [x] **Scan Books** — Multi-platform folder discovery (`DiscoverBooksScreen`) via SAF (Android), directory traversal (Desktop), and file chooser (Web).
- [x] **Manual Book Addition** — Add book records manually without attaching a digital file (`/library/add-manual`).
- [x] **Advanced Book Search** — Live search matching book title, author, and genre (`library_logic.dart`, `/search`).
- [x] **Recently Added Sorting** — Sort library collections by added date and additional sort criteria.
- [x] **Reading Status Filter** — Filter by `All Books`, `Reading`, `TBR`, `Completed`, `On Hold`, `DNF`.
- [x] **Book Status Filter** — Filter by availability / library status (including Trash / Deleted views).
- [x] **Author Filter** — Filter library books by selected author (`AdvancedFilterSheet`).
- [x] **Genre Filter** — Filter library books by selected genres (`LibraryFilterSheet` / `AdvancedFilterSheet`).
- [x] **Format Filter** — Filter by `EPUB`, `PDF`, `DOCX`, and `Audiobook`.
- [x] **Rating Filter** — Filter books by star rating thresholds.
- [x] **More Filters** — Multi-criteria combinable filter sheets.
- [x] **Book Cover Grid** — Responsive multi-column cover grid (`BookGridCard`).
- [x] **Book Titles & Authors** — Title and author labels rendered on library cards.
- [x] **Reading Status Indicators** — Status pills rendered directly on each library card.
- [x] **Star Ratings on Book Cards** — Saved star rating display rendered on library cards.

### 4.4 My Bookshelf
- [x] **Dedicated My Bookshelf Screen** — Separate `BookshelvesScreen` and `BookshelfDetailScreen` views.
- [x] **Covers View** — Front cover shelf display (`BookCoverGrid` / shelf cards).
- [x] **Spines View** — Physical bookshelf layout rendering vertical 3D/clay book spines (`BookshelfBookSpine`, `ClayBookSpine`).
- [x] **Covers / Spines Switcher** — Layout selector (`BookshelfLayoutSelector`) toggling Covers vs. Spines views.
- [x] **Scan Spines** — Interactive Spine Scanner modal sheet (`ScanSpinesSheet`) that previews detected titles and adds them to the user's library *(note: currently uses a simulated scan workflow; live hardware camera OCR is a future enhancement)*.
- [x] **Adjust Book Sizes** — Interactive resize mode for customizing bookshelf book dimensions (`BookSizeSlider`).
- [x] **Small Size Preset** — `S` dimension preset for shelf items.
- [x] **Medium Size Preset** — `M` dimension preset for shelf items.
- [x] **Large Size Preset** — `L` dimension preset for shelf items.

### 4.5 Bookshelf Statistics
- [x] **Total Books** — Total library book count (`LibraryStatistics`).
- [x] **Completed Books** — Count of completed books.
- [x] **Completion Percentage** — Computed percentage of completed books across the library.
- [x] **Currently Reading Count** — Count of books marked `Currently Reading`.
- [x] **Want to Read Count** — Count of books on the `Want to Read` (`TBR`) list.
- [x] **Average Book Rating** — Computed average score across rated books.
- [x] **Genre Statistics** — Per-genre book breakdown & charts (`GenrePieChart`, `TopGenresChart`).
- [x] **Favourite Genre** — Highlights the top-represented genre in the user's library.

### 4.6 Automatic Bookshelf Organisation
All 14 smart-shelf categories are driven by [`SmartShelfService`](frontend/reading_sanctuary_app/lib/features/bookshelf/application/smart_shelf_service.dart):
- [x] **Genre-Based Shelves** (`SmartShelfCategory.genre`)
- [x] **Author-Based Shelves** (`SmartShelfCategory.author`)
- [x] **Reading Status Shelves** (`SmartShelfCategory.readingStatus`)
- [x] **Book Status Shelves** (`SmartShelfCategory.bookStatus`)
- [x] **Page Count Shelves** (`SmartShelfCategory.pageCount`)
- [x] **Rating-Based Shelves** (`SmartShelfCategory.rating`)
- [x] **Publisher-Based Shelves** (`SmartShelfCategory.publisher`)
- [x] **Format-Based Shelves** (`SmartShelfCategory.format`)
- [x] **Price-Based Shelves** (`SmartShelfCategory.price`)
- [x] **Spice Rating Shelves** (`SmartShelfCategory.spice`)
- [x] **Recommendation Shelves** (`SmartShelfCategory.recommendation`)
- [x] **Mood-Based Shelves** (`SmartShelfCategory.mood`)
- [x] **Series-Based Shelves** (`SmartShelfCategory.series`)
- [x] **Collection-Based Shelves** (`SmartShelfCategory.collections`)
- [x] **Book Count Per Shelf** — Displays count badges per shelf.
- [x] **Automatic Book Matching** — Dynamically recomputes shelf membership whenever book metadata updates.
- [x] **Multiple Shelf Columns** — Responsive multi-column layout on wider viewports.
- [x] **Vertical Bookshelf Scrolling** — Vertical scroll across shelf categories and rows.
- [x] **Horizontal Shelf Scrolling** — Horizontal scrolling through books inside each shelf row.

### 4.7 Individual Book Size Customisation
Managed via `BookSizeProvider` and `BookSizeSlider`:
- [x] **Resize Mode** — Dedicated editing mode toggled from bookshelf controls.
- [x] **Individual Book Selection** — Tap any shelf book to target it for resizing.
- [x] **Selected Book Highlight** — Highlights the active book during customization.
- [x] **Individual Height Slider** — Continuous height slider controlling scale factor (`BookSizeSlider`).
- [x] **Live Size Preview** — Immediate visual scaling as the slider or preset changes.
- [x] **Automatic Width Adjustment** — Maintains proportional aspect ratio when height changes.
- [x] **Auto Reset** — `Reset All` button restores default book dimensions.
- [x] **Done / Save Changes** — Persists size customizations and exits resize mode.
- [x] **Preserve Neighbour Positions** — Resizing one book preserves neighboring book sizing and order.

### 4.8 Book Details & Metadata
Implemented across `BookDetailsScreen`, `EditBookMetadataSheet`, `Book` model, and Flyway `V21`:
- [x] **Enlarged Book Cover** — Prominent cover card with upload/replace capability (`BookCoverController`).
- [x] **Book Title** — Editable title field.
- [x] **Author Name** — Editable author field.
- [x] **Reading Status** — Selector across `Want to Read`, `Currently Reading`, `Completed`, `On Hold`, `DNF`.
- [x] **Book Format** — Interactive format switcher tabs (`Book`, `eBook`, `Audiobook`).
- [x] **Personal Recommendation** — Classification tags (`Highly Recommend`, etc.).
- [x] **Star Rating** — Interactive 5-star overall rating.
- [x] **Numerical Rating Out of 100** — Detailed `0–100` score input (`ratingOutOf100`).
- [x] **Genre** — Editable primary genre and tags.
- [x] **Page Count** — Editable total pages (`totalPages`) and quick `Update page` dialog.
- [x] **Acquisition Method** — Tracks `Purchased`, `Borrowed`, `Gifted`, etc. (`acquisitionMethod`).
- [x] **Reading Start Date** — Stored and editable `startedAt`.
- [x] **Completion Date** — Stored and editable `completedAt`.
- [x] **Purchase Date** — Stored and editable `purchaseDate`.
- [x] **Purchase Price** — Amount (`purchasePrice`) and `currency` support.
- [x] **Publisher** — Editable `publisher` metadata.
- [x] **ISBN** — Stored and editable `isbn` identifier.
- [x] **Spice Rating** — Interactive 1–5 spice meter + Fluff & Tear ratings.
- [x] **Book Tropes** — Multi-tag trope chips (e.g., *Enemies to Lovers*, *Slow Burn*).
- [x] **Book Mood** — Mood categorization (e.g., *Dark*, *Cozy*, *Emotional*, *Romantic*).

---

## 5. System Architecture

```text
                           READING SANCTUARY
                                   |
           +-----------------------+-----------------------+
           |                       |                       |
      Flutter Web           Flutter Android        Flutter Desktop
    (IndexedDB Audio)      (SAF + AudioService)    (Local FS + SQLite)
           |                       |                       |
           +-----------------------+-----------------------+
                                   |
                             HTTPS / REST
                          (/api/v1/ + JWT Auth)
                                   |
                         SPRING BOOT BACKEND
             (Java 25, Spring Security, JPA, Flyway V1-V22)
                                   |
     +-------------------+---------+---------+-------------------+
     |                   |                   |                   |
  Auth & User      Books & Metadata     Reader & Audio      Analytics & Sync
(auth, user)    (book, bookfile,     (readerposition,    (analytics, sync,
                 bookshelf,           readingprogress,    activity sessions,
                 bookmetadata,        bookmark, note,     reading goals,
                 collection)          highlight, tts)     streak freezes)
                                   |
                     PostgreSQL 18 + Storage
                 (Local Storage / Private AWS S3)
```

---

## 6. Database Schema (Flyway Migrations `V1`–`V22`)

| Migration | Scope |
|---|---|
| `V1__initial_schema.sql` | Core `users`, authentication, and initial tables |
| `V2__book_metadata_and_covers.sql` | Books, metadata fields, and cover storage keys |
| `V3__reading_progress_and_library_organization.sql` | Bookshelves, collections, reading status, and initial progress |
| `V4__bookmarks_highlights_and_notes.sql` | Bookmarks, highlights, and notes tables |
| `V5__reader_positions.sql` | Reader position snapshots across book files |
| `V6__audiobook_playback.sql` | Backend audiobook playback tracking |
| `V7__tts_playback_positions.sql` | Text-to-Speech listening position tracking |
| `V8__create_reading_analytics.sql` | Activity sessions, daily reading history, reading goals, and streak freezes |
| `V9__create_sync_infrastructure.sql` | `user_devices` and `sync_change_log` monotonic cursor tables |
| `V10__google_authentication.sql` | Google OAuth subject linking (`google_sub`) |
| `V11__add_user_gender.sql` | User profile gender attribute |
| `V12__bookshelf_customization.sql` | Shelf themes, layouts, and custom book sizing persistence |
| `V13__expand_book_file_formats_and_pending_uploads.sql` | Expanded ebook/document format support & pending multi-step uploads |
| `V14__add_dnf_details.sql` | `dnf_at`, `dnf_reason`, `dnf_notes`, `previous_reading_status` |
| `V15__support_m4a_format.sql` | `.m4a` audio format constraint update |
| `V16__create_audiobook_module.sql` | Audiobook metadata, tracks, bookmarks, and listening session sync tables |
| `V17__create_reading_progress.sql` | Unified per-file `reading_progress` (`epub_cfi`, page, percentage, audio ms) |
| `V18__create_annotations.sql` | Unified format-aware `annotations` schema |
| `V19__support_quote_annotations.sql` | Dedicated quote annotation support |
| `V20__book_trash_and_restore.sql` | Soft delete (`deleted_at`) & Forgotten Shelf restoration |
| `V21__expand_book_metadata_and_reading_tracker.sql` | Publisher, ISBN, `rating_out_of_100`, spice/recommendation, tropes, mood, purchase price/date, acquisition method |
| `V22__book_file_checksum_index_and_duplicate_tracking.sql` | File SHA-256 checksum index & duplicate upload detection |

---

## 7. Repository Folder Structure

```text
reading-app/
│
├── frontend/
│   └── reading_sanctuary_app/
│       ├── android/                       # Android project, Gradle build, SAF channel & Home Widgets
│       │   └── app/src/main/kotlin/com/example/reading_sanctuary_app/
│       │       ├── MainActivity.kt
│       │       ├── AudiobookNowPlayingWidgetProvider.kt
│       │       └── AudiobookShelfWidgetProvider.kt
│       ├── ios/ web/ windows/             # Platform runners
│       ├── lib/
│       │   ├── main.dart                  # ProviderScope entry point + dotenv initialization
│       │   ├── app/
│       │   │   ├── app.dart               # MaterialApp.router, themes & 25-locale delegates
│       │   │   ├── router.dart            # GoRouter session restore, auth redirect & ShellRoute
│       │   │   └── theme/                 # Dark Academia, Warm Parchment & Clay themes
│       │   ├── core/
│       │   │   ├── network/               # ApiConfig (Web/Android/CLI), ApiClient, ApiException
│       │   │   ├── sync/                  # SyncEngine, LocalStorageDb, SyncApiService
│       │   │   ├── utils/                 # Breakpoints, relative time helpers
│       │   │   └── widgets/               # BookCover, ClayComponents, ClayBottomNavBar
│       │   ├── l10n/                      # 25 language ARB files & generated localizations
│       │   ├── shared/                    # Book model, repositories, Riverpod providers
│       │   └── features/                  # 28 modular feature packages:
│       │       ├── analytics/             # Analytics dashboard, goals, yearly wrap-up, charts
│       │       ├── annotations/           # Highlights, color picker, notes & panel
│       │       ├── audiobook/             # Full 11-feature audiobook module + IndexedDB storage
│       │       ├── authentication/        # Email/password auth, Google OAuth, session storage
│       │       ├── book_details/          # Book details, format tabs & metadata editor sheet
│       │       ├── book_discovery/        # Multi-platform folder discovery, SAF & batch upload
│       │       ├── books/                 # Single-book file validation & import flows
│       │       ├── bookshelf/             # My Bookshelf, SmartShelfService, Spine View, BookSizeSlider
│       │       ├── calendar/              # Monthly Reading Calendar grid & daily activity details
│       │       ├── cloud_storage/         # Cloud storage quota & file management screen
│       │       ├── discover/              # In-app curated book discovery
│       │       ├── dnf/                   # Cinematic DNF screen with preserved history
│       │       ├── favorites/             # Favorites collection screen
│       │       ├── help/                  # In-app help & documentation
│       │       ├── home/                  # Dashboard, greeting, streaks, Currently Reading carousel
│       │       ├── journal/               # Personal reading reflections & journal screen
│       │       ├── landing/               # Onboarding slides
│       │       ├── library/               # Library grid, advanced filters, AddBookScreen
│       │       ├── offline/               # DownloadManager (SHA-256) & DownloadsScreen
│       │       ├── profile/               # User profile, stats & Shelves/Settings tab
│       │       ├── reader/                # EPUB (WebView/JS), PDF (pdfrx), DOCX (docx_viewer) readers
│       │       ├── reading/               # Active reading overview screen
│       │       ├── search/                # Global library & metadata search
│       │       ├── settings/              # Theme, sync, localization & app settings
│       │       ├── shell/                 # Responsive AppShell (BottomNav / Collapsible Sidebar)
│       │       ├── splash/                # Startup session restoration loading view
│       │       ├── text_to_speech/        # Device TTS reader screen, chunker & voice selector
│       │       └── tracker/               # Reading status trackers, Saved Highlights & Favorite Quotes
│       └── test/                          # 63 test files (373 unit & widget tests)
│
├── backend/
│   └── reading-sanctuary-api/
│       └── src/
│           ├── main/java/com/readingsanctuary/api/  # 24 modules, 31 REST controllers
│           ├── main/resources/db/migration/         # Flyway V1__ through V22__
│           └── test/java/                           # 34 test suites (178 tests)
│
├── docs/                                  # Architecture, setup, testing & deployment guides
├── Features.md                            # 89 + Reading Calendar implementation guide & checklist
├── BOOK.md                                # Ebook library & reader capability reference
├── AUDIO.md                               # 11-feature Audiobook architecture & guide
└── README.md                              # Project documentation (this file)
```

---

## 8. Backend REST API Surface (`/api/v1/`)

Protected endpoints enforce Spring Security JWT Bearer authentication and per-user data ownership:

| Domain | Controller(s) | Key Base Paths |
|---|---|---|
| **Auth & Users** | `AuthController`, `UserController` | `/api/v1/auth/signup`, `/api/v1/auth/login`, `/api/v1/auth/google`, `/api/v1/users/me` |
| **Books & Upload** | `BookController`, `BookUploadController`, `BookMetadataController`, `BookCoverController` | `/api/v1/books`, `/api/v1/books/upload`, `/api/v1/books/check-duplicates`, `/api/v1/books/{id}/cover` |
| **Book Files & Storage** | `BookFileController`, `CloudStorageController`, `DocumentTextController` | `/api/v1/books/{bookId}/files`, `/api/v1/storage/files/{fileId}/download-url`, `/api/v1/storage/local/download` |
| **Reading Progress & Positions** | `ReadingProgressController`, `BookReadingPositionController`, `BookReadingController`, `BookHistoryController` | `/api/v1/reading-progress/{fileId}`, `/api/v1/books/{bookId}/reading-position` |
| **Annotations, Bookmarks & Notes** | `AnnotationController`, `BookmarkController`, `HighlightController`, `BookNoteController`, `BookReviewController` | `/api/v1/annotations`, `/api/v1/bookmarks`, `/api/v1/highlights`, `/api/v1/notes` |
| **Bookshelves & Collections** | `BookshelfController`, `CollectionController`, `ReferenceDataController` | `/api/v1/bookshelves`, `/api/v1/collections` |
| **Audiobooks & TTS** | `AudiobookController`, `AudiobookPlaybackController`, `AudiobookProgressController`, `AudiobookBookmarkController`, `AudiobookHistoryController`, `TtsPlaybackController` | `/api/v1/audiobooks`, `/api/v1/tts` |
| **Analytics, Calendar & Sync** | `AnalyticsController`, `ActivitySessionController`, `ReadingGoalController`, `SyncController`, `DeviceController` | `/api/v1/analytics/*`, `/api/v1/reading-goals`, `/api/v1/sync/*`, `/api/v1/devices` |

---

## 9. Running the Project Locally

### Prerequisites
- **Java 25**, **Maven** (or included `./mvnw` / `.\mvnw.cmd`), **PostgreSQL 18**
- **Flutter SDK (`>=3.3.0`)** & **Android SDK** (for Android builds/emulators)

### 9.1 Start PostgreSQL & Spring Boot Backend
1. Ensure PostgreSQL is running locally on `localhost:5432` with database `reading_sanctuary_db`.
2. Configure `backend/reading-sanctuary-api/.env` (or environment variables): `DATABASE_URL`, `DATABASE_USERNAME`, `DB_PASSWORD`, `READING_SANCTUARY_JWT_SECRET`, and `GOOGLE_CLIENT_ID`.
3. Launch the backend (using a clean build avoids stale incremental `$1` inner classes):
   ```powershell
   cd backend\reading-sanctuary-api
   .\mvnw.cmd clean spring-boot:run
   ```
4. Health check: `http://localhost:8080/actuator/health`

### 9.2 Run the Flutter Frontend
Create/verify `frontend/reading_sanctuary_app/.env` with `GOOGLE_WEB_CLIENT_ID` and `GOOGLE_SERVER_CLIENT_ID`, then run from `frontend\reading_sanctuary_app`:

```powershell
# Flutter Web (fixed port 3000)
flutter run -d chrome --web-port 3000

# Build release Web bundle & serve statically
flutter build web --no-pub
python -m http.server 3000 --bind 127.0.0.1 --directory build/web

# Android Emulator (defaults to http://10.0.2.2:8080/api/v1 via ApiConfig)
flutter emulators --launch Pixel_5
flutter run

# Build Android Release APK
flutter build apk --no-pub

# Windows Desktop (requires Windows Developer Mode for plugin symlinks)
flutter run -d windows
```

### 9.3 Google OAuth Configuration Notes
To enable live Google Sign-In in Google Cloud Console:
- **Web Client:** Add exact authorized JavaScript origins (e.g., `http://localhost:3000`, `http://127.0.0.1:3000`, and your production HTTPS origin).
- **Android Client:** Create an Android OAuth 2.0 Client ID for package `com.example.reading_sanctuary_app` with both your local debug SHA-1 and a dedicated production release keystore SHA-1, while keeping `GOOGLE_SERVER_CLIENT_ID` set to your Web OAuth Client ID so ID tokens pass backend audience validation (`GoogleTokenVerifier`).
- **OAuth Consent Screen:** While in Testing mode, list QA Google accounts under **Test users**.

---

## 10. Automated Verification Baseline

Latest full verification results across the repository:

| Check | Command | Scope & Result | Status |
|---|---|---|---|
| **Backend Test Suite** | `.\mvnw.cmd test` | **178 tests run, 0 failures, 0 errors, 0 skipped** (JUnit 5 + Mockito + MockMvc) | **PASS** |
| **Flutter Static Analysis** | `flutter analyze` | **0 issues found** across entire Flutter codebase | **PASS** |
| **Flutter Test Suite** | `flutter test` | **373 / 373 tests passed** across 63 test files | **PASS** |
| **Flutter Web Release Build** | `flutter build web --no-pub` | Compiled cleanly to `build/web` | **PASS** |
| **Android Release APK** | `flutter build apk --no-pub` | Built cleanly (`build/app/outputs/flutter-apk/app-release.apk`, 95.6 MB) | **PASS** |

---

## 11. Platform Acceptance Summary & Known Issues

Live end-to-end acceptance testing was executed against PostgreSQL 18 + Spring Boot (`localhost:8080`), Flutter Web (`http://127.0.0.1:3000`), and Android Emulator `Pixel_5` (Android 16 / SDK 36):

### Verified End-to-End (`PASS`)
- **Authentication & Sessions:** Account signup, email/password login, sign-out, session persistence across browser reload & Android `force-stop`, and expired-JWT redirect to `/login?redirect=...&expired=1`.
- **Library & EPUB Reader (Web & Android):** Uploading EPUBs, rendering chapters via reader WebView/iframe, Table of Contents navigation, advancing & syncing reading progress (`epubcfi`), direct `#/reader/...` browser reload restoring the open book & saved position, Android restart progress restoration (`Continue Reading`), and saving Reader notes (`Add Note`).
- **Audiobooks on Android:** ID3 metadata + embedded PNG artwork extraction (`audio_metadata_reader`), multi-track import via `Pick Files`, play/pause/`-15s`/`+30s`, chapter switching & track rollover, continuous background audio playback (`KEYCODE_HOME`), `15 min` sleep timer countdown, bookmarking, listening progress (`29% completed`), and reboot persistence.
- **Android SAF Folder Registration:** Granting Storage Access Framework access on `Documents/Phase8Books` (`Active & Accessible • Scanned 1 books`).

### Open Platform Issues Tracked for Remediation
1. **Android Release Media Notification Controls:** `AudioService` raises `IllegalArgumentException: You must specify an icon resource id to build a CustomAction` in release builds (plus `POST_NOTIFICATIONS` is not declared in `AndroidManifest.xml`), keeping system media notifications from posting while background playback runs.
2. **Offline File Download (`Download for Offline`):** `BookDetailsScreen` currently passes `bookId` instead of `fileId` into `OfflineDownloadButton` (`HTTP 404` on `/api/v1/storage/files/{fileId}/download-url`); `LocalStorageService` returns a relative download path; Web `#/downloads` & Android 16 scoped `/storage/emulated/0/Download` scanning hit `dart:io` / scoped-storage limits.
3. **Web Audiobook Import & Android Audio `Scan Folder`:** `AudiobookImportService` accesses `dart:io` `File`/`Directory`, causing `Unsupported operation: _Namespace` when picking MP3s on Web and `"No supported audio files found"` for SAF folders on Android 16.
4. **Reader `Add Bookmark` & `Discover Books` Scan List UI:** Reader toolbar `Add Bookmark` did not populate ToC `Bookmarks (0)` on Android; `DiscoverBooksScreen` updated the folder card count (`Scanned 1 books`) without updating the main results list.
5. **Google OAuth & Concurrent Reading-Progress Race:** Live Google Sign-In requires Google Cloud Console origin/SHA-1 configuration; simultaneous initial reading-progress PUTs can race on `uq_user_book_file`; Android compact UI has minor spacing overlap on `Add Bookmark` chips, Reader AppBar badge, and Onboarding slide CTA offset.

---

## 12. Engineering Documentation Library

| Category | Document | Description |
|---|---|---|
| **Architecture** | [`SYSTEM_ARCHITECTURE.md`](docs/architecture/SYSTEM_ARCHITECTURE.md) | Multi-tier architecture & data flows |
| **Architecture** | [`DATABASE_SCHEMA.md`](docs/architecture/DATABASE_SCHEMA.md) | Relational schema & Flyway overview |
| **Architecture** | [`API_ARCHITECTURE.md`](docs/architecture/API_ARCHITECTURE.md) | REST conventions, JWT lifecycle & endpoints |
| **Architecture** | [`OFFLINE_SYNC_ARCHITECTURE.md`](docs/architecture/OFFLINE_SYNC_ARCHITECTURE.md) | Cursor delta sync, outbox & conflict rules |
| **Setup** | [`DEVELOPMENT_SETUP.md`](docs/setup/DEVELOPMENT_SETUP.md) | Full-stack local development setup |
| **Setup** | [`BACKEND_SETUP.md`](docs/setup/BACKEND_SETUP.md) | Java 25, Maven & Spring Boot guide |
| **Setup** | [`FRONTEND_SETUP.md`](docs/setup/FRONTEND_SETUP.md) | Flutter Web, Android, iOS & Windows setup |
| **Setup** | [`GOOGLE_SIGN_IN_SETUP.md`](docs/GOOGLE_SIGN_IN_SETUP.md) | Google OAuth client configuration guide |
| **Setup** | [`AWS_SETUP.md`](docs/setup/AWS_SETUP.md) | AWS S3, RDS & ECS configuration |
| **Testing** | [`TEST_STRATEGY.md`](docs/testing/TEST_STRATEGY.md) | Testing pyramid & security isolation tests |
| **Testing** | [`API_TESTING.md`](docs/testing/API_TESTING.md) | cURL reference across backend APIs |
| **Testing** | [`END_TO_END_TESTING.md`](docs/testing/END_TO_END_TESTING.md) | End-to-end verification flows |
| **Operations** | [`PRODUCTION_DEPLOYMENT.md`](docs/deployment/PRODUCTION_DEPLOYMENT.md) | Production deployment runbook |
| **Operations** | [`ENVIRONMENT_VARIABLES.md`](docs/deployment/ENVIRONMENT_VARIABLES.md) | Environment variable reference |
| **Operations** | [`DATABASE_BACKUP.md`](docs/deployment/DATABASE_BACKUP.md) | PostgreSQL backup & recovery |
| **Operations** | [`ROLLBACK_GUIDE.md`](docs/deployment/ROLLBACK_GUIDE.md) | Release rollback procedures |
| **Backlog & Guides** | [`Features.md`](Features.md) · [`BOOK.md`](BOOK.md) · [`AUDIO.md`](AUDIO.md) | Master 99-feature plan, ebook & audiobook guides |

---

**Tagline:** *Your books. Your thoughts. Your sanctuary.*  
**Repository:** https://github.com/AnishaPaturi/reading-app

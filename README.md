# 📚 Reading Sanctuary
### Your Personal Digital Reading Ecosystem

**Read. Listen. Annotate. Organize. Remember.**

Reading Sanctuary is a cross-platform personal reading application designed to bring an entire reading life into one organized, customizable and private digital space.

It combines an ebook reader, audiobook player, digital bookshelf, reading tracker, annotation system and personal reading journal into a unified platform.

Instead of switching between multiple applications to read books, listen to audiobooks, track reading progress, save quotes, write notes and organize a personal library, users can manage everything through Reading Sanctuary.

The goal is to recreate the comfort and organization of a personal library while providing the flexibility and accessibility of modern digital technology.

---

# 1. Project Overview

| Attribute | Details |
|---|---|
| Project Name | Reading Sanctuary |
| Project Type | Cross-platform Reading Management Application |
| Domain | Application Development / Digital Reading |
| Frontend | Flutter & Dart |
| Backend | Java & Spring Boot |
| Database | PostgreSQL |
| Local Database | SQLite (mobile) |
| Database Migration | Flyway |
| API Architecture | REST APIs |
| Authentication | Spring Security |
| File Storage | Private cloud object storage (AWS S3 planned) |
| API Documentation | Swagger / OpenAPI |
| Version Control | Git & GitHub |
| Containerization | Docker |
| Development IDE | VS Code |
| Target Platforms | Android, iOS and Web |

## 2. The Problem Statement

Readers often use multiple applications to manage different aspects of their reading experience.

For example:

- One application for reading PDFs and EPUBs.
- Another application for listening to audiobooks.
- Separate applications for tracking reading progress.
- Notes applications for saving quotes and thoughts.
- Spreadsheets or journals for maintaining reading lists.
- Cloud storage applications for organizing book files.

This creates a fragmented reading experience.

Readers also struggle to maintain a centralized record of their reading history, annotations, unfinished books, personal ratings and reading progress.

**Reading Sanctuary addresses this problem by providing one centralized platform for managing the complete digital reading experience.**

## 3. Project Vision

The vision is to build a personal digital library where users can:

- Maintain their entire digital book collection.
- Read ebooks in a comfortable reading environment.
- Listen to audiobooks.
- Convert supported ebook text into speech.
- Organize books into personalized bookshelves.
- Track reading progress and maintain reading history.
- Highlight important passages and attach notes.
- Maintain personal reading journals.
- Save memorable quotes.
- Track books they want to read.
- Access their library across multiple devices.
- Continue reading offline and synchronize changes when internet connectivity returns.

The application will prioritize:

1. Reading experience.
2. User privacy and data ownership.
3. Personalization and customization.
4. Reliable offline access.
5. Seamless synchronization.
6. Long-term preservation of reading history.

---

# 4. Core Features

## 4.1 User Authentication and Profiles

- User registration and login.
- Secure password storage.
- Individual user accounts.
- Profile customization.
- User preferences and reading settings.
- Multi-device account access.
- Private library by default.

## 4.2 Personal Digital Library

Users can maintain a centralized collection of digital books.

Supported ebook formats:

- PDF
- EPUB
- DOCX

Supported audiobook formats:

- MP3
- M4B

Features:

- Upload books directly into the library.
- Automatically create a book entry when a book is uploaded.
- Extract available book metadata.
- Automatically extract the book cover where possible.
- Allow users to upload or replace covers manually.
- Maintain multiple formats of the same book under one book entry.
- Store author, title, genre and description.
- Add personal descriptions and extra information.
- Rate books.
- Maintain reading status.
- Search and filter the library.

**Important design principle:** A book and its uploaded files are separate entities. One book can have multiple ebook and audiobook files without creating duplicate book entries.

## 4.3 Custom Digital Bookshelves

Users can organize their library through customizable bookshelves.

Features:

- Create multiple bookshelves.
- Customize bookshelf appearance.
- Create personal collections.
- Organize books by author, genre or reading status.
- Create nested folders.
- Assign multiple collections to the same book.
- Add custom tags.
- Move books between collections.
- Search within collections.

The visual design will follow a dark academia and cozy library aesthetic.

## 4.4 Ebook Reader

An integrated ebook reading experience supporting:

- PDF reading.
- EPUB reading.
- DOCX reading.
- Reading progress preservation.
- Bookmarks.
- Adjustable reading settings.
- Reading themes.
- Font and text customization where supported.
- Full-screen reading.
- Page navigation.
- Resume reading from the last saved position.

## 4.5 Audiobook Player

An integrated audiobook listening experience.

Features:

- MP3 playback.
- M4B playback.
- Play, pause and resume.
- Playback speed controls.
- Seek forward and backward.
- Audio progress tracking.
- Resume playback from the previous position.
- Chapter navigation for supported M4B files.
- Background audio playback.
- Lock-screen media controls.

## 4.6 Text-to-Speech (TTS)

When an audiobook is unavailable, users can listen to supported ebook content through text-to-speech.

Features:

- Voice playback of ebook text.
- Play and pause controls.
- Adjustable speech speed.
- Voice selection.
- Resume listening.
- Device-native TTS voices.
- Optional cloud-based voices in future releases.

The application will prioritize native device voices initially to reduce infrastructure costs.

Scanned PDFs may require OCR before their text can be used for speech.

## 4.7 Highlights and Annotations

Users can interact with the content of their books.

Features:

- Highlight selected text.
- Multiple highlight colors.
- Add notes to individual highlights.
- Edit or delete annotations.
- View all annotations associated with a book.
- Navigate back to the original highlighted passage.
- Maintain annotations across reading sessions.

Annotations will preserve format-specific location information so that the application can identify the original passage.

## 4.8 Personal Reading Journal

A dedicated space for recording personal reading experiences.

Features:

- Add personal notes to books.
- Write reading reflections.
- Save memorable quotes.
- Add personal reviews.
- Record thoughts and interpretations.
- Maintain a journal independently of book highlights.

## 4.9 Reading Tracker

Users can track their reading journey.

Features:

- Record reading start dates.
- Record completion dates.
- Maintain reading status.
- Track reading progress.
- Track multiple currently-reading books.
- Maintain reading history.
- Track rereading sessions.
- Rate completed books.

Reading statuses:

- Want to Read (TBR)
- Currently Reading
- Completed
- Did Not Finish (DNF)
- On Hold

DNF books will remain in the user's library. Their reading history, notes, annotations and progress will not be deleted.

## 4.10 Offline Access and Cloud Synchronization

Reading Sanctuary will follow an offline-first approach.

Features:

- Download books for offline access.
- Read previously downloaded books without internet.
- Store reading progress locally.
- Store annotations and notes locally.
- Synchronize changes when connectivity returns.
- Support multiple devices.
- Handle synchronization conflicts.
- Maintain reliable user data across devices.

Cloud synchronization will be automatic whenever an internet connection is available.

## 4.11 Reading Statistics and Goals

Planned features:

- Daily reading time.
- Weekly and monthly reading activity.
- Books completed.
- Books currently being read.
- Reading streaks.
- Reading goals.
- Yearly reading summaries.
- Genre-based reading statistics.
- Reading history visualization.

---

# 5. Functional Requirements

| Module | Main Responsibility |
|---|---|
| Authentication | Registration, login and account security |
| User Management | User profiles and preferences |
| Book Management | Book metadata and library records |
| File Management | Ebook and audiobook uploads |
| Bookshelf Management | Personalized shelves and collections |
| Reader | PDF, EPUB and DOCX reading |
| Audiobook | Audio playback and chapter management |
| TTS | Text-to-speech functionality |
| Annotation | Highlights and notes |
| Journal | Personal notes, reviews and quotes |
| Reading Tracker | Reading status and progress |
| Synchronization | Offline-first synchronization |
| Statistics | Reading analytics and goals |

---

# 6. Technology Stack

## Frontend

### Flutter
The application frontend will be developed using Flutter.

Reasons for choosing Flutter:

- Single codebase for Android, iOS and Web.
- Consistent UI across platforms.
- Customizable user interface.
- Responsive layouts.
- Strong ecosystem of packages.
- Native platform integration.

### Dart
Used as the primary programming language for the Flutter application.

Frontend responsibilities:

- User interface.
- Navigation.
- State management.
- API communication.
- Local data management.
- File selection and uploads.
- Ebook reading interface.
- Audio playback.
- Offline functionality.

## Backend

### Java 25

Java will be the primary backend programming language.

### Spring Boot 3.5.x

Spring Boot will provide the backend application framework.

Backend responsibilities:

- Authentication and authorization.
- User management.
- Book management.
- File management.
- Reading progress management.
- Collection management.
- Annotation and journal APIs.
- Cloud storage integration.
- Synchronization logic.

### Spring Security

Used for:

- Authentication.
- Authorization.
- Password security.
- Protected REST endpoints.
- Role and ownership-based access control.

### Spring Data JPA / Hibernate

Used for database access and object-relational mapping.

### Maven

Used for dependency management and backend builds.

## Database

### PostgreSQL

Primary relational database.

Used to store:

- User accounts.
- User profiles.
- Book metadata.
- Author information.
- Book formats and file references.
- Collections and tags.
- Reading progress.
- Reading history.
- Bookmarks.
- Annotations.
- Journal entries.
- Reviews and quotes.
- Synchronization metadata.

### SQLite

Planned local database for mobile devices.

Used for offline data storage and local synchronization queues.

### Flyway

Used for database version control and migrations.

Every database schema change will be maintained as a versioned SQL migration.

## Cloud and File Storage

### AWS S3 (planned)

Private object storage for uploaded ebooks, audiobooks and cover images.

Files will not be publicly accessible by default.

The initial development phase will use local storage or a compatible development storage solution before cloud deployment.

## API Documentation

### Swagger / OpenAPI

Used to document and test backend REST APIs.

## Development and Infrastructure

| Technology | Purpose |
|---|---|
| Git | Version control |
| GitHub | Source code repository |
| Docker | Containerization |
| VS Code | Development environment |
| Android Studio | Android SDK and emulator |
| Postman / Thunder Client | API testing |
| pgAdmin 4 | PostgreSQL administration |
| Maven | Backend build management |
| Flyway | Database migrations |

---

# 7. System Architecture

Reading Sanctuary will initially follow a **modular monolithic architecture**.

This approach keeps the application manageable while separating responsibilities into independent backend modules.

Microservices are intentionally avoided in the initial development phase to reduce deployment complexity and infrastructure overhead.

### High-Level Architecture

```text
                 READING SANCTUARY
                         |
             +-----------+-----------+
             |                       |
       Flutter Web             Flutter Mobile
             |                       |
             +-----------+-----------+
                         |
                    HTTPS / REST
                         |
                SPRING BOOT BACKEND
                         |
       +-----------------+------------------+
       |                 |                  |
   Auth Module       Book Module       Reading Module
       |                 |                  |
       +-----------------+------------------+
                         |
                  SERVICE LAYER
                         |
                REPOSITORY LAYER
                         |
                    PostgreSQL
                         |
          +--------------+--------------+
          |                             |
    Flyway Migrations             Data Records
          |
          +-------------------------------+

Additional integrations:

Spring Boot --> Private Object Storage (AWS S3)
Flutter --> Local Database (SQLite on mobile)
Flutter --> Device TTS / Audio Services
Flutter <--> Backend Synchronization APIs
```

### Architectural Principles

- Modular monolithic backend.
- REST-based frontend/backend communication.
- Separation of controller, service and repository layers.
- Secure file access.
- User-level data isolation.
- Offline-first mobile architecture.
- Version-controlled database migrations.
- Centralized error handling.
- API validation.
- Consistent response formats.
- Secure authentication and authorization.

---

# 8. Database Design

The database will use PostgreSQL with UUID primary keys and relational constraints.

The design separates book records from their physical or digital files.

A single book can have multiple file formats, editions and associated audio files.

## Planned Database Tables

### A. User Management

1. users
2. user_profiles
3. user_preferences
4. user_devices
5. user_tts_preferences

### B. Book Management

6. books
7. authors
8. book_authors
9. genres
10. book_genres
11. book_files
12. book_covers
13. audio_chapters

### C. Organization

14. collections
15. collection_books
16. tags
17. book_tags

### D. Reading Management

18. reading_cycles
19. reading_progress
20. reading_sessions
21. bookmarks
22. reading_goals

### E. Journal and Annotations

23. annotations
24. annotation_comments
25. book_notes
26. book_reviews
27. favorite_quotes

### F. Synchronization and Privacy

28. sync_operations
29. device_downloads
30. book_shares
31. collection_shares

These are the planned logical tables. Their exact columns, relationships and constraints will be finalized during database implementation.

## Important Database Design Decisions

1. A book record is independent of its uploaded files.
2. One book can have multiple ebook and audiobook files.
3. A book can belong to multiple collections.
4. A user can maintain multiple active reading cycles.
5. Rereading a book creates a new reading cycle.
6. DNF does not delete a book or its history.
7. Annotations are associated with the relevant book and file.
8. Reading progress is maintained for the relevant file and reading cycle.
9. User data must be isolated between accounts.
10. Synchronization operations must be idempotent to avoid duplicate changes.

---

# 9. Repository Folder Structure

The project will follow a monorepo structure so that frontend, backend, database scripts, infrastructure and documentation remain together.

```text
reading-app/
│
├── frontend/
│   └── reading_sanctuary_app/
│       │
│       ├── android/
│       ├── ios/
│       ├── web/
│       ├── test/
│       │
│       ├── assets/
│       │   ├── images/
│       │   ├── icons/
│       │   ├── fonts/
│       │   └── animations/
│       │
│       ├── lib/
│       │   │
│       │   ├── main.dart
│       │   │
│       │   ├── app/
│       │   │   ├── app.dart
│       │   │   ├── router.dart
│       │   │   └── theme/
│       │   │       ├── app_theme.dart
│       │   │       ├── colors.dart
│       │   │       └── typography.dart
│       │   │
│       │   ├── core/
│       │   │   ├── constants/
│       │   │   ├── errors/
│       │   │   ├── network/
│       │   │   ├── storage/
│       │   │   ├── utils/
│       │   │   └── widgets/
│       │   │
│       │   ├── features/
│       │   │   │
│       │   │   ├── authentication/
│       │   │   │   ├── data/
│       │   │   │   ├── domain/
│       │   │   │   └── presentation/
│       │   │   │
│       │   │   ├── home/
│       │   │   ├── library/
│       │   │   ├── bookshelf/
│       │   │   ├── book_details/
│       │   │   ├── ebook_reader/
│       │   │   ├── audiobook_player/
│       │   │   ├── annotations/
│       │   │   ├── journal/
│       │   │   ├── reading_tracker/
│       │   │   ├── collections/
│       │   │   ├── search/
│       │   │   ├── statistics/
│       │   │   └── settings/
│       │   │
│       │   └── shared/
│       │       ├── models/
│       │       ├── services/
│       │       └── components/
│       │
│       └── pubspec.yaml
│
├── backend/
│   └── reading-sanctuary-api/
│       │
│       ├── src/
│       │   ├── main/
│       │   │   ├── java/
│       │   │   │   └── com/readingsanctuary/
│       │   │   │       │
│       │   │   │       ├── ReadingSanctuaryApplication.java
│       │   │   │       │
│       │   │   │       ├── config/
│       │   │   │       ├── security/
│       │   │   │       ├── common/
│       │   │   │       │
│       │   │   │       ├── auth/
│       │   │   │       ├── user/
│       │   │   │       ├── book/
│       │   │   │       ├── file/
│       │   │   │       ├── author/
│       │   │   │       ├── collection/
│       │   │   │       ├── bookshelf/
│       │   │   │       ├── reading/
│       │   │   │       ├── annotation/
│       │   │   │       ├── journal/
│       │   │   │       ├── audiobook/
│       │   │   │       ├── statistics/
│       │   │   │       └── sync/
│       │   │   │
│       │   │   └── resources/
│       │   │       ├── application.yml
│       │   │       └── db/
│       │   │           └── migration/
│       │   │
│       │   └── test/
│       │       └── java/
│       │
│       └── pom.xml
│
├── database/
│   ├── migrations/
│   ├── seeds/
│   ├── diagrams/
│   └── documentation/
│
├── infrastructure/
│   ├── docker/
│   ├── deployment/
│   └── scripts/
│
├── docs/
│   ├── PRD.md
│   ├── DATABASE_DESIGN.md
│   ├── API_SPECIFICATION.md
│   ├── SYSTEM_ARCHITECTURE.md
│   ├── IMPLEMENTATION_PLAN.md
│   └── CONTRIBUTING.md
│
├── .gitignore
├── README.md
└── LICENSE
```

The folder structure represents the intended architecture. Directories will be created progressively as their corresponding modules are implemented.

---

# 10. API Design

The backend will expose REST APIs using JSON.

Planned API groups:

| API Group | Example Endpoints |
|---|---|
| Authentication | `/api/v1/auth/register`, `/api/v1/auth/login` |
| Users | `/api/v1/users/me` |
| Books | `/api/v1/books` |
| Files | `/api/v1/books/{bookId}/files` |
| Collections | `/api/v1/collections` |
| Reading | `/api/v1/reading/progress` |
| Bookmarks | `/api/v1/bookmarks` |
| Annotations | `/api/v1/annotations` |
| Journal | `/api/v1/notes` |
| Reviews | `/api/v1/reviews` |
| Audiobooks | `/api/v1/audiobooks` |
| Synchronization | `/api/v1/sync` |
| Statistics | `/api/v1/statistics` |

All protected endpoints will enforce authentication and user-level authorization.

API versioning will use `/api/v1/`.

---

# 11. Implementation Roadmap

Development will be divided into phases to ensure that the foundation is stable before advanced features are introduced.

## Phase 1 — Environment and Project Initialization

- Install and configure Flutter.
- Configure Android Studio and Android SDK.
- Install and configure PostgreSQL.
- Configure Java and Maven.
- Create GitHub repository.
- Initialize Flutter project.
- Initialize Spring Boot project.
- Configure the monorepo.
- Configure Git and `.gitignore`.

**Deliverable:** A working frontend and backend project structure.

## Phase 2 — Backend Foundation and Database

- Configure PostgreSQL connection.
- Configure Spring Data JPA.
- Configure Flyway.
- Design the complete ER diagram.
- Create database migrations.
- Implement initial entities.
- Create repositories.
- Create service and controller layers.
- Implement centralized exception handling.
- Configure Swagger.
- Create health-check endpoint.

**Deliverable:** A functioning backend connected to PostgreSQL.

## Phase 3 — Authentication and User Management

- Registration.
- Login.
- Password hashing.
- Authentication and authorization.
- User profiles.
- User preferences.
- Protected API endpoints.

**Deliverable:** Users can create accounts and securely access their personal library.

## Phase 4 — Personal Library and File Management

- Upload PDF, EPUB and DOCX.
- Extract metadata where available.
- Extract book covers.
- Add manual metadata editing.
- Support multiple files per book.
- Store file references securely.
- Detect possible duplicate uploads.
- Create book entries automatically.

**Deliverable:** Users can upload and manage their personal digital libraries.

## Phase 5 — Bookshelf and Organization

- Create bookshelves.
- Create collections.
- Create nested folders.
- Add tags.
- Organize books.
- Search and filter books.
- Customize bookshelf appearance.

**Deliverable:** A functional personal digital bookshelf.

## Phase 6 — Ebook Reader

- PDF reader.
- EPUB reader.
- DOCX reader.
- Reading progress.
- Bookmarks.
- Resume reading.
- Reader customization.
- Basic reading settings.

**Deliverable:** Users can read supported ebook formats inside the application.

## Phase 7 — Reading Tracker

- Reading status management.
- TBR list.
- Start and completion dates.
- DNF functionality.
- Book ratings.
- Reading history.
- Multiple active reading cycles.
- Rereading support.

**Deliverable:** A complete personal reading tracker.

## Phase 8 — Annotations and Journal

- Text highlighting.
- Multiple highlight colors.
- Notes attached to highlights.
- Personal book notes.
- Favorite quotes.
- Reviews.
- Reading journal.

**Deliverable:** Users can preserve their thoughts and important passages.

## Phase 9 — Audiobooks and TTS

- MP3 playback.
- M4B playback.
- Playback controls.
- Audio progress tracking.
- Chapter navigation.
- Background playback.
- Device-native text-to-speech.
- Voice preferences.

**Deliverable:** Integrated audiobook and text-to-speech experience.

## Phase 10 — Offline Access and Synchronization

- Local database.
- Offline book access.
- Local reading progress.
- Local annotations.
- Synchronization queue.
- Automatic synchronization.
- Conflict resolution.
- Multi-device synchronization.

**Deliverable:** A reliable offline-first reading ecosystem.

## Phase 11 — Statistics and Personalization

- Reading statistics.
- Reading goals.
- Reading streaks.
- Activity summaries.
- Custom themes.
- Advanced bookshelf customization.

**Deliverable:** A personalized reading dashboard.

## Phase 12 — Testing and Deployment

- Unit testing.
- Integration testing.
- API testing.
- UI testing.
- Security testing.
- Performance testing.
- Docker configuration.
- Backend deployment.
- Cloud storage integration.
- Web deployment.
- Android release build.
- iOS release build.

**Deliverable:** A production-ready application with deployment and publishing workflows.

---

# 12. Minimum Viable Product (MVP)

The first release will focus on the essential reading and library experience.

### Included in MVP

- User registration and login.
- Personal library.
- PDF, EPUB and DOCX uploads.
- Multiple formats under one book entry.
- Automatic book entry creation.
- Basic metadata extraction.
- Personalized bookshelves.
- Collections and folders.
- Ebook reading.
- Reading progress preservation.
- Bookmarks and basic notes.
- TBR list.
- Reading statuses.
- Start and completion dates.
- Book ratings.
- PostgreSQL persistence.
- Basic cloud file storage.
- Initial offline reading support.

### Features for Later Releases

- Advanced annotation system.
- Full audiobook player.
- Text-to-speech.
- Advanced reading journal.
- Reading analytics.
- Reading goals.
- Multi-device synchronization.
- Advanced offline conflict resolution.
- Optional sharing.
- Cloud-based TTS voices.

### Explicitly Out of Scope for Initial Releases

- Book purchasing.
- E-commerce functionality.
- Public social media feed.
- Collaborative annotations.
- AI-generated book summaries.
- AI book recommendations.
- Public author profiles.

---

# 13. Security and Privacy

Privacy is a fundamental part of Reading Sanctuary.

Planned security measures:

- Secure password hashing.
- Authentication for protected resources.
- Authorization based on resource ownership.
- Private file storage.
- Secure file access.
- Input validation.
- File type and file size validation.
- Protection against unauthorized access.
- HTTPS communication.
- Secure token management.
- Database access restrictions.
- Backup and recovery mechanisms.

All libraries will be private by default.

Users may receive optional sharing capabilities in future releases.

Users should retain control over their personal reading data and uploaded content.

---

# 14. Testing Strategy

Testing will be performed throughout development.

### Backend Testing

- JUnit 5.
- Mockito.
- Spring Boot Test.
- Repository tests.
- Service tests.
- Controller integration tests.
- Database integration tests.

### Frontend Testing

- Flutter unit tests.
- Widget tests.
- Integration tests.
- Responsive UI tests.

### API Testing

- Swagger UI.
- Postman.
- Thunder Client.

### Database Testing

- Migration validation.
- Referential integrity.
- Constraint validation.
- Transaction testing.
- Data ownership testing.

---

# 15. Deployment Strategy

The deployment architecture will be finalized after local development and testing.

Planned deployment components:

| Component | Technology |
|---|---|
| Web frontend | Flutter Web hosting |
| Android application | Google Play Store |
| iOS application | Apple App Store |
| Backend | Spring Boot deployment |
| Database | Managed PostgreSQL |
| File storage | Private AWS S3 |
| Containerization | Docker |
| Version control | GitHub |
| API documentation | Swagger/OpenAPI |

Development will initially happen locally.

Cloud infrastructure will be introduced incrementally rather than creating unnecessary infrastructure costs at the beginning.

**Platform note:** Android and web development can be performed on Windows. Building and publishing the iOS application requires macOS and Xcode.

---

# 16. Development Principles

The following principles will guide implementation:

1. Build a stable foundation before advanced features.
2. Maintain clean separation between frontend, backend and database.
3. Avoid unnecessary microservices.
4. Use modular and reusable code.
5. Maintain version-controlled SQL migrations.
6. Implement proper validation and exception handling.
7. Never silently discard user data.
8. Preserve reading history even when a book is marked DNF.
9. Design offline support into the architecture early.
10. Prioritize data integrity and security.
11. Write tests for critical functionality.
12. Document APIs and architectural decisions.
13. Keep the application responsive across screen sizes.
14. Avoid unnecessary infrastructure and operational costs.

---

# 17. Current Development Status

**Project stage: Initial Environment Setup**

| Component | Current Status |
|---|---|
| Flutter SDK | Installed |
| Dart SDK | Installed |
| Android Studio | Installed |
| Android SDK | Configured |
| Android licenses | Accepted |
| Java 25 | Installed |
| Maven 3.9.15 | Installed |
| Git | Installed |
| PostgreSQL 18 | Installed and running |
| pgAdmin 4 | Installed and connected |
| GitHub repository | Created |
| Flutter frontend | To be initialized |
| Spring Boot backend | To be initialized |
| Database schema | Pending |
| API implementation | Pending |

Repository: https://github.com/AnishaPaturi/reading-app

---

# 18. Expected Final Outcome

Reading Sanctuary aims to become a complete personal digital reading ecosystem.

A user should be able to:

1. Create an account.
2. Upload their books.
3. Organize books into personalized bookshelves.
4. Open and read ebooks.
5. Listen to audiobooks.
6. Use text-to-speech when an audiobook is unavailable.
7. Highlight important passages.
8. Attach notes to highlights.
9. Maintain a personal reading journal.
10. Track reading progress and history.
11. Manage TBR and DNF books.
12. Access their library offline.
13. Synchronize their reading activity across devices.
14. View their personal reading statistics.

The ultimate goal is simple:

**A personal sanctuary for everything a reader reads, listens to, highlights, remembers and loves.**

---

# 19. Project Repository

GitHub: https://github.com/AnishaPaturi/reading-app

**Project Name:** Reading Sanctuary

**Tagline:** Your books. Your thoughts. Your sanctuary.

---

# 20. Running the Frontend

To run the Flutter frontend, follow the steps below:

### Step 1: Open the Frontend Directory

Open your terminal and navigate to the Flutter project folder:

```powershell
cd frontend\reading_sanctuary_app
```

### Step 2: Choose Your Target Device

#### Option A: Run in the Web Browser (Fastest / Recommended for Development)

Your system already has Google Chrome and Microsoft Edge detected.

Run on Google Chrome:

```powershell
flutter run -d chrome
```

Run on Microsoft Edge:

```powershell
flutter run -d edge
```

#### Option B: Run on an Android Emulator

You have two configured Android Virtual Devices (`Medium_Phone_API_36.1` and `Pixel_5`):

1. Launch the emulator:
   ```powershell
   flutter emulators --launch Pixel_5
   ```
   *(or launch `Medium_Phone_API_36.1`)*

2. Run the app:
   ```powershell
   flutter run
   ```

#### Option C: Run on Windows Desktop

To run natively as a Windows desktop application:

1. Ensure Developer Mode is turned on in Windows Settings (run `start ms-settings:developers`).
2. Run:
   ```powershell
   flutter run -d windows
   ```

### Useful Commands

| Task | Command |
|---|---|
| Run unit & widget tests | `flutter test` |
| Check for lint or code issues | `flutter analyze` |
| Check connected devices | `flutter devices` |
| Hot reload during active run | Press `r` in the terminal |
| Hot restart during active run | Press `R` in the terminal |
| Stop running app | Press `q` in the terminal |

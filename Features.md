Yes — the calendar you described should be a **proper Reading Calendar**, not just a streak counter or a row of dates.

It will look like a real monthly calendar:

- Each day is a separate date cell, arranged Monday–Sunday (with the correct month layout).
- **Green indicator:** the user read that day and completed their daily reading target.
- **Red indicator:** the user did not read that day.
- **Today:** clearly highlighted.
- **Future dates:** neutral; they must not be marked as missed.
- Tapping a date shows that day's reading activity, such as pages read and books read.
- Month navigation lets users move between previous and current months.

I'll include this as an additional feature in the implementation, alongside the existing streak calendar. They serve different purposes: the calendar shows the full reading history; the streak tracks consecutive successful days.

One important thing I found in the repository documentation: the root README describes later milestones as completed, but the frontend README still describes the app as **Milestone 1**, with Bookshelves, Reader, Audiobooks, Journal and Statistics listed as placeholders. So I don't want to give you steps that accidentally overwrite functionality you have already built.

I'll structure the work around the 89-item backlog in seven modules: Dashboard and calendar, Library, Bookshelf views, Statistics, automatic shelves, book resizing, and Book Details. The calendar will be an additional item in the dashboard/tracking module.

# **Complete implementation plan — all 89 missing features + Reading Calendar**

I would implement these in **10 phases**, in the order below. This is important because several features depend on the same data.

For example, the reading calendar, streaks, reading momentum, weekly activity and reading statistics should all use the same reading-session records. We should not build five separate systems that calculate the same information differently.

## **1. Before changing anything: protect the existing project**

Your project is:

- Frontend: Flutter + Dart
- State management: Riverpod
- Navigation: GoRouter
- Backend: Java + Spring Boot
- Database: PostgreSQL
- Migrations: Flyway
- Local/offline storage: SQLite

The repository documentation describes an existing backend architecture with analytics, reading goals, sync and storage modules. However, the frontend README still describes Milestone 1 and placeholder screens. The current Book Details source also contains more functionality than that older README suggests.

So, **do not assume every item in the previous 89-feature list is still missing in your latest working copy.** Check each feature against your current code before creating it again.

Useful project references:

- [Reading Sanctuary GitHub repository](https://github.com/AnishaPaturi/reading-app?utm_source=chatgpt.com)
- [Database schema documentation](https://github.com/AnishaPaturi/reading-app/blob/main/docs/architecture/DATABASE_SCHEMA.md?utm_source=chatgpt.com)
- [API architecture documentation](https://github.com/AnishaPaturi/reading-app/blob/main/docs/architecture/API_ARCHITECTURE.md?utm_source=chatgpt.com)
- [Offline synchronization documentation](https://github.com/AnishaPaturi/reading-app/blob/main/docs/architecture/OFFLINE_SYNC_ARCHITECTURE.md?utm_source=chatgpt.com)

### **Step 1.1 — Create a separate implementation branch**

Open your project terminal:

```
git checkout main
git pull origin main
git checkout -b feature/reading-dashboard-and-library-enhancements
```

Keep your current `main` branch untouched until the features have been tested.

### **Step 1.2 — Verify the project**

Frontend:

```
cd frontend/reading_sanctuary_app
flutter pub get
flutter analyze
flutter test
```

Backend:

```
cd backend/reading-sanctuary-api
./mvnw clean test
```

On Windows, use:

```
.\mvnw.cmd clean test
```

Save the test results. If something is already failing, you need to know that before introducing new changes.

# **2. Build the shared data foundation**

Phase 1 — Database and backend foundation

This phase supports almost every feature in the list.

The biggest mistake would be to implement all the UI first and then discover that the backend cannot save the information.

## **Step 2.1 — Expand the book data model**

Your existing book model needs to support the additional metadata required by the video.

The following fields should be available for a book:

| Field               | Purpose                           |
| ------------------- | --------------------------------- |
| `title`             | Book title                        |
| `author`            | Author name                       |
| `genre`             | Main genre                        |
| `description`       | Book description                  |
| `publisher`         | Publisher                         |
| `isbn`              | ISBN                              |
| `totalPages`        | Total number of pages             |
| `currentPage`       | Current reading position          |
| `rating`            | Star rating                       |
| `ratingOutOf100`    | Numerical rating                  |
| `recommendation`    | Personal recommendation           |
| `spiceRating`       | Spice rating                      |
| `tropes`            | List of book tropes               |
| `mood`              | Book mood                         |
| `price`             | Purchase price                    |
| `currency`          | Purchase currency                 |
| `acquisitionMethod` | Purchased, borrowed, gifted, etc. |
| `purchaseDate`      | Purchase date                     |
| `startDate`         | Reading start date                |
| `completionDate`    | Reading completion date           |
| `format`            | Ebook, audiobook, etc.            |

Keep the existing multiple-file arrangement: one book can have several attached files.

For example, one book can have:

- EPUB
- PDF
- M4B
- MP3

These should remain attached to one book record instead of creating four duplicate books.

### **Step 2.2 — Update the Flutter model**

Open:

```
lib/shared/models/book.dart
```

Add the fields that do not already exist.

A simplified example:

```
class Book {
  final String id;
  final String title;
  final String author;
  final String? publisher;
  final String? isbn;
  final String? description;

  final int totalPages;
  final int currentPage;

  final double rating;
  final int? ratingOutOf100;

  final int? spiceRating;
  final List<String> tropes;
  final String? mood;
  final String? recommendation;

  final double? purchasePrice;
  final String? currency;
  final String? acquisitionMethod;

  final DateTime? purchaseDate;
  final DateTime? startDate;
  final DateTime? completionDate;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.publisher,
    this.isbn,
    this.description,
    this.totalPages = 0,
    this.currentPage = 0,
    this.rating = 0,
    this.ratingOutOf100,
    this.spiceRating,
    this.tropes = const [],
    this.mood,
    this.recommendation,
    this.purchasePrice,
    this.currency,
    this.acquisitionMethod,
    this.purchaseDate,
    this.startDate,
    this.completionDate,
  });
}
```

This is an example of the expanded model, not a replacement to paste blindly. Preserve your existing constructors, serialization, file references, status and progress fields.

Also update:

- `fromJson`
- `toJson`
- `copyWith`
- Equality and hash code, if implemented
- Local SQLite serialization
- API request and response DTOs

**Important:** Never store dates as formatted display strings such as `17 Nov 2026`. Store proper date or timestamp values and format them in Flutter.

## **Step 2.3 — Create a Flyway migration**

Your database documentation lists migrations through V9.

Create:

```
src/main/resources/db/migration/V10__reading_sanctuary_enhancements.sql
```

Add the new metadata columns to your existing books table, using the actual table and column names in your current schema.

For example:

```
ALTER TABLE books
    ADD COLUMN IF NOT EXISTS publisher VARCHAR(255),
    ADD COLUMN IF NOT EXISTS isbn VARCHAR(30),
    ADD COLUMN IF NOT EXISTS rating_out_of_100 INTEGER,
    ADD COLUMN IF NOT EXISTS spice_rating INTEGER,
    ADD COLUMN IF NOT EXISTS mood VARCHAR(100),
    ADD COLUMN IF NOT EXISTS recommendation VARCHAR(50),
    ADD COLUMN IF NOT EXISTS purchase_price NUMERIC(12, 2),
    ADD COLUMN IF NOT EXISTS currency VARCHAR(10),
    ADD COLUMN IF NOT EXISTS acquisition_method VARCHAR(50),
    ADD COLUMN IF NOT EXISTS purchase_date DATE,
    ADD COLUMN IF NOT EXISTS start_date DATE,
    ADD COLUMN IF NOT EXISTS completion_date DATE;
```

Add validation constraints after checking your existing data.

For example, rating out of 100 must be between 0 and 100.

Do not add duplicate columns if they already exist in your database.

## **Step 2.4 — Add a reading session system**

This is the most important part of the reading tracker.

A reading session represents one period of reading or listening.

Create a table similar to:

```
CREATE TABLE reading_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL REFERENCES users(id),
    book_id UUID NOT NULL REFERENCES books(id),

    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,

    duration_seconds INTEGER NOT NULL DEFAULT 0,
    pages_read INTEGER NOT NULL DEFAULT 0,

    session_type VARCHAR(20) NOT NULL DEFAULT 'READING',

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reading_sessions_user_started
ON reading_sessions(user_id, started_at);
```

The table must also follow your existing deletion, ownership and synchronization conventions.

Why do we need this?

Suppose a user reads:

| Time    | Book   | Pages |
| ------- | ------ | ----- |
| 8:00 AM | Book A | 15    |
| 2:00 PM | Book B | 20    |
| 9:00 PM | Book A | 10    |

The system should calculate:

- Total pages read: 45
- Number of books read: 2
- Reading sessions: 3
- Total reading duration: Sum of the three session durations

This data will power the calendar, dashboard, streaks and statistics.

## **Step 2.5 — Create the analytics service**

Create or expand the following backend components:

```
analytics/
├── controller/
│   └── AnalyticsController.java
├── service/
│   ├── AnalyticsService.java
│   ├── ReadingSessionService.java
│   ├── ReadingStreakService.java
│   └── ReadingCalendarService.java
├── repository/
│   ├── ReadingSessionRepository.java
│   └── ReadingGoalRepository.java
└── dto/
    ├── DashboardResponse.java
    ├── CalendarDayResponse.java
    └── ReadingStatisticsResponse.java
```

Use your existing package structure if these modules already exist.

The service layer should calculate the actual values. Flutter should display them, not independently invent the calculations.

## **Step 2.6 — Add or verify the API endpoints**

Your API documentation already describes an analytics domain. Extend it rather than creating a duplicate analytics API.

| Method | Endpoint                                | Purpose                 |
| ------ | --------------------------------------- | ----------------------- |
| POST   | `/api/analytics/sessions`               | Save a reading session  |
| GET    | `/api/analytics/dashboard`              | Dashboard data          |
| GET    | `/api/analytics/calendar?month=2026-11` | Calendar data           |
| GET    | `/api/analytics/streaks`                | Current and best streak |
| GET    | `/api/analytics/statistics`             | Reading statistics      |
| GET    | `/api/analytics/goals`                  | Reading goals           |
| POST   | `/api/analytics/goals`                  | Create or update a goal |

All endpoints must use the authenticated user ID. Never accept an arbitrary user ID from the Flutter client as proof of ownership.

# **3. Implement the Reading Calendar and Dashboard**

Phase 2 — Dashboard and reading tracker

This phase covers the first 21 dashboard features and adds your new calendar.

## **Step 3.1 — Create the Reading Calendar**

The calendar should be a dedicated visual component, not another statistic card.

Suggested file structure:

```
lib/features/calendar/
├── presentation/
│   ├── screens/
│   │   └── reading_calendar_screen.dart
│   └── widgets/
│       ├── calendar_header.dart
│       ├── calendar_grid.dart
│       ├── calendar_day_cell.dart
│       ├── calendar_legend.dart
│       └── selected_day_details.dart
├── application/
│   └── reading_calendar_controller.dart
└── data/
    └── reading_calendar_repository.dart
```

### **Step 3.1.1 — Design the calendar**

[Consistency Grid – Daily Planner & Tracker | The Visual Execution System - Payhip](https://images.openai.com/static-rsc-4/nUgeQR0c9Sgv0p0U5fC6jMg8nUbFlPog7mwEhFjuNbVtsWyffhtkhAvM_DK5kyRoVdrQbJkFarYXQwCnaKkE2Re9AX89wZ30vSLe47HY-dNc6tpXwTP7yQtSrCSU4gZCvX3vOSLHHgdfb_0cDS4PZjD_soWZlUDu-CllCI4GuvA?purpose=inline)

[Orbil | Cozy Book Tracker, Reading Journal, and Bookshelf App](https://images.openai.com/static-rsc-4/Ix3xZopn3g6QtrB0BzzymQA7JY0DbPpdP6SPIXKohHkQI4NE1Bapj0906oMdc_ngb-DtqiB5wk4EoqQtBrYwImv98DaySws1anDNYmJBTsllaYvzDHLXJobgfL24bKU-H4lp6lrc-N6xaILXcMoYJHw15yNQcw3xKmgrHH7ddew?purpose=inline)

[The Best Book Tracking App: Discover BOOKMORY](https://images.openai.com/static-rsc-4/3lQ8dvUSj3Kncq6ZtevAxPGYwvRfFGLJKxklSsMfIK5toZpo35I2IPVa6GgfjYarMlnpOB3Cm-C-fcpAtxqNCdVy6eXhlVjpq1SV0R2jDzLK4vQOesIPVxQpWrYph7kvYqUGzXZojV0SXmrfSpz4YIg-_0dtiIqPF-EFX21r1Ns?purpose=inline)

10

The calendar should contain:

1. Month and year.
2. Previous month arrow.
3. Next month arrow.
4. Seven weekday headings.
5. Correctly positioned dates.
6. Reading indicators.
7. Selected date details.
8. Monthly reading summary.
9. Legend explaining the colours.

### **Step 3.1.2 — Define the colour rules**

**Green — Read**

Reading recorded

**Red — Didn't read**

No reading recorded

**Grey — Future date**

Not yet applicable

**Gold outline — Today**

Current date

Use your existing theme colours where possible. These are suggested meanings, not a reason to introduce a completely different theme.

**One important rule:** A date should only turn red after it has passed. Future dates must never be counted as missed reading days.

I recommend that a day counts as "read" when the user has at least one valid reading or listening session recorded for that local date. You can separately show whether the daily reading goal was achieved.

### **Step 3.1.3 — Calculate the calendar layout**

For each month:

1. Determine the first date of the month.
2. Determine the weekday of that date.
3. Add blank cells before the first date.
4. Add all dates of the month.
5. Render the grid.
6. Match each date with its reading-session record.

In Flutter:

```
final firstDay = DateTime(year, month, 1);
final daysInMonth = DateTime(year, month + 1, 0).day;

// DateTime weekday: Monday = 1, Sunday = 7
final leadingEmptyCells = firstDay.weekday - 1;
```

Create a `GridView.builder` with seven columns.

Use the selected date to show the day's information below the calendar.

For example:

```
17 November 2026

Reading activity
----------------
Books read: 2
Pages read: 45
Reading time: 52 minutes

Book A — 25 pages
Book B — 20 pages
```

### **Step 3.1.4 — Connect the calendar to the backend**

The calendar API should return a structure similar to:

```
{
  "month": "2026-11",
  "days": [
    {
      "date": "2026-11-16",
      "hasRead": true,
      "pagesRead": 35,
      "minutesRead": 42
    },
    {
      "date": "2026-11-17",
      "hasRead": false,
      "pagesRead": 0,
      "minutesRead": 0
    }
  ]
}
```

The backend should return the full month's date information, including days without sessions, so the frontend can distinguish missed days from missing data.

The exact example above is illustrative. Your actual response should include the complete month and use the authenticated user's timezone when assigning sessions to dates.

### **Step 3.1.5 — Add month navigation**

When the user taps the left arrow:

- Load the previous month.
- Fetch that month's reading records.
- Update the calendar grid.
- Recalculate the monthly summary.

When the user taps the right arrow:

- Load the next month.
- Do not allow future dates to become missed days.

### **Step 3.1.6 — Add monthly summary**

Below the calendar:

- Days read.
- Days missed.
- Total reading time.
- Total pages read.
- Best reading streak during the month.

This completes your additional calendar feature.

## **Step 3.2 — Implement daily reading streaks**

Features covered:

- Daily reading streak.
- Current streak.
- Weekly streak calendar.
- Mark today complete.
- Streak freeze.
- Freeze availability.
- Personal best.

### **Backend logic**

Create a `ReadingStreakService`.

The service should:

1. Fetch the user's daily reading activity.
2. Convert timestamps into the user's local dates.
3. Identify consecutive reading days.
4. Calculate the current streak.
5. Calculate the longest historical streak.
6. Determine whether today is complete.
7. Apply a streak freeze if the user has one and the rules allow it.

Do not calculate streaks by counting sessions. Three sessions on one date still represent one successful reading day.

### **Streak freeze**

Create a table such as:

```
CREATE TABLE streak_freezes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    freeze_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE(user_id, freeze_date)
);
```

A freeze is a protected day, not a fake reading session.

Display:

- Current streak.
- Longest streak.
- Available freezes.
- Used freezes.
- Whether today is complete.

The user should not be able to use more freezes than they own.

## **Step 3.3 — Implement reading momentum**

This is a calculated dashboard statistic.

For example, use:

- Pages read during the last seven days.
- Reading minutes during the last seven days.
- Number of days with reading activity.

You can display a simple momentum indicator:

```
Reading Momentum

Strong
5 of the last 7 days active
```

Use a consistent calculation in the backend so that the same values appear on different devices.

## **Step 3.4 — Implement the Currently Reading section**

Features covered:

- Multiple currently-reading books.
- Navigation between books.
- Cover and title.
- Author and genre.
- Format.
- Progress slider.
- Current page increase/decrease.
- Total pages.
- Start date.
- Days spent reading.
- Average pages per day.
- Estimated days remaining.
- Expandable description.

Build a reusable widget:

```
features/home/presentation/widgets/
├── currently_reading_section.dart
├── currently_reading_card.dart
├── reading_progress_slider.dart
├── reading_page_controls.dart
└── reading_summary.dart
```

For multiple books, use a horizontal `PageView` or carousel.

For each book:

```
Book cover

Title
Author · Genre

Currently Reading

[---------- progress ----------]

Page 125 of 400

[ - ] 125 [ + ]

Started: 10 November 2026
Days spent: 7
Average: 18 pages/day
Estimated remaining: 16 days

[Read more]
```

### **Progress calculations**

```
Progress percentage =
(currentPage / totalPages) × 100
```

Average pages per day:

```
Pages read since starting / elapsed reading days
```

Estimated remaining days:

```
Remaining pages / average pages per day
```

If the average is zero, display "Not enough reading data" instead of dividing by zero.

For audiobooks, use the playback duration and total duration rather than page numbers.

### **Page controls**

The plus and minus buttons should:

1. Change the current page.
2. Validate the new value.
3. Update the progress bar.
4. Save the reading position.
5. Update the backend.
6. Queue the change for offline synchronization if the device is offline.

Do not allow the current page to go below zero or above the total page count.

# **4. Implement the Library enhancements**

Phase 3 — Library management

This phase covers the eight missing library features and the three partially implemented ones.

Create or expand:

```
lib/features/library/
├── presentation/
│   ├── screens/
│   │   └── library_screen.dart
│   └── widgets/
│       ├── library_toolbar.dart
│       ├── library_filters.dart
│       ├── library_sort_menu.dart
│       ├── library_search.dart
│       ├── advanced_filter_sheet.dart
│       └── book_grid_card.dart
├── application/
│   └── library_controller.dart
└── data/
    └── library_repository.dart
```

## **Step 4.1 — Implement Select / Import**

You already have book import functionality in your project history.

Verify that the library has a visible button:

```
+ Add Books
```

When tapped, it should open the device file picker.

The user should be able to:

- Select one file.
- Select multiple files.
- Import supported ebook formats.
- Import supported audiobook formats.
- Attach another format to an existing book.

If the selected file belongs to a book that already exists, provide a way to attach it to that book rather than automatically creating a duplicate.

## **Step 4.2 — Implement Scan Books**

There are two different possible scanning behaviours:

- Scanning a selected folder for supported files.
- Scanning physical book covers or spines using the camera.

For the digital-library feature, implement folder scanning first.

Flow:

1. User taps Scan Books.
2. User selects a folder where the platform supports folder access.
3. App scans supported extensions.
4. App reads available metadata.
5. App identifies possible duplicate books.
6. App shows a review screen.
7. User confirms which books to import.

Do not import files silently without allowing the user to review the results.

## **Step 4.3 — Implement advanced search**

Your existing search already supports title, author and genre according to the frontend documentation.

Expand it to search:

- Title.
- Author.
- Genre.
- Publisher.
- ISBN.
- Tropes.
- Collections.

Use debouncing so that the app does not send an API request on every keystroke.

For example, wait around 300 milliseconds after the user stops typing.

## **Step 4.4 — Implement sorting**

Add a sort dropdown:

```
Sort by

Recently Added
Title: A–Z
Title: Z–A
Author
Rating: Highest
Rating: Lowest
Recently Read
```

The sorting should work with the active filters.

## **Step 4.5 — Implement all filters**

Add the following filters:

| Filter         | Values                                                      |
| -------------- | ----------------------------------------------------------- |
| Reading status | Reading, TBR, Completed, On Hold, DNF                       |
| Book status    | Available, Archived, etc., according to your book lifecycle |
| Author         | Available authors                                           |
| Genre          | Available genres                                            |
| Format         | PDF, EPUB, MP3, M4B, M4A                                    |
| Rating         | Star rating range                                           |
| More Filters   | Advanced filter controls                                    |

The More Filters section should support combinations of filters.

Example:

```
Genre: Dark Romance
Rating: 4 stars and above
Format: EPUB
Status: Completed
```

The query should return books that match all active filters, not just one.

## **Step 4.6 — Implement star ratings on book cards**

Display a small star-rating indicator below the cover or title.

For example:

```
[Book Cover]

The Book Title
Author Name

★★★★★ 4.5
```

The card rating must use the saved book rating.

Do not create a separate rating state just for the card.

# **5. Implement the My Bookshelf experience**

Phase 4 — Visual bookshelf

This phase covers:

- Dedicated My Bookshelf screen.
- Covers view.
- Spines view.
- View switching.
- Scan Spines.
- Adjust Sizes.
- S, M and L size presets.

## **Step 5.1 — Create the bookshelf screen**

Create:

```
lib/features/bookshelves/
├── presentation/
│   ├── screens/
│   │   └── bookshelf_screen.dart
│   └── widgets/
│       ├── bookshelf_header.dart
│       ├── bookshelf_view_switcher.dart
│       ├── bookshelf_cover_view.dart
│       ├── bookshelf_spine_view.dart
│       ├── bookshelf_row.dart
│       └── bookshelf_book_item.dart
├── application/
│   └── bookshelf_controller.dart
└── data/
    └── bookshelf_repository.dart
```

Your current navigation already has a Bookshelves destination according to the repository documentation. Connect it to the actual screen instead of a placeholder.

## **Step 5.2 — Implement Covers view**

Display books using their covers.

Requirements:

- Responsive grid.
- Multiple bookshelves.
- Scrollable layout.
- Book cover images.
- Selection.
- Book details navigation.

Do not use a list of book titles as the primary bookshelf presentation.

## **Step 5.3 — Implement Spines view**

[Bookshelf Background Pictures | Download Free Images on Unsplash](https://images.openai.com/static-rsc-4/YDqbapKdYR7fAFlOBj1rlQOs9BPa5pLXqCEBRjW7NHpcZ-3IwgqpG-mY6CraaTAUtj1MvRY5tnMfPXWRurLRQnzyHv3GmqKnD9UIQXLim8nmYuN4gHl3gxORqj-ri52yJLwXYWJ1bu2c_a8V_x7_f0JMMP6ge09hvXrPncmQyNA?purpose=inline)

[新書・文庫の背表紙アップデート　opencover開発日誌｜すぎもとたつお](https://images.openai.com/static-rsc-4/N5jyw4fnssfM9CWdgTaB18B1U29oVztio-reaxtNBN1Q57SsoTjplZJHXCjMBNCa98pZlrH_TstN-NoZRLODp-E2RmwD6MIsLdc5bJYMxkh1mgR6u7pUmfY3nUgN6dlAy_wzwR12-KKfC1LzqaLscp_8nBTVR7-3EMdzPsbvQr4?purpose=inline)

[SideBooks iPhone用アプリ - からiOS用ダウンロード Tatsumi-system Co., Ltd.](https://images.openai.com/static-rsc-4/cun78y7FTEr5xaMth_E2sNcDMcNqlVn-lkwMDimtbDaJVHx66StNtbOOG8FsT-mNuVK9nonO7266uxWjAhjh4f1zUO9cWJHbeDIOE8L9vc8KY7ocsShfozFs7-4KXQfL-BH1H4FYj_DjJxciL1Sh5S8HwSdO_0O-i7wghp7Pup8?purpose=inline)

8

The Spines view should render each book as a vertical spine.

Display:

- Book title.
- Author, if space permits.
- Spine colour.
- Book height.
- Optional small decorative details.

You can use the existing cover image or generate a visual spine representation from the cover's dominant colours.

Do not make users upload a separate spine image for every book.

## **Step 5.4 — Implement the view switcher**

Add a control:

```
[ Covers ] [ Spines ]
```

When the user switches views:

- Keep the current bookshelf selected.
- Preserve scroll position if practical.
- Load the selected view.
- Save the preference.

Store the user's preferred bookshelf view in user preferences.

## **Step 5.5 — Implement Scan Spines**

This is a separate camera feature.

Suggested flow:

1. User selects Scan Spines.
2. Request camera permission.
3. Open camera.
4. Capture an image of a physical bookshelf.
5. Detect text on the spines using OCR.
6. Match detected text against existing books.
7. Search for unmatched titles.
8. Show a review screen.
9. Let the user select which matches to add.

For Flutter, you can investigate a text-recognition package such as Google ML Kit's text recognition for supported mobile platforms.

Important: OCR will not identify every spine correctly. The review screen is essential.

For web, use a separate supported implementation or allow image upload. Do not assume every mobile camera/OCR package works in Flutter Web.

# **6. Implement Bookshelf Statistics**

Phase 5 — Statistics

The eight statistics features should be calculated from the book and reading data you already store.

Create:

```
lib/features/statistics/
├── presentation/
│   ├── screens/
│   │   └── statistics_screen.dart
│   └── widgets/
│       ├── statistic_card.dart
│       ├── genre_statistics.dart
│       ├── reading_status_chart.dart
│       └── favourite_genre_card.dart
├── application/
│   └── statistics_controller.dart
└── data/
    └── statistics_repository.dart
```

## **Step 6.1 — Total books**

Count distinct book records belonging to the current user.

Do not count every attached file as a separate book.

## **Step 6.2 — Completed books**

Count books whose reading status is Completed.

If rereading is supported, use the book's current status for the library count and reading cycles for historical completion statistics.

## **Step 6.3 — Completion percentage**

Use:

```
Completed books / Total books × 100
```

Define which statuses are included in the denominator and keep that definition consistent. A sensible default is all books except archived or deleted records.

## **Step 6.4 — Currently Reading count**

Count books with the Currently Reading status.

This must support multiple active books.

## **Step 6.5 — Want to Read count**

Count books with Want to Read status.

## **Step 6.6 — Average score**

Calculate the average of the user's rated books.

Do not include unrated books as zero-rated books.

## **Step 6.7 — Genre count**

Group books by genre and count them.

For example:

| Genre    | Books |
| -------- | ----- |
| Fantasy  | 18    |
| Romance  | 14    |
| Mystery  | 9     |
| Thriller | 7     |

## **Step 6.8 — Favourite genre**

Use the genre with the highest book count or the highest completed-book count.

I recommend showing the rule clearly, such as:

```
Favourite Genre
Fantasy

18 books in your library
```

If two genres are tied, handle the tie instead of arbitrarily selecting one.

# **7. Implement Automatic Bookshelf Organisation**

Phase 6 — Smart shelves

This is one of the larger features.

You need a rule-based bookshelf system, not 14 separate hardcoded bookshelf screens.

The 14 automatic shelf categories are:

1. Genre.
2. Author.
3. Reading status.
4. Book status.
5. Page count.
6. Rating.
7. Publisher.
8. Format.
9. Price.
10. Spice.
11. Recommendation.
12. Mood.
13. Series.
14. Collections.

## **Step 7.1 — Create a Smart Shelf data model**

Create a shelf model that stores:

- Shelf ID.
- User ID.
- Shelf name.
- Shelf category.
- Filter rule.
- Display order.
- Visibility.
- Created date.

Example:

```
{
  "name": "Fantasy Books",
  "category": "GENRE",
  "rule": {
    "field": "genre",
    "operator": "EQUALS",
    "value": "Fantasy"
  }
}
```

This is an example of the rule structure, not a reason to trust arbitrary JSON supplied by the client.

Validate all rule fields and allowed operators in the backend.

## **Step 7.2 — Implement the shelf rule engine**

Create a service:

```
SmartShelfService.java
```

Its responsibility:

1. Receive a shelf definition.
2. Validate the rule.
3. Fetch books belonging to the current user.
4. Apply the rule.
5. Return matching books.
6. Return the number of matching books.

For example:

```
Shelf: Completed Books

Rule:
readingStatus = COMPLETED
```

Another example:

```
Shelf: Highly Rated

Rule:
rating >= 4
```

## **Step 7.3 — Implement each automatic shelf category**

Use a shared rule engine and create presets for each category.

| Shelf category | Matching rule                 |
| -------------- | ----------------------------- |
| Genre          | Group by genre                |
| Author         | Group by author               |
| Reading status | Group by reading status       |
| Book status    | Group by book status          |
| Page count     | Group by page-count range     |
| Rating         | Group by rating range         |
| Publisher      | Group by publisher            |
| Format         | Group by file format          |
| Price          | Group by purchase-price range |
| Spice          | Group by spice rating         |
| Recommendation | Group by recommendation       |
| Mood           | Group by mood                 |
| Series         | Group by series               |
| Collections    | Group by collection           |

You will need to ensure the corresponding metadata exists. For example, a series shelf requires a series name and ideally a series order. If the current schema does not contain those fields, add them.

## **Step 7.4 — Show the number of books per shelf**

Example:

```
Fantasy                 18 books
Romance                 14 books
Mystery                  9 books
Completed               23 books
Currently Reading        4 books
```

The count should be calculated from the matching book results.

## **Step 7.5 — Implement automatic matching**

Whenever a book is:

- Added.
- Edited.
- Rated.
- Moved to a different status.
- Assigned a genre.
- Added to a collection.

The shelf results should reflect the updated metadata.

Do not manually copy books into automatically generated shelves.

This is important: **automatic shelves should be dynamic views of your library, not duplicate copies of books.**

## **Step 7.6 — Implement multiple columns**

On desktop:

- Display multiple shelf sections across the page where space permits.
- Use a responsive grid.
- Maintain consistent book-card sizes.

On mobile:

- Use a single-column vertical arrangement.
- Allow horizontal scrolling within shelf rows.

## **Step 7.7 — Implement vertical and horizontal scrolling**

The layout should support:

- Vertical scrolling for the overall bookshelf page.
- Horizontal scrolling for books inside each shelf.
- Multiple sections.
- Shelf headings and book counts.

Do not put a vertical scrollable grid inside another vertical scrollable grid without managing the scroll constraints.

# **8. Implement Individual Book Size Customisation**

Phase 7 — Shelf editing

This phase covers all nine book resizing features.

Create:

```
lib/features/bookshelves/presentation/widgets/
├── bookshelf_edit_toolbar.dart
├── resizable_book.dart
├── book_size_slider.dart
└── bookshelf_edit_controls.dart
```

## **Step 8.1 — Add an Adjust Sizes button**

Add this to the bookshelf toolbar:

```
[ Covers ] [ Spines ] [ Adjust Sizes ]
```

When tapped:

- Enter edit mode.
- Display selection indicators.
- Allow individual books to be selected.
- Display size controls for the selected book.

## **Step 8.2 — Implement book selection**

The user taps a book.

The selected book should:

- Receive a visible selection border.
- Remain in its current position.
- Show its resize control.
- Not affect neighbouring books.

## **Step 8.3 — Implement the height slider**

The user can increase or decrease the height of the selected book.

Use a slider with sensible minimum and maximum values.

For example:

```
Book Size

Small  -----------●--------  Large
```

Keep the book's width proportional to its cover image or spine representation.

## **Step 8.4 — Implement size presets**

Add:

```
S    M    L
```

Suggested behaviour:

- S: Small.
- M: Medium.
- L: Large.

Store the chosen size for each book or bookshelf layout.

Do not hardcode the actual pixel sizes into the book database.

## **Step 8.5 — Implement live preview**

When the user moves the slider:

- Update the selected book immediately.
- Preserve the neighbouring books' positions as much as possible.
- Avoid changing the entire bookshelf unnecessarily.

## **Step 8.6 — Implement Auto Reset**

Auto Reset should restore the selected book or the entire edited shelf to its default dimensions, depending on the action label.

Provide clear confirmation if it resets all custom sizes.

## **Step 8.7 — Implement Done**

When the user taps Done:

1. Validate the dimensions.
2. Save the bookshelf layout.
3. Exit edit mode.
4. Refresh the bookshelf.
5. Synchronize changes to the backend.

If the user leaves edit mode without saving, handle unsaved changes rather than silently losing them.

# **9. Implement all remaining Book Details features**

Phase 8 — Book details and metadata

Your current Book Details screen already contains some information such as title, author, status, genre, page count, rating and additional rating controls.

Do not replace the entire screen. Extend the existing screen and preserve the current design.

## **Step 9.1 — Verify the existing features**

| Feature            | Implementation      |
| ------------------ | ------------------- |
| Enlarged cover     | Preserve and verify |
| Title              | Preserve            |
| Author             | Preserve            |
| Reading status     | Preserve            |
| Format             | Add or verify       |
| Recommendation     | Add or verify       |
| Star rating        | Preserve            |
| Rating out of 100  | Add                 |
| Genre              | Preserve            |
| Page count         | Preserve            |
| Acquisition method | Add                 |
| Start date         | Add or verify       |
| Completion date    | Add or verify       |
| Purchase date      | Add                 |
| Purchase price     | Add                 |
| Publisher          | Add                 |
| ISBN               | Add or verify       |
| Spice rating       | Add or verify       |
| Tropes             | Add                 |
| Mood               | Add                 |

## **Step 9.2 — Add the Recommendation field**

Add a recommendation selector.

Possible values:

- Highly Recommended.
- Recommended.
- Maybe.
- Not Recommended.

Save the value to the backend.

Do not confuse a recommendation with the star rating. They are separate pieces of information.

## **Step 9.3 — Add numerical rating out of 100**

Provide a slider or number selector.

For example:

```
My Rating

87 / 100
```

You can derive a star rating from this value, but don't overwrite a user's separately chosen star rating unless that is the intended product behaviour.

## **Step 9.4 — Add acquisition method**

Add a dropdown:

- Purchased.
- Gifted.
- Borrowed.
- Library.
- Free download.
- Subscription.
- Other.

Allow the user to enter a custom value if required.

## **Step 9.5 — Add dates**

Add date pickers for:

- Start date.
- Completion date.
- Purchase date.

Validation:

- Completion date should not be before start date.
- Purchase date should not be in the future unless the user has a specific reason to record a future order.
- Do not automatically overwrite manually entered dates when the reading status changes.

When the user marks a book as Completed, you can offer to set the completion date to today.

## **Step 9.6 — Add purchase price**

Use a numeric input and currency selector.

Example:

```
Purchase Price

₹ 499.00
```

Store the amount and currency separately.

## **Step 9.7 — Add publisher and ISBN**

Allow users to enter and edit these fields.

If ISBN metadata is available during import, auto-fill it. Users must still be able to correct it.

## **Step 9.8 — Add spice, tropes and mood**

Your existing screen already has some additional rating controls. Preserve them.

Add a dedicated section for:

**Spice rating**

A user-selectable scale, such as 0–5.

**Tropes**

Allow multiple tags, such as:

- Enemies to Lovers.
- Friends to Lovers.
- Second Chance.
- Forced Proximity.
- Found Family.
- Slow Burn.

**Mood**

Allow multiple mood labels or one primary mood.

Examples:

- Dark.
- Cozy.
- Emotional.
- Suspenseful.
- Romantic.
- Lighthearted.

The user should be able to add custom tropes and moods rather than being restricted to a fixed list.

# **10. Complete the Library, Bookshelf and Calendar UI integration**

Phase 9 — Frontend integration

At this stage, the backend and core feature modules should be functional.

Now connect all the screens to the real API.

## **Step 10.1 — Use Riverpod providers**

For every feature, create:

- Repository.
- Controller or notifier.
- Provider.
- Loading state.
- Error state.
- Success state.

For example:

```
features/calendar/
├── data/
│   └── reading_calendar_repository.dart
├── application/
│   └── reading_calendar_controller.dart
└── presentation/
    └── screens/
        └── reading_calendar_screen.dart
```

The screen should observe the provider rather than directly making HTTP requests.

## **Step 10.2 — Connect the navigation**

Update your existing router and navigation destinations.

Add or verify:

- Reading Calendar.
- Bookshelves.
- Statistics.

If you want the calendar to be easily accessible, I recommend placing it inside the Reading Tracker area or providing a clear dashboard shortcut.

Do not add another navigation item if an existing tracker destination already handles this.

## **Step 10.3 — Preserve the theme**

Use your existing Dark Academia and Warm Parchment theme system.

Keep:

- Existing typography.
- Existing backgrounds.
- Existing card styling.
- Existing border radii.
- Existing spacing.
- Existing responsive shell.

The calendar's green and red indicators should be integrated into the current palette, not used as an excuse to redesign the app.

## **Step 10.4 — Add loading and error states**

Every API-backed screen should handle:

- Loading.
- Empty results.
- API errors.
- Offline mode.
- Refresh.
- Retry.

For example, if the user opens the calendar without an internet connection, display cached reading history if available.

# **11. Offline support and synchronization**

Phase 10 — Persistence and reliability

Your repository documentation describes an offline-first architecture with a local database, an outbox and server synchronization.

The new features must follow that design.

## **Step 11.1 — Store new information locally**

Make sure the local database can store:

- Reading sessions.
- Reading calendar activity.
- Book metadata.
- Book ratings.
- Tropes.
- Moods.
- Purchase details.
- Bookshelf layout preferences.
- Smart shelf definitions.
- Streak freeze records.

## **Step 11.2 — Queue offline updates**

When a user changes a book's rating while offline:

1. Update the local database.
2. Add a pending operation to the outbox.
3. Display the updated value immediately.
4. Synchronize when the network returns.
5. Mark the operation as synchronized.

Apply the same pattern to reading sessions, calendar activity and bookshelf preferences.

## **Step 11.3 — Prevent duplicate sessions**

Use an idempotent client-generated ID for each session submission.

Otherwise, a request that succeeds on the server but times out before the client receives the response could create a duplicate session when retried.

## **Step 11.4 — Test synchronization across devices**

Test:

- Reading on Device A.
- Opening the same account on Device B.
- Checking that reading progress matches.
- Checking that the calendar matches.
- Changing a rating on Device B.
- Confirming that Device A receives the update.

# **12. Complete feature checklist**

This is the full backlog, with the new calendar added separately. The numbering preserves the original video feature references so you can compare them against your earlier list.

**Implementation tracker**

0/112 complete

Tick items as you implement and verify them.

**Dashboard and tracker**

0/21 complete

Daily greeting and date

Reading momentum

Daily reading streak

Personal best streak

Weekly streak calendar

Mark today complete

Streak freeze

Freeze availability

Currently Reading section

Multiple currently-reading books navigation

Book cover and title

Author and genre

Reading format

Progress slider

Current page increase/decrease

Total page count

Reading start date

Days spent reading

Average pages per day

Estimated days remaining

Expandable book description

**Library**

0/16 complete

Select/import books

Scan books/folders

Manual book addition

Search title, author and genre

Sort by recently added

Filter by reading status

Filter by book status

Filter by author

Filter by genre

Filter by format

Filter by rating

More Filters / combined filters

Cover grid

Book titles and authors

Reading status indicators

Star ratings on cards

**My Bookshelf**

0/9 complete

Dedicated My Bookshelf screen

Covers view

Spines view

Switch between Covers and Spines

Scan Spines

Adjust Sizes

Small size preset

Medium size preset

Large size preset

**Bookshelf statistics**

0/8 complete

Total books

Completed book count

Completion percentage

Currently Reading count

Want to Read count

Average score

Genre count

Favourite genre

**Automatic bookshelf organisation**

0/19 complete

Genre shelves

Author shelves

Reading-status shelves

Book-status shelves

Page-count shelves

Rating shelves

Publisher shelves

Format shelves

Price shelves

Spice-rating shelves

Recommendation shelves

Mood shelves

Series shelves

Collection shelves

Book count per shelf

Automatically match books to shelves

Multiple columns

Vertical bookshelf scrolling

Horizontal shelf sections

**Book size customisation**

0/9 complete

Enter resize mode

Select individual book

Show selected book with neighbours

Individual height slider

Live size preview

Preserve width/aspect ratio

Auto Reset

Done/save changes

Preserve neighbour positions

**Book details**

0/20 complete

Enlarged cover

Title

Author

Reading status

Format

Recommendation

Star rating

Numerical rating out of 100

Genre

Page count

Acquisition method

Start date

Completion date

Purchase date

Purchase price

Publisher

ISBN

Spice rating

Tropes

Mood

**Additional calendar feature**

0/10 complete

Real monthly calendar grid

Monday–Sunday weekday headings

Green marker for days read

Red marker for past days not read

Neutral future dates

Highlight today

Previous/next month navigation

Tap a date to view reading activity

Monthly days-read and days-missed totals

Monthly pages and reading-time totals

Reset checklist

# **13. Testing — do not skip this**

Before considering the implementation complete, test the following scenarios.

| Test                         | Expected result                               |
| ---------------------------- | --------------------------------------------- |
| Read one book today          | Calendar marks today green                    |
| Do not read on a past date   | Calendar marks it red                         |
| Open a future month          | Future dates remain neutral                   |
| Read two books on one day    | One green calendar day, both sessions counted |
| Read on two consecutive days | Streak increases                              |
| Use a valid streak freeze    | Streak is protected                           |
| Update current page          | Progress bar updates                          |
| Complete a book              | Completed count increases                     |
| Change genre                 | Genre statistics and smart shelves update     |
| Change rating                | Average score and rating filter update        |
| Attach a second format       | No duplicate book record                      |
| Switch to Spines             | Bookshelf displays spines                     |
| Resize one book              | Neighbouring book dimensions remain unchanged |
| Save shelf layout            | Dimensions remain after reopening             |
| Use a combined filter        | Only matching books appear                    |
| Go offline and update a book | Change is queued locally                      |
| Reconnect                    | Change synchronizes once                      |
| Open another account         | User cannot access another user's data        |

Run:

```
flutter analyze
flutter test
```

And:

```
.\mvnw.cmd clean test
```

Also perform manual testing in Chrome and an Android emulator. Camera scanning and local file selection need platform-specific tests.

## **14. Recommended implementation order**

Do not try to implement all 89 features in one giant code change. That would make debugging unnecessarily difficult.

| Order | Work                             | Depends on               |
| ----- | -------------------------------- | ------------------------ |
| 1     | Database and book metadata       | Existing schema          |
| 2     | Reading sessions and analytics   | Database                 |
| 3     | Reading Calendar                 | Reading sessions         |
| 4     | Streaks and dashboard            | Reading sessions         |
| 5     | Library search, sort and filters | Book metadata            |
| 6     | Book Details enhancements        | Book metadata            |
| 7     | Bookshelf Covers and Spines      | Book collection          |
| 8     | Bookshelf statistics             | Book and reading data    |
| 9     | Automatic shelves                | Metadata and collections |
| 10    | Individual book resizing         | Bookshelf UI             |
| 11    | Offline sync integration         | All changed modules      |
| 12    | Full regression testing          | All modules              |


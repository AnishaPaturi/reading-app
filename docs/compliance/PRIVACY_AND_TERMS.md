# Reading Sanctuary — Privacy Policy, Terms of Service & Data Rights

## 1. Privacy Policy Summary

Reading Sanctuary is designed around the core philosophy of **user privacy, zero tracking, and reader sovereignty**.

### 1.1 Data Collection Principles
- **No Third-Party Analytics**: Reading Sanctuary does not sell, share, or monetize reading habits, book titles, reading speeds, or annotation data.
- **Private Cloud Storage**: Book files (EPUB, PDF, DOCX, MP3, M4B) uploaded by users are stored in private, isolated AWS S3 buckets with strict access controls. They are accessible exclusively via short-lived presigned URLs generated for the authenticated user.
- **Local-First Caching**: Offline reading data is stored on-device in secure application storage (`LocalStorageDb`).

---

## 2. Terms of Service Summary

- **Personal Digital Library**: Reading Sanctuary is provided for personal reading management and archival of books and audio content to which the user has legal access.
- **Account Responsibilities**: Users are responsible for maintaining the confidentiality of their credentials.
- **Acceptable Use**: Uploading malicious binaries, automated scraping, or attempting cross-user unauthorized access is strictly prohibited.

---

## 3. Data Subject Rights & Account Deletion (GDPR & CCPA)

Reading Sanctuary implements complete user data ownership:

### 3.1 Right to Erasure ("Right to Be Forgotten")
- **Endpoint**: `DELETE /api/users/profile`
- **Execution**:
  1. Authenticates requesting user via JWT.
  2. Initiates transactional deletion across PostgreSQL:
     - Deletes `sync_change_log`, `sync_devices`, `sync_processed_changes`.
     - Deletes `reading_goals`, `activity_sessions`.
     - Deletes `book_reading_positions`, `audiobook_playback_positions`, `tts_playback_positions`.
     - Deletes `book_notes`, `book_highlights`, `bookmarks`.
     - Deletes `bookshelves`, `book_reviews`, `collections`.
     - Deletes `books` and `book_files`.
     - Deletes `users` identity and credential record.
  3. Purges associated binary files from AWS S3 via `S3StorageService.deleteObject()`.

### 3.2 Right to Portability
- **Endpoint**: `GET /api/users/export`
- **Execution**: Generates a standard JSON archive of the user's library catalog, metadata, reading logs, and annotations for download.

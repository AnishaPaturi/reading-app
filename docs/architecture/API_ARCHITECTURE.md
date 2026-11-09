# Reading Sanctuary — API Architecture & Endpoints

All endpoints are prefixed with `/api/v1/` and require `Authorization: Bearer <JWT>` header unless marked public.

---

## 1. Authentication & Users
- `POST /api/v1/users/register` [Public]: Register new account.
- `POST /api/v1/auth/login` [Public]: Authenticate with email/password, returns JWT.

## 2. Books & File Management
- `POST /api/v1/books`: Create new book record.
- `GET /api/v1/books`: List books owned by user.
- `GET /api/v1/books/{id}`: Get book details.
- `PUT /api/v1/books/{id}`: Update book metadata.
- `DELETE /api/v1/books/{id}`: Delete book and associated files.
- `GET /api/v1/books/{bookId}/files/{fileId}`: Stream or download book file.

## 3. Reading & Playback Progress
- `POST /api/v1/books/{bookId}/files/{fileId}/position`: Save format-aware reading position.
- `GET /api/v1/books/{bookId}/files/{fileId}/position`: Get latest reading position.
- `POST /api/v1/audiobook/position`: Save audiobook position.
- `GET /api/v1/audiobook/position`: Get audiobook position.
- `POST /api/v1/tts/position`: Save Text-to-Speech position.
- `GET /api/v1/tts/position`: Get Text-to-Speech position.

## 4. Bookmarks, Highlights & Notes
- `POST /api/v1/books/{bookId}/bookmarks`: Create bookmark.
- `GET /api/v1/books/{bookId}/bookmarks`: List bookmarks.
- `DELETE /api/v1/books/{bookId}/bookmarks/{id}`: Delete bookmark.
- `POST /api/v1/books/{bookId}/highlights`: Create text highlight with color.
- `GET /api/v1/books/{bookId}/highlights`: List highlights.
- `DELETE /api/v1/books/{bookId}/highlights/{id}`: Delete highlight.
- `POST /api/v1/books/{bookId}/notes`: Create book note.
- `GET /api/v1/books/{bookId}/notes`: List book notes.
- `PUT /api/v1/books/{bookId}/notes/{id}`: Update book note.
- `DELETE /api/v1/books/{bookId}/notes/{id}`: Delete book note.

## 5. Reading Analytics & Goals
- `GET /api/v1/analytics/overview`: Overview metrics (books, streaks, times).
- `GET /api/v1/analytics/streaks`: Reading streak days and history.
- `GET /api/v1/analytics/activity`: Daily and monthly activity heatmap data.
- `GET /api/v1/analytics/pace`: Reading speed and pace statistics.
- `GET /api/v1/analytics/wrap-up`: Annual reading wrap-up summary.
- `POST /api/v1/analytics/sessions/start`: Start reading/audio session.
- `POST /api/v1/analytics/sessions/{id}/heartbeat`: Heartbeat update.
- `POST /api/v1/analytics/sessions/{id}/close`: Complete session.
- `POST /api/v1/analytics/goals`: Create reading goal.
- `GET /api/v1/analytics/goals`: List active goals.
- `GET /api/v1/analytics/goals/{id}/progress`: Calculate goal progress.

## 6. Cloud Storage (AWS S3)
- `POST /api/v1/storage/upload-url`: Request presigned S3 upload URL.
- `POST /api/v1/storage/complete-upload`: Confirm upload completion with SHA-256 checksum.
- `GET /api/v1/storage/files/{fileId}/download-url`: Request presigned S3 download URL.
- `DELETE /api/v1/storage/files/{fileId}`: Delete file from S3 and database.
- `GET /api/v1/storage/files/{fileId}/status`: Get verification status.

## 7. Multi-Device Synchronization
- `POST /api/v1/sync/devices`: Register current device.
- `GET /api/v1/sync/devices`: List registered devices.
- `DELETE /api/v1/sync/devices/{id}`: Deactivate device.
- `GET /api/v1/sync/pull?deviceId=...&cursor=...`: Pull incremental changes from cursor.
- `POST /api/v1/sync/push`: Push queued client changes with conflict resolution.
- `POST /api/v1/sync/acknowledge`: Acknowledge consumed cursor.

## 8. Health & Monitoring
- `GET /actuator/health` [Public]: Application health probe.
- `GET /actuator/info` [Public]: Application info.

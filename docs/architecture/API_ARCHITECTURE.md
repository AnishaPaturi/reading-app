# Reading Sanctuary — API Architecture & Standards

## 1. Architectural Philosophy

Reading Sanctuary exposes a stateless, RESTful HTTP API built with Spring Boot 3 and Java 25. The API serves cross-platform Flutter clients (Android, iOS, Web, Desktop) and manages catalog metadata, annotations, reading progress, audio streaming, analytics, file storage via AWS S3 presigned URLs, and bidirectional offline synchronization.

---

## 2. Global Conventions

### 2.1 Base URLs
- **Local Development**: `http://localhost:8080/api`
- **Android Emulator**: `http://10.0.2.2:8080/api`
- **Production**: `https://api.readingsanctuary.com/api`

### 2.2 Content Types & Encodings
- All request and response bodies use `application/json; charset=UTF-8` unless explicitly streaming binary media.
- Binary files (PDF, EPUB, DOCX, MP3, M4B) are **never** uploaded directly through the API server; they use direct-to-S3 presigned URLs.

### 2.3 Authentication & Authorization
- **Scheme**: Bearer Token Authorization Header (`Authorization: Bearer <jwt-token>`).
- **Token Format**: Standard RFC 7519 JWT signed with HMAC-SHA256 (`HS256`).
- **Claims**:
  - `sub`: User UUID (`java.util.UUID`)
  - `email`: User email address
  - `roles`: Assigned authorities (e.g., `ROLE_USER`)
  - `iat`: Issued-at epoch seconds
  - `exp`: Expiration epoch seconds (default: 24 hours)

### 2.4 Error Schema
All error responses adhere to standard Spring Web error conventions:

```json
{
  "timestamp": "2026-11-09T10:15:30.123Z",
  "status": 404,
  "error": "Not Found",
  "message": "Book not found with ID: 4f8d227a-8b1e-4c33-9111-92b8d5e0a123",
  "path": "/api/books/4f8d227a-8b1e-4c33-9111-92b8d5e0a123"
}
```

Common status codes:
- `200 OK`: Successful read or update.
- `201 Created`: Resource successfully created.
- `204 No Content`: Successful deletion.
- `400 Bad Request`: Validation failure or malformed payload.
- `401 Unauthorized`: Missing, invalid, or expired JWT token.
- `403 Forbidden`: Resource belongs to another user (strict tenant isolation).
- `404 Not Found`: Entity not found.
- `409 Conflict`: Sync conflict or duplicate unique identifier.
- `500 Internal Server Error`: Unhandled server exception.

---

## 3. API Domain Endpoints

### 3.1 Authentication (`/api/auth`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/auth/register` | Register new user with username, email, password | No |
| `POST` | `/api/auth/login` | Authenticate with credentials and receive JWT | No |
| `POST` | `/api/auth/refresh` | Refresh an active JWT session | Yes |
| `GET` | `/api/auth/me` | Fetch authenticated user profile and roles | Yes |

### 3.2 Books & Catalog (`/api/books`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/books` | List books for authenticated user (paginated, searchable) | Yes |
| `POST` | `/api/books` | Create a new book record | Yes |
| `GET` | `/api/books/{id}` | Retrieve book details by ID | Yes |
| `PUT` | `/api/books/{id}` | Update book metadata (title, author, genre, etc.) | Yes |
| `DELETE` | `/api/books/{id}` | Delete book and cascade delete files/annotations | Yes |
| `GET` | `/api/books/{id}/files` | List files attached to book (EPUB, PDF, DOCX, Audio) | Yes |
| `POST` | `/api/books/{id}/files` | Register a file attachment record | Yes |
| `DELETE` | `/api/books/{id}/files/{fileId}` | Remove a file attachment | Yes |

### 3.3 Reading Positions (`/api/books/{bookId}/reading-position`)
Format-aware position tracking across EPUB, PDF, and DOCX:
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/books/{bookId}/reading-position` | Get latest reading position | Yes |
| `PUT` | `/api/books/{bookId}/reading-position` | Update reading position (page, CFI, scroll offset) | Yes |

### 3.4 Annotations: Bookmarks, Highlights & Notes
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/books/{bookId}/bookmarks` | List bookmarks for a book | Yes |
| `POST` | `/api/books/{bookId}/bookmarks` | Create bookmark at location | Yes |
| `DELETE` | `/api/books/{bookId}/bookmarks/{id}` | Delete bookmark | Yes |
| `GET` | `/api/books/{bookId}/highlights` | List highlights for a book | Yes |
| `POST` | `/api/books/{bookId}/highlights` | Create highlighted text with color & note | Yes |
| `PUT` | `/api/books/{bookId}/highlights/{id}` | Update highlight color or note | Yes |
| `DELETE` | `/api/books/{bookId}/highlights/{id}` | Delete highlight | Yes |
| `GET` | `/api/books/{bookId}/notes` | List book notes | Yes |
| `POST` | `/api/books/{bookId}/notes` | Create or update chapter/book note | Yes |
| `DELETE` | `/api/books/{bookId}/notes/{id}` | Delete note | Yes |

### 3.5 Audiobooks & Text-to-Speech
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/books/{bookId}/audiobook-position` | Get current audiobook playback position | Yes |
| `PUT` | `/api/books/{bookId}/audiobook-position` | Save playback position (time offset, track index) | Yes |
| `GET` | `/api/books/{bookId}/tts-position` | Get TTS reading state (utterance index, word offset) | Yes |
| `PUT` | `/api/books/{bookId}/tts-position` | Save TTS position | Yes |

### 3.6 Analytics & Reading Goals (`/api/analytics`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/analytics/sessions` | Record reading/listening session (duration, pages) | Yes |
| `GET` | `/api/analytics/dashboard` | Fetch dashboard stats (total books, streaks, hours) | Yes |
| `GET` | `/api/analytics/wrap-up` | Yearly or monthly reading wrap-up summary | Yes |
| `GET` | `/api/analytics/goals` | List reading goals (daily minutes, yearly books) | Yes |
| `POST` | `/api/analytics/goals` | Create or update a reading goal | Yes |

### 3.7 Cloud Storage Presigned URLs (`/api/storage`)
Direct offload pattern for binary files:
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/storage/upload-intent` | Request AWS S3 PUT presigned URL for upload | Yes |
| `POST` | `/api/storage/complete-upload` | Confirm upload completion and verify SHA-256 | Yes |
| `GET` | `/api/storage/download-url/{fileId}` | Generate temporary AWS S3 GET presigned URL | Yes |

### 3.8 Bidirectional Sync & Devices (`/api/sync`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/sync/devices` | Register client device (UUID, platform, name) | Yes |
| `GET` | `/api/sync/devices` | List registered devices for current user | Yes |
| `POST` | `/api/sync/pull` | Pull delta changes from server starting at cursor | Yes |
| `POST` | `/api/sync/push` | Push local outbox changes to server with conflict resolution | Yes |

---

## 4. Actuator & Monitoring Endpoints

Spring Boot Actuator provides operational endpoints configured for health checks and container probes:
- `GET /actuator/health`: Public readiness/liveness probe for AWS ALB target groups.
- `GET /actuator/info`: Build information, version, and git commit hash.
- `GET /actuator/metrics`: System and JVM performance metrics (protected).

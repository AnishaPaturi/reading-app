# Reading Sanctuary — Comprehensive Test Strategy

## 1. Test Philosophy & Testing Pyramid

Reading Sanctuary adheres to an automated testing strategy designed to guarantee data integrity, multi-tenant isolation, cross-format reader fidelity, and seamless offline synchronization across platforms.

```
       / \
      / E2E \       End-to-End User Journeys (12-step verification)
     /-------\
    /  Integ  \     Spring Boot MockMvc, Database ITs & Flutter Widget Tests
   /-----------\
  /    Unit     \   JUnit 5, Mockito, Dart Unit Tests (Models, Repositories, Reducers)
 /---------------\
```

---

## 2. Backend Test Suites (97 Tests Passing)

### 2.1 Domain & Service Unit Tests
- **Storage & S3**: `CloudStorageServiceTest` verifies presigned PUT and GET URL generation, metadata validation, and SHA-256 integrity verification.
- **Sync Engine**: `SyncServiceTest` verifies monotonic cursor progression, change log recording, and conflict resolution heuristics.
- **Controllers & DTOs**: `Step11ControllerValidationTest` tests validation constraints, JSON schemas, and HTTP status codes.

### 2.2 Security & Multi-Tenant Isolation (`UserDataIsolationTest`)
Ensures no user can access, modify, or delete another user's books, annotations, reading progress, or cloud files:
- Rejects cross-user book retrieval with `403 Forbidden` or `404 Not Found`.
- Guarantees reading positions, highlights, and bookmarks are strictly scoped by `user_id`.
- Verifies JWT claim tampering or missing tokens result in `401 Unauthorized`.

### 2.3 End-to-End Integration Tests
- `BookManagementIT`: Full lifecycle of book creation, metadata editing, file attachment, and deletion cascading.
- `ReadingProgressIT`: Format-aware position tracking, page transition sequences, and progress percentage updates.
- `AnnotationWorkflowIT`: End-to-end creation, color updating, note attachment, and retrieval for bookmarks and highlights.

---

## 3. Frontend Test Suites

### 3.1 Data Model & Serialization Tests
- `sync_models_test.dart`: Validates JSON serialization and deserialization for `SyncDeviceModel`, `SyncChangeItem`, and `SyncConflictItem`.

### 3.2 Offline Storage & Engine Tests
- `local_storage_db_test.dart`: Tests SQLite persistence for outbox queueing, state transitions (`PENDING`, `SYNCING`, `SYNCED`, `FAILED`), and device cursor tracking.
- `sync_engine_test.dart`: Verifies bidirectional delta sync, periodic background timers, exponential backoff on network failures, and network reconnection triggers.
- `download_manager_test.dart`: Validates chunked downloads, pause/resume mechanisms, and SHA-256 file integrity checks before setting `DownloadStatus.completed`.

### 3.3 Widget & Visual Tests
- `sync_widgets_test.dart`: Verifies the Dark Academia styling, accessibility labels, and state transitions of `SyncStatusIndicator`, `OfflineDownloadButton`, and `SyncConflictCard`.

---

## 4. Continuous Integration Pipeline

Both test suites are run automatically on every pull request and push to `main` via GitHub Actions:
- **`backend-ci.yml`**: Runs `./mvnw clean test` on Java 25, reporting surefire results.
- **`frontend-ci.yml`**: Runs `flutter analyze` and `flutter test`.
- Builds are blocked if any test fails or static analysis detects warnings.

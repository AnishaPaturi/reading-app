# Reading Sanctuary — Backend Setup & Developer Guide

## 1. Overview & Stack

The Reading Sanctuary backend is built on:
- **Language**: Java 25
- **Framework**: Spring Boot 3.4.x
- **Security**: Spring Security 6 with stateless JWT authentication
- **Persistence**: Spring Data JPA / Hibernate with PostgreSQL
- **Migrations**: Flyway Migration Engine
- **Cloud Storage**: AWS Java SDK v2 (`software.amazon.awssdk:s3:2.29.50`)
- **Observability**: Spring Boot Actuator

---

## 2. Environment Configuration

The backend supports two primary Spring profiles:

### 2.1 Default Local Profile (`application.properties`)
Configured for local development. By default:
- Database: `jdbc:postgresql://localhost:5432/readingsanctuary`
- Storage: Falls back to local disk storage under `./uploads/` when AWS credentials are not set.
- JWT Secret: Uses a development secret with 24-hour expiration.

### 2.2 Production Profile (`application-prod.properties`)
Activated via `-Dspring.profiles.active=prod` or `SPRING_PROFILES_ACTIVE=prod`:
- Database URL, user, and password populated via environment variables (`DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`).
- Cloud Storage: Uses AWS S3 via default credential provider chain (IAM role).
- Strict CORS configuration restricting origins to production domains.
- HikariCP connection pool configured for production concurrency.

---

## 3. Database Migrations (Flyway)

Flyway runs automatically on application startup. Migrations are located in:
`src/main/resources/db/migration/`

| Version | Migration Script | Scope |
|---|---|---|
| `V1` | `V1__init_schema.sql` | Users table and password hashes |
| `V2` | `V2__create_books_table.sql` | Books catalog and metadata |
| `V3` | `V3__create_book_files_table.sql` | Book files and S3 keys |
| `V4` | `V4__create_reading_positions_table.sql` | Format-aware reading positions |
| `V5` | `V5__create_audiobook_positions_table.sql` | Audiobook playback offsets |
| `V6` | `V6__create_tts_positions_table.sql` | Text-to-Speech playback offsets |
| `V7` | `V7__create_bookmarks_highlights_notes.sql` | Bookmarks, highlights, notes |
| `V8` | `V8__create_analytics_tables.sql` | Activity sessions and streaks |
| `V9` | `V9__create_sync_infrastructure.sql` | Sync change log, devices, idempotency |

To repair a failed migration in local development:
```bash
./mvnw flyway:repair
```

---

## 4. Building and Running

### 4.1 Running in Development Mode
```bash
cd backend/reading-sanctuary-api
./mvnw spring-boot:run
```

### 4.2 Packaging Production JAR
```bash
cd backend/reading-sanctuary-api
./mvnw clean package -DskipTests
java -jar target/reading-sanctuary-api-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod
```

### 4.3 Building Docker Container
A multi-stage `Dockerfile` is provided in the backend root:

```bash
cd backend/reading-sanctuary-api
docker build -t reading-sanctuary-api:latest .
```

To run the container:
```bash
docker run -d \
  --name reading-sanctuary-api \
  -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/readingsanctuary \
  -e DATABASE_USERNAME=postgres \
  -e DATABASE_PASSWORD=postgres \
  -e AWS_REGION=us-east-1 \
  -e AWS_S3_BUCKET=my-local-bucket \
  reading-sanctuary-api:latest
```

---

## 5. Testing & Verification

The backend includes a comprehensive suite of 97 automated tests:

```bash
cd backend/reading-sanctuary-api
./mvnw clean test
```

Test reports are generated in `target/surefire-reports/`.
Key test suites:
- `UserDataIsolationTest`: Verifies multi-tenant isolation and 403/404 boundaries.
- `BookManagementIT`: Full lifecycle integration test for books.
- `ReadingProgressIT`: Reading position transitions and tracking.
- `AnnotationWorkflowIT`: Bookmarks, highlights, notes lifecycle.
- `CloudStorageServiceTest`: S3 presigned URL generation and checksum verification.
- `SyncServiceTest`: Monotonic cursor assignment and conflict resolution.

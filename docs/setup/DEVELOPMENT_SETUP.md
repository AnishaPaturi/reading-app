# Reading Sanctuary — Local Development Setup Guide

This guide walks through configuring your local development environment to run the complete Reading Sanctuary stack (Spring Boot API, PostgreSQL, and Flutter application).

---

## 1. System Prerequisites

| Tool | Minimum Version | Verification Command | Notes |
|---|---|---|---|
| **Git** | 2.40+ | `git --version` | Source control |
| **Java JDK** | 25 | `java --version` | OpenJDK 25 / Eclipse Temurin |
| **Maven** | 3.9+ | `./mvnw -v` | Included via Maven Wrapper |
| **Flutter SDK** | 3.29+ | `flutter --version` | Channel stable |
| **Dart SDK** | 3.7+ | `dart --version` | Bundled with Flutter |
| **Docker** | 24+ | `docker --version` | For local PostgreSQL container |
| **PostgreSQL** | 16+ | `psql --version` | Or run via Docker Compose |

---

## 2. Repository Layout

```
reading-app/
├── backend/
│   └── reading-sanctuary-api/       # Spring Boot 3 API
│       ├── pom.xml
│       ├── Dockerfile
│       └── src/
│           ├── main/resources/db/migration/ # Flyway migrations (V1 to V9)
│           └── test/                        # 97 Unit and Integration tests
├── frontend/
│   └── reading_sanctuary_app/       # Flutter application
│       ├── pubspec.yaml
│       └── lib/
│           ├── core/                # Network layer, themes, storage
│           └── features/            # Auth, Books, Reader, Audio, Stats, Sync
├── docs/                            # Architecture, Setup, Testing, and Deployment
└── .github/workflows/               # GitHub Actions CI/CD pipelines
```

---

## 3. Quick Start

### 3.1 Step 1: Start PostgreSQL Database
Using Docker Compose:

```bash
docker run -d \
  --name reading-sanctuary-pg \
  -e POSTGRES_DB=readingsanctuary \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:16-alpine
```

### 3.2 Step 2: Start Spring Boot Backend
Navigate to the backend directory and launch the application:

```bash
cd backend/reading-sanctuary-api
./mvnw spring-boot:run
```

- Flyway will automatically execute migrations `V1` through `V9`.
- The API will be accessible at: `http://localhost:8080/api`
- Actuator health check: `http://localhost:8080/actuator/health`

### 3.3 Step 3: Launch Flutter Application
Open a new terminal session:

```bash
cd frontend/reading_sanctuary_app
flutter pub get
```

Run on your target platform:
- **Chrome / Web**:
  ```bash
  flutter run -d chrome
  ```
- **Android Emulator**:
  ```bash
  flutter run -d emulator-5554
  ```
  *(Note: The app automatically detects Android and directs API requests to `http://10.0.2.2:8080/api`)*
- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

---

## 4. Running Tests

### 4.1 Backend Verification
Execute all 97 backend unit, controller, and security integration tests:

```bash
cd backend/reading-sanctuary-api
./mvnw clean test
```

### 4.2 Frontend Verification
Execute all Flutter unit and widget test suites:

```bash
cd frontend/reading_sanctuary_app
flutter test
```

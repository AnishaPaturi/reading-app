# Reading Sanctuary — Development Setup Guide

## 1. Prerequisites

- **Java Development Kit**: JDK 25 (Temurin or OpenJDK)
- **Flutter SDK**: Flutter 3.47.x (Dart 3.13.x)
- **PostgreSQL**: PostgreSQL 16+ running locally on port 5432
- **Node/Git**: Git 2.40+

---

## 2. Quick Start

### 2.1 Backend Setup
```bash
# 1. Navigate to backend directory
cd backend/reading-sanctuary-api

# 2. Configure environment variables (or rely on application.properties defaults)
export DB_PASSWORD=your_local_postgres_password
export READING_SANCTUARY_JWT_SECRET=super-secret-key-at-least-256-bits-long-12345

# 3. Run migrations and start API
./mvnw spring-boot:run
```
The API starts at `http://localhost:8080/api/v1`.

### 2.2 Frontend Setup
```bash
# 1. Navigate to frontend directory
cd frontend/reading_sanctuary_app

# 2. Fetch Flutter packages
flutter pub get

# 3. Run application (Web, Android emulator, or Windows desktop)
flutter run -d chrome
# or
flutter run -d android
```

---

## 3. Verify Local Services

- API Health Check: `curl http://localhost:8080/actuator/health` -> `{"status":"UP"}`
- Web Frontend: `http://localhost:port`

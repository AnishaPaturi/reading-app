# Reading Sanctuary — Frontend Setup & Developer Guide

## 1. Overview & Stack

The Reading Sanctuary client application is built with Flutter:
- **Framework**: Flutter 3.29+ / Dart 3.7+
- **State Management**: Riverpod 2.6 (StateNotifier, Provider, FutureProvider)
- **Navigation & Routing**: GoRouter 14.8 with deep-linking and browser history support
- **Design System**: Dark Academia aesthetic (aged parchment surfaces, warm sepia undertones, ink typography)
- **Local Persistence**: `LocalStorageDb` (SQLite / secure key-value store)
- **Offline File Manager**: `DownloadManager` with SHA-256 integrity verification
- **Network Layer**: Centralized `ApiClient` with structured `ApiException` and token injection

---

## 2. Configuration & API Base URL

The application automatically resolves its API base URL using `lib/core/network/api_config.dart`.

### 2.1 Default Resolutions
- **Android Emulator**: Resolves to `http://10.0.2.2:8080/api`
- **Web & Desktop / Other**: Resolves to `http://localhost:8080/api`

### 2.2 Custom Environment Overrides
To target staging or production backends, pass `--dart-define=API_BASE_URL`:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://api.readingsanctuary.com/api
```

---

## 3. Running on Target Platforms

### 3.1 Web (Chrome)
```bash
cd frontend/reading_sanctuary_app
flutter run -d chrome --web-port=3000
```

### 3.2 Android Emulator
1. Launch Android Virtual Device (AVD):
   ```bash
   flutter emulators --launch Pixel_5
   ```
2. Run application:
   ```bash
   flutter run -d emulator-5554
   ```

### 3.3 Windows Desktop
```bash
flutter run -d windows
```

### 3.4 macOS Desktop / iOS Simulator (macOS host only)
```bash
flutter run -d ios
```

---

## 4. Production Builds

### 4.1 Production Web Build
```bash
cd frontend/reading_sanctuary_app
flutter build web \
  --release \
  --pwa-strategy=offline-first \
  --dart-define=API_BASE_URL=https://api.readingsanctuary.com/api
```
The output is generated in `build/web/` ready for Amazon S3 and CloudFront hosting.

### 4.2 Production Android Builds
- **Release APK**:
  ```bash
  flutter build apk --release --dart-define=API_BASE_URL=https://api.readingsanctuary.com/api
  ```
  Output: `build/app/outputs/flutter-apk/app-release.apk`

- **Google Play App Bundle (AAB)**:
  ```bash
  flutter build appbundle --release --dart-define=API_BASE_URL=https://api.readingsanctuary.com/api
  ```
  Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 5. Code Quality & Testing

### 5.1 Static Analysis
Check for linter rules and static type safety:
```bash
flutter analyze
```

### 5.2 Unit & Widget Tests
Execute the automated test suite:
```bash
flutter test
```
Key frontend test suites:
- `sync_models_test.dart`: Serialization of device models, change items, and conflict items.
- `local_storage_db_test.dart`: Outbox queue operations, cursor persistence, and download tasks.
- `sync_engine_test.dart`: Pull/push coordination, exponential backoff, and network recovery.
- `download_manager_test.dart`: Chunked file download, pause/resume, and SHA-256 verification.
- `sync_widgets_test.dart`: `SyncStatusIndicator`, `OfflineDownloadButton`, and conflict cards.

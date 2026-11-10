# Google Sign-In setup (Android)

This branch adds Google Sign-In to the Flutter login and registration screens. The Flutter app receives a Google ID token, sends it to Spring Boot, and Spring Boot verifies the token before creating/finding the PostgreSQL user and issuing a Reading Sanctuary JWT.

## 1. Create OAuth credentials

In Google Cloud Console:

1. Select or create a Google Cloud project.
2. Configure the OAuth consent screen / Google Auth Platform branding and audience.
3. Create an Android OAuth client:
   - Package name: com.example.reading_sanctuary_app (from android/app/build.gradle.kts).
   - SHA-1: obtain your debug SHA-1 using the command below.
4. Create a Web application OAuth client. This is the server/audience client ID used by both Flutter's serverClientId and Spring Boot's verifier.
5. Copy the Web client ID. Do not put a client secret in Flutter or commit it to Git.

Windows PowerShell, from any folder:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copy the SHA-1 fingerprint (not SHA-256) into the Android OAuth client. For release builds, also register the release signing certificate SHA-1. If distributing through Google Play App Signing, register the Play App Signing SHA-1 too.

## 2. Configure the backend .env file

The backend is configured to load a local .env file using Spring Boot's config import support. No extra dotenv dependency is required.

Create this file:
backend/reading-sanctuary-api/.env

Copy the safe template from backend/reading-sanctuary-api/.env.example and fill in your own values. Keep the real .env file local; it is ignored by Git.

```env
DB_PASSWORD=your_local_postgres_password
GOOGLE_CLIENT_ID=your_web_application_client_id.apps.googleusercontent.com
READING_SANCTUARY_JWT_SECRET=your_base64_encoded_32_byte_secret
```

Generate a JWT secret once in PowerShell:

```powershell
[Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

Paste the output into READING_SANCTUARY_JWT_SECRET. Keep it stable between restarts. Do not regenerate it every time you start the backend.

Start the backend from the backend/reading-sanctuary-api directory:

```powershell
./mvnw spring-boot:run
```

If the repository does not contain the Maven wrapper, use mvn spring-boot:run.

The backend setting app.google.client-id must contain the Web application client ID, not the Android client ID.

On startup, Flyway runs V10__google_authentication.sql. It makes password_hash nullable for Google-only accounts and adds display_name, profile_picture_url, and google_sub. Existing email/password users are preserved.

## 3. Run Flutter on the Android emulator

Open PowerShell in frontend/reading_sanctuary_app:

```powershell
flutter pub get
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_APPLICATION_CLIENT_ID.apps.googleusercontent.com
```

The existing Android emulator API base URL is http://10.0.2.2:8080/api/v1, which reaches the host machine's Spring Boot server. If you changed your backend host/port, pass --dart-define=API_BASE_URL=http://10.0.2.2:8080.

## 4. What the implementation does

- Google account selection happens in Flutter using google_sign_in.
- Flutter sends only the Google ID token to POST /api/v1/auth/google.
- Spring verifies signature, audience, issuer and Google's verified-email claim.
- A first-time user is inserted into users; a returning Google user is found by the immutable Google subject (sub).
- If a local account already has the same Google-verified email, the Google subject is linked to that existing account rather than creating a duplicate.
- The backend returns the same Reading Sanctuary JWT format used by password login.
- The app stores the returned token in the existing Riverpod auth token provider.
- The email/password login path remains available. Google-only users have no password hash and cannot log in with a password until a separate password setup/reset flow is implemented.

## 5. Verify the database

After a successful Google login, run:

```sql
SELECT id, email, display_name, profile_picture_url,
       google_sub, password_hash IS NULL AS google_only,
       is_active, created_at
FROM users
ORDER BY created_at DESC;
```

Do not select or share password hashes in screenshots or logs.

## Troubleshooting

- Google account picker opens but backend returns 401: confirm Flutter's GOOGLE_SERVER_CLIENT_ID and backend's GOOGLE_CLIENT_ID are exactly the same Web application client ID.
- Google sign-in reports developer error / code 10: check the Android package name and debug SHA-1 in the Android OAuth client. Rebuild the app after changing credentials.
- ID token is null: check the Web client ID passed as serverClientId and the Android OAuth client configuration.
- Connection refused from emulator: keep Spring Boot running on port 8080 and use 10.0.2.2, not localhost, from Android emulator.
- Flyway migration fails: inspect the Flyway error before changing the schema manually. Do not edit an already-applied migration; create a new migration instead.

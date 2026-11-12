import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reading_sanctuary_app/features/authentication/data/models/auth_user.dart';
import 'package:reading_sanctuary_app/features/authentication/data/services/session_storage.dart';
import 'package:reading_sanctuary_app/features/authentication/data/services/session_storage_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUser = AuthUser(
    id: 'user-123',
    email: 'reader@example.com',
    token: 'jwt-mock-token-xyz',
    displayName: 'Mia Reader',
    gender: 'female',
  );

  group('InMemoryAuthSessionStorage Tests', () {
    test('save, load, and clear in-memory session', () async {
      final storage = InMemoryAuthSessionStorage();

      // Initially empty
      final initial = await storage.loadSession();
      expect(initial, isNull);

      // Save
      await storage.saveSession(token: testUser.token!, user: testUser);
      final loaded = await storage.loadSession();
      expect(loaded, isNotNull);
      expect(loaded!.token, 'jwt-mock-token-xyz');
      expect(loaded.user.id, 'user-123');
      expect(loaded.user.email, 'reader@example.com');
      expect(loaded.user.displayName, 'Mia Reader');
      expect(loaded.user.gender, 'female');

      // Clear
      await storage.clearSession();
      final afterClear = await storage.loadSession();
      expect(afterClear, isNull);
    });
  });

  group('IoAuthSessionStorage (Mobile/Native) Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists session in SharedPreferences and loads it back', () async {
      final storage = IoAuthSessionStorage();

      await storage.saveSession(token: testUser.token!, user: testUser);

      final loaded = await storage.loadSession();
      expect(loaded, isNotNull);
      expect(loaded!.token, 'jwt-mock-token-xyz');
      expect(loaded.user.id, 'user-123');
      expect(loaded.user.email, 'reader@example.com');
      expect(loaded.user.displayName, 'Mia Reader');
      expect(loaded.user.gender, 'female');

      // Verify underlying SharedPreferences values
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sanctuary_auth_token'), 'jwt-mock-token-xyz');
      expect(prefs.getString('sanctuary_auth_user'), isNotNull);
    });

    test('clears session from SharedPreferences upon logout', () async {
      final storage = IoAuthSessionStorage();

      await storage.saveSession(token: testUser.token!, user: testUser);
      expect(await storage.loadSession(), isNotNull);

      await storage.clearSession();
      expect(await storage.loadSession(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('sanctuary_auth_token'), isNull);
      expect(prefs.getString('sanctuary_auth_user'), isNull);
    });

    test('returns null if stored session data is corrupted', () async {
      SharedPreferences.setMockInitialValues({
        'sanctuary_auth_token': 'valid-token',
        'sanctuary_auth_user': 'invalid-json-string{',
      });

      final storage = IoAuthSessionStorage();
      final loaded = await storage.loadSession();
      expect(loaded, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/folder_manager_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/platform_book_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class MockPlatformScanner implements PlatformBookScanner {
  final Map<String, bool> permissions = {};
  ScanFolder? nextPickedFolder;
  int releaseCount = 0;

  @override
  String get platformCapabilitiesDescription => 'Mock scanner for testing';

  @override
  Future<ScanFolder?> pickFolder() async => nextPickedFolder;

  @override
  Future<bool> verifyPermission(ScanFolder folder) async {
    return permissions[folder.pathOrUri] ?? true;
  }

  @override
  Future<bool> releasePermission(ScanFolder folder) async {
    releaseCount++;
    permissions.remove(folder.pathOrUri);
    return true;
  }

  @override
  Future<List<DiscoveredFile>> scanFolder(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async => [];

  @override
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async* {}

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPlatformScanner mockScanner;
  late FolderManagerService manager;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockScanner = MockPlatformScanner();
    manager = FolderManagerService(scanner: mockScanner);
  });

  test('registerFolder registers multiple distinct folders and prevents duplicates', () async {
    await manager.initialize();

    const folder1 = ScanFolder(
      id: 'f1',
      name: 'Downloads',
      pathOrUri: '/storage/downloads',
      isDefault: true,
      folderType: FolderType.downloads,
    );

    const folder2 = ScanFolder(
      id: 'f2',
      name: 'Audiobooks',
      pathOrUri: '/storage/audiobooks',
      folderType: FolderType.custom,
    );

    expect(await manager.registerFolder(folder1), isTrue);
    expect(await manager.registerFolder(folder2), isTrue);

    // Duplicate registration should be rejected
    expect(await manager.registerFolder(folder1), isFalse);

    expect(manager.folders.length, 2);
    expect(manager.activeFolders.length, 2);
  });

  test('persisted folders survive restart and verify permission on initialize', () async {
    // Initial session
    await manager.initialize();
    const folder = ScanFolder(
      id: 'f1',
      name: 'Downloads',
      pathOrUri: 'content://tree/primary%3ADownload',
    );
    await manager.registerFolder(folder);
    expect(manager.folders.length, 1);

    // Simulate permission revoked before next app launch
    mockScanner.permissions['content://tree/primary%3ADownload'] = false;

    // Simulate new app launch with same persistent storage
    final newManager = FolderManagerService(scanner: mockScanner);
    await newManager.initialize();

    expect(newManager.folders.length, 1);
    expect(newManager.folders.first.status, FolderAccessStatus.permissionRevoked);
    expect(newManager.activeFolders, isEmpty);

    // Test reconnect folder
    mockScanner.nextPickedFolder = const ScanFolder(
      id: 'reconnect-f1',
      name: 'Reconnected Downloads',
      pathOrUri: 'content://tree/primary%3ADownload_new',
    );
    mockScanner.permissions['content://tree/primary%3ADownload_new'] = true;

    final reconnected = await newManager.reconnectFolder('f1');
    expect(reconnected, isTrue);
    expect(newManager.folders.first.status, FolderAccessStatus.active);
    expect(newManager.folders.first.name, 'Reconnected Downloads');
    expect(newManager.activeFolders.length, 1);
  });

  test('removeFolder releases platform permission and deletes from list', () async {
    await manager.initialize();
    const folder = ScanFolder(
      id: 'f1',
      name: 'Custom',
      pathOrUri: '/storage/custom',
    );
    await manager.registerFolder(folder);
    expect(manager.folders.length, 1);

    final removed = await manager.removeFolder('f1');
    expect(removed, isTrue);
    expect(manager.folders, isEmpty);
    expect(mockScanner.releaseCount, 1);
  });
}

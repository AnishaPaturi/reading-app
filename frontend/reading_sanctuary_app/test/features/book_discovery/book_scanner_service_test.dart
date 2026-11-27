import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/book_scanner_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/folder_manager_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/platform_book_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestPlatformScanner implements PlatformBookScanner {
  final Map<String, List<DiscoveredFile>> folderFiles = {};

  @override
  String get platformCapabilitiesDescription => 'Test Scanner';

  @override
  Future<ScanFolder?> pickFolder() async => null;

  @override
  Future<bool> verifyPermission(ScanFolder folder) async => true;

  @override
  Future<bool> releasePermission(ScanFolder folder) async => true;

  @override
  Future<List<DiscoveredFile>> scanFolder(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async {
    return folderFiles[folder.id] ?? [];
  }

  @override
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async* {
    for (final file in folderFiles[folder.id] ?? <DiscoveredFile>[]) {
      yield file;
    }
  }

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestPlatformScanner mockScanner;
  late FolderManagerService folderManager;
  late BookScannerService scannerService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockScanner = TestPlatformScanner();
    folderManager = FolderManagerService(scanner: mockScanner);
    await folderManager.initialize();

    scannerService = BookScannerService(
      scanner: mockScanner,
      folderManager: folderManager,
    );
  });

  test('scanAllFolders scans across active folders and deduplicates results', () async {
    const folder1 = ScanFolder(id: 'f1', name: 'Downloads', pathOrUri: '/downloads');
    const folder2 = ScanFolder(id: 'f2', name: 'Documents', pathOrUri: '/documents');

    await folderManager.registerFolder(folder1);
    await folderManager.registerFolder(folder2);

    final file1 = DiscoveredFile(
      id: 'd1',
      name: 'Book1.epub',
      pathOrUri: '/downloads/Book1.epub',
      extension: 'epub',
      sizeBytes: 1000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/downloads',
    );

    final file2 = DiscoveredFile(
      id: 'd2',
      name: 'Audio.mp3',
      pathOrUri: '/documents/Audio.mp3',
      extension: 'mp3',
      sizeBytes: 5000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/documents',
    );

    // Duplicate reference of file1 appearing in second folder
    final duplicateFile = DiscoveredFile(
      id: 'd3',
      name: 'Book1.epub',
      pathOrUri: '/downloads/Book1.epub',
      extension: 'epub',
      sizeBytes: 1000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/documents',
    );

    mockScanner.folderFiles['f1'] = [file1];
    mockScanner.folderFiles['f2'] = [file2, duplicateFile];

    final results = await scannerService.scanAllFolders();

    // Deduplicated by pathOrUri -> exactly 2 files
    expect(results.length, 2);
    expect(results.map((f) => f.pathOrUri).toSet(), containsAll(['/downloads/Book1.epub', '/documents/Audio.mp3']));

    // Verify folder stats updated
    expect(folderManager.folders.firstWhere((f) => f.id == 'f1').discoveredCount, 1);
    expect(folderManager.folders.firstWhere((f) => f.id == 'f2').discoveredCount, 2);
  });

  test('scanSingleFolder scans designated folder and merges into discoveredFiles', () async {
    const folder = ScanFolder(id: 'f1', name: 'Downloads', pathOrUri: '/downloads');
    await folderManager.registerFolder(folder);

    final file = DiscoveredFile(
      id: 'd1',
      name: 'Notes.pdf',
      pathOrUri: '/downloads/Notes.pdf',
      extension: 'pdf',
      sizeBytes: 2000,
      lastModified: DateTime.now(),
      parentFolderIdentifier: '/downloads',
    );

    mockScanner.folderFiles['f1'] = [file];

    final results = await scannerService.scanSingleFolder(folder);

    expect(results.length, 1);
    expect(scannerService.discoveredFiles.length, 1);
    expect(scannerService.discoveredFiles.first.name, 'Notes.pdf');

    scannerService.clearResults();
    expect(scannerService.discoveredFiles, isEmpty);
  });
}

import 'dart:async';
import 'dart:typed_data';
import '../../models/discovered_file.dart';
import '../../models/scan_folder.dart';
import 'platform_book_scanner.dart';

class DesktopBookScanner implements PlatformBookScanner {
  @override
  String get platformCapabilitiesDescription =>
      'Desktop filesystem scanner is not available in browser.';

  @override
  Future<ScanFolder?> pickFolder() async => null;

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
  Future<bool> verifyPermission(ScanFolder folder) async => false;

  @override
  Future<bool> releasePermission(ScanFolder folder) async => true;

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async => null;
}

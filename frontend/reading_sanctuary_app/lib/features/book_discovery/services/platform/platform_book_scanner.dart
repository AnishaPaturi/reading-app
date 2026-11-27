import 'dart:typed_data';
import '../../models/discovered_file.dart';
import '../../models/scan_folder.dart';

abstract class PlatformBookScanner {
  /// Allows user to pick a folder using platform-appropriate mechanism.
  /// Android: launches Intent.ACTION_OPEN_DOCUMENT_TREE and takes persistable permission.
  /// Desktop: launches native directory picker.
  /// Web: directory selection or multi-file selection.
  Future<ScanFolder?> pickFolder();

  /// Scans a folder recursively and returns matching book/audiobook files.
  Future<List<DiscoveredFile>> scanFolder(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  });

  /// Verifies if stored folder permission/path is still valid and accessible.
  Future<bool> verifyPermission(ScanFolder folder);

  /// Releases persistent permission if applicable (e.g. Android SAF).
  Future<bool> releasePermission(ScanFolder folder);

  /// Reads leading bytes of file for signature verification.
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12});

  /// Streams files as they are discovered for progressive UI feedback.
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  });

  /// Human-readable explanation of platform-specific storage capabilities / limitations.
  String get platformCapabilitiesDescription;
}

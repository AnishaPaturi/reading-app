import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/services/providers.dart';
import '../../library/presentation/providers/book_upload_provider.dart';
import '../models/batch_import_state.dart';
import '../services/batch_import_service.dart';
import '../services/book_scanner_service.dart';
import '../services/discovery_engine.dart';
import '../services/duplicate_detection_service.dart';
import '../services/file_checksum_service.dart';
import '../services/folder_manager_service.dart';
import '../services/platform_file_stream_service.dart';
import 'batch_import_provider.dart';
import 'book_selection_provider.dart';

final fileChecksumServiceProvider = Provider<FileChecksumService>((ref) {
  return FileChecksumService();
});

final folderManagerServiceProvider = ChangeNotifierProvider<FolderManagerService>((ref) {
  final scanner = BookScannerService.createDefaultPlatformScanner();
  return FolderManagerService(scanner: scanner);
});

final bookScannerServiceProvider = ChangeNotifierProvider<BookScannerService>((ref) {
  final folderManager = ref.watch(folderManagerServiceProvider);
  return BookScannerService(
    scanner: folderManager.scanner,
    folderManager: folderManager,
  );
});

final duplicateDetectionServiceProvider = Provider<DuplicateDetectionService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final checksumService = ref.watch(fileChecksumServiceProvider);
  final scanner = ref.watch(folderManagerServiceProvider).scanner;
  return DuplicateDetectionService(
    apiClient: apiClient,
    checksumService: checksumService,
    platformScanner: scanner,
  );
});

final discoveryEngineProvider = ChangeNotifierProvider<DiscoveryEngine>((ref) {
  final scannerService = ref.watch(bookScannerServiceProvider);
  final duplicateService = ref.watch(duplicateDetectionServiceProvider);
  return DiscoveryEngine(
    scannerService: scannerService,
    duplicateDetectionService: duplicateService,
  );
});

final platformFileStreamServiceProvider = Provider<PlatformFileStreamService>((ref) {
  return PlatformFileStreamService();
});

final batchImportServiceProvider = Provider<BatchImportService>((ref) {
  final uploadService = ref.watch(bookUploadServiceProvider);
  final streamService = ref.watch(platformFileStreamServiceProvider);
  return BatchImportService(
    uploadService: uploadService,
    streamService: streamService,
    onLibraryUpdated: () {
      ref.invalidate(booksProvider);
    },
  );
});

final bookSelectionProvider = StateNotifierProvider<BookSelectionNotifier, Set<String>>((ref) {
  return BookSelectionNotifier();
});

final batchImportProvider = StateNotifierProvider<BatchImportNotifier, BatchImportState>((ref) {
  final service = ref.watch(batchImportServiceProvider);
  return BatchImportNotifier(service: service);
});

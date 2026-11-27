import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../models/classified_book.dart';
import '../models/discovered_file.dart';
import '../models/duplicate_status.dart';
import 'file_checksum_service.dart';
import 'file_signature_validator.dart';
import 'platform/platform_book_scanner.dart';

class BackendDuplicateCheckResult {
  final Map<String, Map<String, dynamic>> matchesByChecksum;
  final Set<String> verifiedChecksums;
  final Map<String, String> batchErrors;

  const BackendDuplicateCheckResult({
    this.matchesByChecksum = const {},
    this.verifiedChecksums = const {},
    this.batchErrors = const {},
  });
}

class DuplicateDetectionService {
  final ApiClient? apiClient;
  final FileChecksumService checksumService;
  final PlatformBookScanner? platformScanner;

  DuplicateDetectionService({
    this.apiClient,
    required this.checksumService,
    this.platformScanner,
  });

  /// Processes discovered files, validates signatures, streams SHA-256,
  /// clusters local duplicates, verifies against backend library, and classifies every file.
  Future<List<ClassifiedBook>> classifyFiles(
    List<DiscoveredFile> files, {
    void Function(int processed, int total, String currentFileName)? onProgress,
  }) async {
    if (files.isEmpty) return [];

    final classified = <ClassifiedBook>[];
    final filesNeedingBackendCheck = <DiscoveredFile>[];
    final fileChecksumMap = <String, String>{}; // pathOrUri -> checksum
    final checksumFirstFileMap = <String, DiscoveredFile>{}; // checksum -> first DiscoveredFile

    var processedCount = 0;
    final total = files.length;

    // STEP 1: Format validation & streaming SHA-256 calculation
    for (final file in files) {
      processedCount++;
      onProgress?.call(processedCount, total, file.name);

      // 1. Check empty file (0 bytes)
      if (file.sizeBytes <= 0) {
        classified.add(
          ClassifiedBook(
            file: file,
            checksum: '',
            classification: DuplicateClassification.invalid,
            errorMessage: 'File is empty (0 bytes)',
            isValidFormat: false,
          ),
        );
        continue;
      }

      // 2. Read leading bytes if not already available
      Uint8List? header = file.headerBytes;
      if (header == null && platformScanner != null) {
        try {
          header = await platformScanner!.readFileHeader(file.pathOrUri, maxBytes: 12);
        } catch (_) {}
      }

      // 3. Validate format signature (magic bytes)
      final signatureError = FileSignatureValidator.validateSignature(
        file.extension,
        header,
        file.sizeBytes,
      );

      if (signatureError != null) {
        classified.add(
          ClassifiedBook(
            file: file,
            checksum: '',
            classification: DuplicateClassification.invalid,
            errorMessage: signatureError,
            isValidFormat: false,
          ),
        );
        continue;
      }

      // 4. Compute streaming SHA-256 (with smart cache invalidation)
      final checksum = await checksumService.computeChecksum(file);

      if (checksum == null || checksum.isEmpty) {
        classified.add(
          ClassifiedBook(
            file: file,
            checksum: '',
            classification: DuplicateClassification.error,
            errorMessage: 'Could not access or hash file content',
            isValidFormat: false,
          ),
        );
        continue;
      }

      fileChecksumMap[file.pathOrUri] = checksum;
      final enrichedFile = file.copyWith(checksum: checksum);

      // 5. Detect duplicates within the current scan session
      if (checksumFirstFileMap.containsKey(checksum)) {
        final firstFile = checksumFirstFileMap[checksum]!;
        classified.add(
          ClassifiedBook(
            file: enrichedFile,
            checksum: checksum,
            classification: DuplicateClassification.duplicateInScan,
            duplicateOfPathOrUri: firstFile.pathOrUri,
            isValidFormat: true,
          ),
        );
      } else {
        checksumFirstFileMap[checksum] = enrichedFile;
        filesNeedingBackendCheck.add(enrichedFile);
      }
    }

    // STEP 2: Query backend library duplicate endpoint for distinct checksums
    BackendDuplicateCheckResult checkResult = const BackendDuplicateCheckResult();

    if (apiClient != null && filesNeedingBackendCheck.isNotEmpty) {
      checkResult = await _checkBackendDuplicates(filesNeedingBackendCheck);
    }

    // STEP 3: Classify distinct files against backend results
    for (final file in filesNeedingBackendCheck) {
      final checksum = fileChecksumMap[file.pathOrUri]!;

      // 1. Matched as duplicate in user's library
      if (checkResult.matchesByChecksum.containsKey(checksum)) {
        final match = checkResult.matchesByChecksum[checksum]!;
        classified.add(
          ClassifiedBook(
            file: file,
            checksum: checksum,
            classification: DuplicateClassification.alreadyImported,
            existingBookTitle: match['existingBookTitle'] as String?,
            existingBookId: match['existingBookId'] as String?,
            isValidFormat: true,
          ),
        );
      }
      // 2. Explicitly verified by backend as absent from user's library
      else if (checkResult.verifiedChecksums.contains(checksum)) {
        classified.add(
          ClassifiedBook(
            file: file,
            checksum: checksum,
            classification: DuplicateClassification.newBook,
            isValidFormat: true,
          ),
        );
      }
      // 3. Unverified (backend unavailable, network error, failed batch, or partial response)
      else {
        final errorReason = checkResult.batchErrors[file.id] ??
            (apiClient == null
                ? 'Library duplicate verification unavailable: Client offline or unauthenticated'
                : 'Library duplicate verification could not be completed');

        classified.add(
          ClassifiedBook(
            file: file,
            checksum: checksum,
            classification: DuplicateClassification.verificationFailed,
            errorMessage: errorReason,
            isValidFormat: true,
          ),
        );
      }
    }

    // STEP 4: Propagate existingBookTitle to any scan-duplicates if primary file is already imported
    return _propagateDuplicateMetadata(classified, checkResult.matchesByChecksum);
  }

  /// Retries backend duplicate verification for any previously unverified books.
  /// Reuses existing calculated checksums without recalculating or reading from disk.
  Future<List<ClassifiedBook>> retryVerification(
    List<ClassifiedBook> books, {
    void Function(int processed, int total, String currentFileName)? onProgress,
  }) async {
    final unverified = books
        .where((b) => b.classification == DuplicateClassification.verificationFailed)
        .toList();

    if (unverified.isEmpty || apiClient == null) {
      if (apiClient == null) {
        return books.map((b) {
          if (b.classification == DuplicateClassification.verificationFailed) {
            return b.copyWith(
              errorMessage: 'Library duplicate verification unavailable: Client offline',
            );
          }
          return b;
        }).toList();
      }
      return books;
    }

    final unverifiedFiles = unverified.map((b) => b.file).toList();
    final checkResult = await _checkBackendDuplicates(unverifiedFiles);

    final updated = books.map((book) {
      if (book.classification != DuplicateClassification.verificationFailed) {
        return book;
      }

      final checksum = book.checksum;
      if (checkResult.matchesByChecksum.containsKey(checksum)) {
        final match = checkResult.matchesByChecksum[checksum]!;
        return book.copyWith(
          classification: DuplicateClassification.alreadyImported,
          existingBookTitle: match['existingBookTitle'] as String?,
          existingBookId: match['existingBookId'] as String?,
          errorMessage: null,
        );
      } else if (checkResult.verifiedChecksums.contains(checksum)) {
        return book.copyWith(
          classification: DuplicateClassification.newBook,
          errorMessage: null,
        );
      } else {
        final err = checkResult.batchErrors[book.file.id] ??
            'Library duplicate verification could not be completed';
        return book.copyWith(errorMessage: err);
      }
    }).toList();

    return _propagateDuplicateMetadata(updated, checkResult.matchesByChecksum);
  }

  List<ClassifiedBook> _propagateDuplicateMetadata(
    List<ClassifiedBook> classified,
    Map<String, Map<String, dynamic>> matchesByChecksum,
  ) {
    return classified.map((book) {
      if (book.classification == DuplicateClassification.duplicateInScan) {
        final primaryChecksum = book.checksum;
        if (matchesByChecksum.containsKey(primaryChecksum)) {
          final match = matchesByChecksum[primaryChecksum]!;
          return book.copyWith(
            existingBookTitle: match['existingBookTitle'] as String?,
            existingBookId: match['existingBookId'] as String?,
          );
        }
      }
      return book;
    }).toList();
  }

  Future<BackendDuplicateCheckResult> _checkBackendDuplicates(
    List<DiscoveredFile> files,
  ) async {
    final matches = <String, Map<String, dynamic>>{};
    final verified = <String>{};
    final batchErrors = <String, String>{};
    const batchSize = 100;

    for (var i = 0; i < files.length; i += batchSize) {
      final batch = files.skip(i).take(batchSize).toList();

      final requestPayload = {
        'files': batch.map((f) => {
          'clientRefId': f.id,
          'checksum': f.checksum,
          'fileName': f.name,
          'fileSizeBytes': f.sizeBytes,
        }).toList(),
      };

      try {
        final dynamic response = await apiClient!.post(
          '/books/check-duplicates',
          body: requestPayload,
        );

        if (response != null && response is Map<String, dynamic>) {
          // 1. Process matches
          final duplicates = response['duplicates'] as List<dynamic>? ?? [];
          for (final d in duplicates) {
            if (d is Map<String, dynamic>) {
              final checksum = d['checksum'] as String?;
              if (checksum != null && checksum.isNotEmpty) {
                matches[checksum] = d;
              }
            }
          }

          // 2. Process verified checksums
          final returnedVerified = response['verifiedChecksums'] as List<dynamic>?;
          if (returnedVerified != null) {
            for (final v in returnedVerified) {
              if (v is String && v.isNotEmpty) {
                verified.add(v);
              }
            }
          } else {
            // For responses without explicit verifiedChecksums list, all items in successful batch are verified
            for (final f in batch) {
              if (f.checksum != null && f.checksum!.isNotEmpty) {
                verified.add(f.checksum!);
              }
            }
          }
        } else {
          // Empty or non-map response: mark batch as unverified
          for (final f in batch) {
            batchErrors[f.id] = 'Unexpected or empty response from backend';
          }
        }
      } catch (e) {
        final errorMsg = 'Backend duplicate batch check failed: $e';
        debugPrint(errorMsg);
        for (final f in batch) {
          batchErrors[f.id] = errorMsg;
        }
      }
    }

    return BackendDuplicateCheckResult(
      matchesByChecksum: matches,
      verifiedChecksums: verified,
      batchErrors: batchErrors,
    );
  }
}

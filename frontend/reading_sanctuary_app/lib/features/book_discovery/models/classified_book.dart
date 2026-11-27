import 'package:flutter/foundation.dart';
import 'discovered_file.dart';
import 'duplicate_status.dart';

@immutable
class ClassifiedBook {
  final DiscoveredFile file;
  final String checksum;
  final DuplicateClassification classification;
  final String? existingBookTitle;
  final String? existingBookId;
  final String? duplicateOfPathOrUri;
  final String? errorMessage;
  final bool isValidFormat;

  const ClassifiedBook({
    required this.file,
    required this.checksum,
    required this.classification,
    this.existingBookTitle,
    this.existingBookId,
    this.duplicateOfPathOrUri,
    this.errorMessage,
    this.isValidFormat = true,
  });

  /// A book is strictly importable only after backend library verification
  /// confirms that it is a verified new book not present in the user's library.
  bool get isImportable => classification == DuplicateClassification.newBook;

  bool get isAlreadyImported => classification == DuplicateClassification.alreadyImported;

  bool get isDuplicateInScan => classification == DuplicateClassification.duplicateInScan;

  bool get isVerificationFailed => classification == DuplicateClassification.verificationFailed;

  bool get isDuplicate => isAlreadyImported || isDuplicateInScan;

  bool get hasError =>
      classification == DuplicateClassification.invalid ||
      classification == DuplicateClassification.error ||
      classification == DuplicateClassification.verificationFailed;

  ClassifiedBook copyWith({
    DiscoveredFile? file,
    String? checksum,
    DuplicateClassification? classification,
    String? existingBookTitle,
    String? existingBookId,
    String? duplicateOfPathOrUri,
    String? errorMessage,
    bool? isValidFormat,
  }) {
    return ClassifiedBook(
      file: file ?? this.file,
      checksum: checksum ?? this.checksum,
      classification: classification ?? this.classification,
      existingBookTitle: existingBookTitle ?? this.existingBookTitle,
      existingBookId: existingBookId ?? this.existingBookId,
      duplicateOfPathOrUri: duplicateOfPathOrUri ?? this.duplicateOfPathOrUri,
      errorMessage: errorMessage ?? this.errorMessage,
      isValidFormat: isValidFormat ?? this.isValidFormat,
    );
  }

  Map<String, dynamic> toJson() => {
    'file': file.toJson(),
    'checksum': checksum,
    'classification': classification.name,
    'existingBookTitle': existingBookTitle,
    'existingBookId': existingBookId,
    'duplicateOfPathOrUri': duplicateOfPathOrUri,
    'errorMessage': errorMessage,
    'isValidFormat': isValidFormat,
  };

  factory ClassifiedBook.fromJson(Map<String, dynamic> json) => ClassifiedBook(
    file: DiscoveredFile.fromJson(json['file'] as Map<String, dynamic>),
    checksum: json['checksum'] as String? ?? '',
    classification: DuplicateClassification.values.firstWhere(
      (e) => e.name == json['classification'],
      orElse: () => DuplicateClassification.error,
    ),
    existingBookTitle: json['existingBookTitle'] as String?,
    existingBookId: json['existingBookId'] as String?,
    duplicateOfPathOrUri: json['duplicateOfPathOrUri'] as String?,
    errorMessage: json['errorMessage'] as String?,
    isValidFormat: json['isValidFormat'] as bool? ?? true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassifiedBook && runtimeType == other.runtimeType && file.pathOrUri == other.file.pathOrUri;

  @override
  int get hashCode => file.pathOrUri.hashCode;
}

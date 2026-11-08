enum ReaderFileType {
  pdf,
  epub,
  docx;

  static ReaderFileType fromFormat(String format) {
    switch (format.toUpperCase()) {
      case 'PDF':
        return ReaderFileType.pdf;
      case 'EPUB':
        return ReaderFileType.epub;
      case 'DOCX':
        return ReaderFileType.docx;
      default:
        throw UnsupportedError(
          'Unsupported reading format: $format',
        );
    }
  }
}

enum AnnotationType {
  highlight,
  note,
}

extension AnnotationTypeX on AnnotationType {
  String get nameUpper => name.toUpperCase();

  static AnnotationType fromString(String? val) {
    if (val == null) return AnnotationType.highlight;
    final lower = val.toLowerCase().trim();
    if (lower == 'note') return AnnotationType.note;
    return AnnotationType.highlight;
  }
}

class ClassScope {
  final int? classNumber;
  final String section;

  const ClassScope({required this.classNumber, required this.section});

  factory ClassScope.fromProfile(Map<String, dynamic> map) {
    return ClassScope(
      classNumber: _readClassNumber(map['class']),
      section: (map['section'] ?? '').toString().trim(),
    );
  }

  static int? _readClassNumber(dynamic value) {
    if (value is int && value >= 1 && value <= 12) return value;

    final parsed = int.tryParse((value ?? '').toString().trim());
    if (parsed == null || parsed < 1 || parsed > 12) return null;
    return parsed;
  }

  bool get isAssigned => classNumber != null;

  String get label {
    if (classNumber == null && section.isEmpty) return 'Unassigned class';
    if (section.isEmpty) return classNumber?.toString() ?? 'Unassigned class';
    return '${classNumber ?? 'Unassigned class'} - $section';
  }

  Map<String, dynamic> toHomeworkColumns() {
    return {'class_number': classNumber, 'section': section};
  }

  bool matches({required int classNumber, required String section}) {
    final sameClass = this.classNumber == classNumber;
    final sameSection =
        this.section.isEmpty ||
        section.isEmpty ||
        this.section.toLowerCase() == section.toLowerCase();
    return sameClass && sameSection;
  }
}

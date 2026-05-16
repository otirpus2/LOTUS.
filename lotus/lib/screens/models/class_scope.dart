class ClassScope {
  final int? classNumber;
  final String className;
  final String section;

  const ClassScope({
    required this.classNumber,
    required this.className,
    required this.section,
  });

  factory ClassScope.fromProfile(Map<String, dynamic> map) {
    final classValue = (map['class'] ?? '').toString().trim();
    return ClassScope(
      classNumber: _readClassNumber(classValue),
      className: classValue,
      section: (map['section'] ?? '').toString().trim(),
    );
  }

  static int? _readClassNumber(dynamic value) {
    if (value is int && value >= 1 && value <= 12) return value;

    final parsed = int.tryParse((value ?? '').toString().trim());
    if (parsed == null || parsed < 1 || parsed > 12) return null;
    return parsed;
  }

  bool get isAssigned => className.isNotEmpty || classNumber != null;

  String get classKey {
    if (className.isNotEmpty) return _normalizeClass(className);
    return classNumber?.toString() ?? '';
  }

  String get label {
    final displayClass = className.isNotEmpty
        ? className
        : classNumber?.toString();
    if (displayClass == null && section.isEmpty) return 'Unassigned class';
    if (section.isEmpty) return displayClass ?? 'Unassigned class';
    return '${displayClass ?? 'Unassigned class'} - $section';
  }

  Map<String, dynamic> toHomeworkColumns() {
    return {'class_name': className, 'section': section};
  }

  bool matches({required String className, required String section}) {
    final sameClass = classKey == _normalizeClass(className);
    final sameSection =
        this.section.isEmpty ||
        section.isEmpty ||
        this.section.toLowerCase() == section.toLowerCase();
    return sameClass && sameSection;
  }

  static String _normalizeClass(String value) {
    final text = value.trim().toLowerCase();
    if (text.isEmpty) return '';

    final parsed = int.tryParse(text);
    if (parsed != null) return parsed.toString();

    final numberMatch = RegExp(r'\d+').firstMatch(text);
    if (numberMatch != null) {
      return int.parse(numberMatch.group(0)!).toString();
    }

    return text;
  }
}

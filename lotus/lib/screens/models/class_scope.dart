class ClassScope {
  final String? classId;
  final String? className;
  final String section;

  const ClassScope({required this.classId, required this.className, required this.section});

  factory ClassScope.fromProfile(Map<String, dynamic> map) {
    final classRoom = map['class_rooms'] as Map<String, dynamic>?;
    return ClassScope(
      classId: map['class_id']?.toString(),
      className: classRoom?['name']?.toString() ?? map['class']?.toString(),
      section: (classRoom?['section'] ?? map['section'] ?? '').toString().trim(),
    );
  }

  bool get isAssigned => classId != null || className != null;

  String get label {
    if (!isAssigned) return 'Unassigned class';
    if (section.isEmpty) return className ?? 'Unassigned class';
    return '${className ?? 'Unassigned class'} - $section';
  }

  Map<String, dynamic> toHomeworkColumns() {
    if (classId != null) {
      return {'class_id': classId};
    }
    return {'class_name': className, 'section': section};
  }
}

class CalendarAudienceScope {
  final String userId;
  final String? classId;
  final String className;
  final String section;

  const CalendarAudienceScope({
    required this.userId,
    required this.classId,
    required this.className,
    required this.section,
  });

  factory CalendarAudienceScope.fromProfile({
    required String userId,
    required Map<String, dynamic>? map,
  }) {
    final classRoom = map?['class_rooms'] as Map<String, dynamic>?;
    return CalendarAudienceScope(
      userId: userId,
      classId: map?['class_id']?.toString(),
      className: classRoom?['name']?.toString() ?? '',
      section: (classRoom?['section'] ?? '').toString().trim(),
    );
  }

  String get label {
    if (className.isEmpty && section.isEmpty) return 'Unassigned class';
    if (section.isEmpty) return className;
    return '$className - $section';
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String colorHex;
  final String? classId;
  final List<String> targetStudentIds;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.colorHex,
    required this.classId,
    required this.targetStudentIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      eventDate: _readDate(map['event_date']),
      colorHex: _readColor(map['color_hex']),
      classId: map['class_id']?.toString(),
      targetStudentIds: _readStringList(map['target_student_ids']),
      createdBy: _readOptionalText(map['created_by']),
      createdAt: _readOptionalDateTime(map['created_at']),
      updatedAt: _readOptionalDateTime(map['updated_at']),
    );
  }

  bool get isStudentEvent => targetStudentIds.isNotEmpty;

  String get dateKey => formatCalendarDate(eventDate);

  String get audienceLabel {
    if (isStudentEvent) return 'For you';
    if (classId == null) return 'Common event';
    return 'Class Event';
  }

  bool isVisibleFor(CalendarAudienceScope audience) {
    if (isStudentEvent) {
      return targetStudentIds.contains(audience.userId);
    }

    if (classId == null) return true;
    return audience.classId == classId;
  }
}

String formatCalendarDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String? _readOptionalText(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? null : text;
}

String _readColor(dynamic value) {
  final text = (value ?? '').toString().trim();
  return text.isEmpty ? '#4285F4' : text;
}

List<String> _readStringList(dynamic value) {
  if (value == null) return const <String>[];

  if (value is List) {
    return value
        .map((item) => (item ?? '').toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final text = value.toString().trim();
  if (text.isEmpty) return const <String>[];

  return text
      .replaceAll('{', '')
      .replaceAll('}', '')
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

DateTime _readDate(dynamic value) {
  final text = (value ?? '').toString().trim();
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return DateTime.now();
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _readOptionalDateTime(dynamic value) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

class CalendarAudienceScope {
  final String userId;
  final String className;
  final String section;

  const CalendarAudienceScope({
    required this.userId,
    required this.className,
    required this.section,
  });

  factory CalendarAudienceScope.fromProfile({
    required String userId,
    required Map<String, dynamic>? map,
  }) {
    return CalendarAudienceScope(
      userId: userId,
      className: (map?['class'] ?? '').toString().trim(),
      section: (map?['section'] ?? '').toString().trim(),
    );
  }

  String get label {
    if (className.isEmpty && section.isEmpty) return 'Unassigned class';
    if (section.isEmpty) return className;
    return '$className - $section';
  }

  String get classKey => normalizeCalendarClass(className);
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String colorHex;
  final String className;
  final String section;
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
    required this.className,
    required this.section,
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
      className:
          _readOptionalText(
            map['class_name'] ?? map['class'] ?? map['class_number'],
          ) ??
          '',
      section: (map['section'] ?? '').toString().trim(),
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
    if (className.isEmpty) return 'Common event';
    if (section.isEmpty) return 'Class $className';
    return 'Class $className - $section';
  }

  bool isVisibleFor(CalendarAudienceScope audience) {
    if (isStudentEvent) {
      return targetStudentIds.contains(audience.userId);
    }

    if (className.isEmpty) return true;
    if (audience.classKey != normalizeCalendarClass(className)) return false;
    if (section.isEmpty) return true;
    if (audience.section.isEmpty) return false;
    return audience.section.toLowerCase() == section.toLowerCase();
  }
}

String formatCalendarDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String normalizeCalendarClass(String value) {
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

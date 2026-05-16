class HomeworkModel {
  final String id;
  final String subject;
  final String fileType; // normalized: pdf | doc | excel
  final String fileName;
  final String storagePath;
  final int? classNumber;
  final String className;
  final String section;
  final List<String> targetStudentIds;
  final DateTime createdAt;

  HomeworkModel({
    required this.id,
    required this.subject,
    required this.fileType,
    required this.fileName,
    required this.storagePath,
    required this.classNumber,
    required this.className,
    required this.section,
    required this.targetStudentIds,
    required this.createdAt,
  });

  factory HomeworkModel.fromMap(Map<String, dynamic> map) {
    return HomeworkModel(
      id: map['id']?.toString() ?? '',
      subject: map['subject'] ?? '',
      fileType: map['file_type'] ?? '',
      fileName: map['file_name'] ?? '',
      storagePath: map['storage_path'] ?? '',
      classNumber: _readClassNumber(map['class_name'] ?? map['class']),
      className: (map['class_name'] ?? map['class'] ?? '').toString().trim(),
      section: map['section'] ?? '',
      targetStudentIds: _readStringList(map['target_student_ids']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static int? _readClassNumber(dynamic value) {
    if (value is int && value >= 1 && value <= 12) return value;

    final parsed = int.tryParse((value ?? '').toString().trim());
    if (parsed == null || parsed < 1 || parsed > 12) return null;
    return parsed;
  }

  static List<String> _readStringList(dynamic value) {
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
}

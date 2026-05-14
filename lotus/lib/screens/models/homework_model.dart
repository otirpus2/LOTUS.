class HomeworkModel {
  final String id;
  final String subject;
  final String fileType; // normalized: pdf | doc | excel
  final String fileName;
  final String storagePath;
  final int? classNumber;
  final String section;
  final DateTime createdAt;

  HomeworkModel({
    required this.id,
    required this.subject,
    required this.fileType,
    required this.fileName,
    required this.storagePath,
    required this.classNumber,
    required this.section,
    required this.createdAt,
  });

  factory HomeworkModel.fromMap(Map<String, dynamic> map) {
    return HomeworkModel(
      id: map['id']?.toString() ?? '',
      subject: map['subject'] ?? '',
      fileType: map['file_type'] ?? '',
      fileName: map['file_name'] ?? '',
      storagePath: map['storage_path'] ?? '',
      classNumber: _readClassNumber(
        map['class_number'] ?? map['class_name'] ?? map['class'],
      ),
      section: map['section'] ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  static int? _readClassNumber(dynamic value) {
    if (value is int && value >= 1 && value <= 12) return value;

    final parsed = int.tryParse((value ?? '').toString().trim());
    if (parsed == null || parsed < 1 || parsed > 12) return null;
    return parsed;
  }
}

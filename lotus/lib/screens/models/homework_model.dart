class HomeworkModel {
  final String id;
  final String subject;
  final String fileType; // normalized: pdf | doc | excel
  final String fileName;
  final String storagePath;
  final DateTime createdAt;

  HomeworkModel({
    required this.id,
    required this.subject,
    required this.fileType,
    required this.fileName,
    required this.storagePath,
    required this.createdAt,
  });

  factory HomeworkModel.fromMap(Map<String, dynamic> map) {
    return HomeworkModel(
      id: map['id']?.toString() ?? '',
      subject: map['subject'] ?? '',
      fileType: map['file_type'] ?? '',
      fileName: map['file_name'] ?? '',
      storagePath: map['storage_path'] ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
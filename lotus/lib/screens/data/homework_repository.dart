import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/homework_model.dart';
import 'notificiation_services.dart';

class HomeworkRepository {
  HomeworkRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final NotificationService _notificationService = NotificationService();

  static const String _bucket = 'homework';
  static const Map<String, String> _folderSubjects = {
    'math': 'Math',
    'science': 'Science',
    'sst': 'SST',
    'english': 'English',
  };

  String? normalizeFileType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'pdf';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'doc';
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) return 'excel';
    return null;
  }

  String normalizeSubjectFolder(String subject) {
    final normalized = subject.trim().toLowerCase();
    return _folderSubjects.containsKey(normalized) ? normalized : 'general';
  }

  Future<bool> isAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final res = await _supabase
        .from('profiles')
        .select('is_admin')
        .eq('id', user.id)
        .maybeSingle();

    if (res == null) return false;
    return (res['is_admin'] as bool?) ?? false;
  }

  Future<HomeworkModel> uploadHomeworkFile({
    required String fileName,
    required String subject,
    required String localPath,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }

    final fileType = normalizeFileType(fileName);
    if (fileType == null) {
      throw ArgumentError('Unsupported file type');
    }

    final storagePath =
        '${normalizeSubjectFolder(subject)}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final file = File(localPath);
    if (!await file.exists()) {
      throw ArgumentError('File does not exist at path');
    }

    await _supabase.storage
        .from(_bucket)
        .upload(storagePath, file, fileOptions: const FileOptions());

    // Insert homework metadata row.
    final insertRes = await _supabase
        .from('homework')
        .upsert({
      'subject':
      _folderSubjects[normalizeSubjectFolder(subject)] ?? subject,
      'file_type': fileType,
      'file_name': fileName,
      'storage_path': storagePath,
      'uploaded_by': user.id,
    }, onConflict: 'storage_path')
        .select()
        .maybeSingle();

    if (insertRes == null) {
      throw StateError('Failed to create homework row');
    }

    final homework = HomeworkModel.fromMap(insertRes);

    await _notificationService.createHomeworkNotifications(
      title: 'New Homework Added',
      subtitle: 'Subject: $subject • ${fileType.toUpperCase()} file: $fileName',
      homeworkId: homework.id,
    );

    return homework;
  }

  Future<List<HomeworkModel>> listHomeworks({
    String? subject,
    String? fileType, // normalized pdf/doc/excel
  }) async {
    await syncStorageMetadata();

    // MVP-safe filtering without relying on eq() builder methods.
    final res = await _supabase
        .from('homework')
        .select('*')
        .order('created_at', ascending: false);

    final data = res as List<dynamic>;

    return data
        .map((e) => HomeworkModel.fromMap(e as Map<String, dynamic>))
        .where((h) {
      final subjectOk =
          subject == null || subject == 'All' || h.subject == subject;
      final fileTypeOk =
          fileType == null || fileType == 'All' || h.fileType == fileType;
      return subjectOk && fileTypeOk;
    })
        .toList();
  }

  Future<void> syncStorageMetadata() async {
    try {
      // The SQL file creates this RPC. It backfills table rows for files that
      // were uploaded directly in Supabase Storage before/without app upload.
      await _supabase.rpc('sync_homework_storage');
    } on PostgrestException catch (e) {
      if (e.code == '42883' || e.message.contains('sync_homework_storage')) {
        return;
      }

      rethrow;
    }
  }

  String getFileUrl({required String storagePath}) {
    final url = _supabase.storage.from(_bucket).getPublicUrl(storagePath);
    return url;
  }

  Future<String> getDownloadUrl({required String storagePath}) async {
    try {
      return await _supabase.storage
          .from(_bucket)
          .createSignedUrl(storagePath, 60 * 60, transform: null);
    } catch (_) {
      return getFileUrl(storagePath: storagePath);
    }
  }
}
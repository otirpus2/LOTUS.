import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/class_scope.dart';
import '../models/homework_model.dart';

class ClassManagementRepository {
  ClassManagementRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return user.id;
  }

  Future<ClassScope> getCurrentClassScope() async {
    final row = await _supabase
        .from('profiles')
        .select('class, section')
        .eq('id', _currentUserId)
        .maybeSingle();

    if (row == null) {
      return const ClassScope(classNumber: null, className: '', section: '');
    }

    return ClassScope.fromProfile(row);
  }

  Stream<ClassScope> watchCurrentClassScope() {
    final userId = _currentUserId;

    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
          if (rows.isEmpty) {
            return const ClassScope(
              classNumber: null,
              className: '',
              section: '',
            );
          }

          return ClassScope.fromProfile(rows.first);
        });
  }

  Stream<List<HomeworkModel>> watchClassHomeworks({
    required ClassScope scope,
    String? subject,
    String? fileType,
  }) {
    if (!scope.isAssigned) {
      return Stream.value(const <HomeworkModel>[]);
    }

    return _supabase
        .from('homework')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          return rows.map(HomeworkModel.fromMap).where((homework) {
            final classOk =
                homework.className.isEmpty ||
                scope.matches(
                  className: homework.className,
                  section: homework.section,
                );
            final sectionOk =
                scope.section.isEmpty ||
                homework.section.isEmpty ||
                homework.section == scope.section;
            final subjectOk =
                subject == null ||
                subject == 'All' ||
                homework.subject == subject;
            final fileTypeOk =
                fileType == null ||
                fileType == 'All' ||
                homework.fileType == fileType;
            return classOk && sectionOk && subjectOk && fileTypeOk;
          }).toList();
        });
  }
}

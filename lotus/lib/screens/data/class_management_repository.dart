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
        .select('class_id, class_rooms(name, section)')
        .eq('id', _currentUserId)
        .maybeSingle();

    if (row == null) {
      return const ClassScope(classId: null, className: null, section: '');
    }

    return ClassScope.fromProfile(row);
  }

  Stream<ClassScope> watchCurrentClassScope() {
    final userId = _currentUserId;

    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .asyncMap((rows) async {
          if (rows.isEmpty) {
            return const ClassScope(classId: null, className: null, section: '');
          }
          final row = rows.first;
          
          if (row['class_id'] != null) {
            final classRoom = await _supabase
                .from('class_rooms')
                .select('name, section')
                .eq('id', row['class_id'])
                .maybeSingle();
            row['class_rooms'] = classRoom;
          }
          
          return ClassScope.fromProfile(row);
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

    dynamic query = _supabase.from('homework').stream(primaryKey: ['id']);
    
    query = query.eq('class_id', scope.classId!);

    return (query as SupabaseStreamBuilder).order('created_at', ascending: false)
        .map((rows) {
          return rows.map(HomeworkModel.fromMap).where((homework) {
            final subjectOk =
                subject == null ||
                subject == 'All' ||
                homework.subject == subject;
            final fileTypeOk =
                fileType == null ||
                fileType == 'All' ||
                homework.fileType == fileType;
            return subjectOk && fileTypeOk;
          }).toList();
        });
  }
}

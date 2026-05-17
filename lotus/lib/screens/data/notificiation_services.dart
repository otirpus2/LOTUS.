import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> createHomeworkNotifications({
    required String title,
    required String subtitle,
    required String homeworkId,
    required String classId,
  }) async {
    final authUser = _supabase.auth.currentUser;

    final profiles = await _supabase
        .from('profiles')
        .select('id')
        .eq('class_id', classId);

    final List<dynamic> rows = profiles as List<dynamic>;

    final inserts = <Map<String, dynamic>>[];
    for (final row in rows) {
      inserts.add({
        'user_id': row['id'],
        'title': title,
        'subtitle': subtitle,
        'type': 'homework_uploaded',
        'entity_type': 'homework',
        'entity_id': homeworkId,
        'created_at': DateTime.now().toIso8601String(),
        'created_by': authUser?.id,
      });
    }

    if (inserts.isEmpty) return;

    // Insert in chunks to avoid request size limits.
    const int chunkSize = 50;
    for (var i = 0; i < inserts.length; i += chunkSize) {
      final chunk = inserts.sublist(
        i,
        (i + chunkSize) > inserts.length ? inserts.length : (i + chunkSize),
      );

      await _supabase.from('notifications').insert(chunk);
    }
  }
}

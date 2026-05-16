import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> createHomeworkNotifications({
    required String title,
    required String subtitle,
    required String homeworkId,
    required String className,
    String section = '',
  }) async {
    final authUser = _supabase.auth.currentUser;

    var query = _supabase.from('profiles').select('id').eq('class', className);

    if (section.trim().isNotEmpty) {
      query = query.eq('section', section.trim());
    }

    final profiles = await query.order('id', ascending: true);

    final List<dynamic> rows = profiles as List<dynamic>;

    final inserts = <Map<String, dynamic>>[];
    for (final row in rows) {
      inserts.add({
        'user_id': row['id'],
        'title': title,
        'subtitle': subtitle,
        'type': 'homework_uploaded',
        'homework_id': homeworkId,
        'class_name': className,
        'section': section.trim(),
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

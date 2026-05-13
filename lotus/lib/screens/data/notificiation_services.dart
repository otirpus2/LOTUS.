import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> createHomeworkNotifications({
    required String title,
    required String subtitle,
    required String homeworkId,
  }) async {
    final authUser = _supabase.auth.currentUser;

    // Fetch all users (MVP). Supabase auth users are not directly queryable
    // with the client for security reasons, but for testing we assume a
    // `profiles` table exists that mirrors auth users.
    //
    // If your `profiles` table doesn't exist yet, create it as described in TODO.md.
    final profiles = await _supabase
        .from('profiles')
        .select('id')
        .order('id', ascending: true);

    final List<dynamic> rows = profiles as List<dynamic>;

    final inserts = <Map<String, dynamic>>[];
    for (final row in rows) {
      inserts.add({
        'user_id': row['id'],
        'title': title,
        'subtitle': subtitle,
        'type': 'homework_uploaded',
        'homework_id': homeworkId,
        'created_at': DateTime.now().toIso8601String(),
        // optional: track who triggered
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
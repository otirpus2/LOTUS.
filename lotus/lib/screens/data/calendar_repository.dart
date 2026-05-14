import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/calendar_event.dart';

class CalendarRepository {
  CalendarRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return user.id;
  }

  Stream<CalendarAudienceScope> watchCurrentAudienceScope() {
    final userId = _currentUserId;

    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) {
          final row = rows.isEmpty ? null : rows.first;
          return CalendarAudienceScope.fromProfile(userId: userId, map: row);
        });
  }

  Stream<List<CalendarEvent>> watchVisibleEvents({
    required CalendarAudienceScope audience,
  }) {
    return _supabase
        .from('calendar_events')
        .stream(primaryKey: ['id'])
        .order('event_date', ascending: true)
        .map((rows) {
          final events = rows
              .map((row) => CalendarEvent.fromMap(row))
              .where((event) => event.isVisibleFor(audience))
              .toList();

          events.sort((a, b) {
            final byDate = a.eventDate.compareTo(b.eventDate);
            if (byDate != 0) return byDate;
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });

          return events;
        });
  }
}

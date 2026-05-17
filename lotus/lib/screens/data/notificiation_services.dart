import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Generic method to create notifications for one or more users
  Future<void> createNotifications({
    required List<String> targetUserIds,
    required String title,
    required String subtitle,
    required String type,
    String? entityType,
    String? entityId,
  }) async {
    if (targetUserIds.isEmpty) return;

    final authUser = _supabase.auth.currentUser;
    final timestamp = DateTime.now().toUtc().toIso8601String();

    final List<Map<String, dynamic>> inserts = targetUserIds.map((userId) {
      return {
        'user_id': userId,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'entity_type': entityType,
        'entity_id': entityId,
        'is_read': false,
        'created_at': timestamp,
        'created_by': authUser?.id,
      };
    }).toList();

    try {
      const int chunkSize = 50;
      for (var i = 0; i < inserts.length; i += chunkSize) {
        final chunk = inserts.sublist(
          i,
          (i + chunkSize) > inserts.length ? inserts.length : (i + chunkSize),
        );
        await _supabase.from('notifications').insert(chunk);
      }
    } catch (e) {
      debugPrint('Error creating notifications: $e');
    }
  }

  /// Specific helper for homework
  Future<void> createHomeworkNotifications({
    required String title,
    required String subtitle,
    required String homeworkId,
    required String classId,
  }) async {
    final profiles = await _supabase
        .from('profiles')
        .select('id')
        .eq('class_id', classId);

    final List<String> ids = (profiles as List).map((row) => row['id'] as String).toList();
    
    await createNotifications(
      targetUserIds: ids,
      title: title,
      subtitle: subtitle,
      type: 'homework_uploaded',
      entityType: 'homework',
      entityId: homeworkId,
    );
  }

  /// Specific helper for friend requests
  Future<void> createFriendRequestNotification({
    required String receiverId,
    required String senderName,
  }) async {
    await createNotifications(
      targetUserIds: [receiverId],
      title: 'New Friend Request',
      subtitle: '$senderName sent you a friend request.',
      type: 'friend_request',
      entityType: 'friendship',
    );
  }

  /// Specific helper for new messages
  Future<void> createMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageContent,
  }) async {
    await createNotifications(
      targetUserIds: [receiverId],
      title: 'New Message from $senderName',
      subtitle: messageContent,
      type: 'new_message',
      entityType: 'chat',
    );
  }

  /// Specific helper for alerts (Reports/Test Results/Warnings)
  Future<void> createAlertNotification({
    required List<String> targetUserIds,
    required String title,
    required String subtitle,
    required String type, // 'report_warning', 'test_result'
  }) async {
    await createNotifications(
      targetUserIds: targetUserIds,
      title: title,
      subtitle: subtitle,
      type: type,
    );
  }
}

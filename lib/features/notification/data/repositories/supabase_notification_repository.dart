import '../../../../core/network/supabase_service.dart';
import '../../../../core/utils/borrowly_logger.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  NotificationEntity _mapRowToEntity(Map<String, dynamic> row) {
    final typeStr = row['type'] as String? ?? 'system';
    final type = NotificationType.values.firstWhere(
      (t) => t.name.toLowerCase() == typeStr.toLowerCase(),
      orElse: () => NotificationType.system,
    );

    return NotificationEntity(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? 'Notification',
      body: row['body'] as String? ?? '',
      type: type,
      timestamp: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      isRead: row['is_read'] as bool? ?? false,
      targetRoute: row['target_route'] as String?,
    );
  }

  @override
  Future<List<NotificationEntity>> getNotifications(String userId) async {
    BorrowlyLogger.event('Notification: Fetch Notifications', parameters: {'userId': userId});
    if (userId == 'guest_user_id' || userId.length != 36 || !userId.contains('-')) {
      return [];
    }

    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client
            .from('notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapRowToEntity(r as Map<String, dynamic>)).toList();
      } catch (e) {
        BorrowlyLogger.warning('getNotifications error: $e');
      }
    }

    return [];
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    BorrowlyLogger.event('Notification: Mark As Read', parameters: {'notificationId': notificationId});
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('id', notificationId);
      } catch (e) {
        BorrowlyLogger.warning('markAsRead error: $e');
      }
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    BorrowlyLogger.event('Notification: Mark All As Read', parameters: {'userId': userId});
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('user_id', userId);
      } catch (e) {
        BorrowlyLogger.warning('markAllAsRead error: $e');
      }
    }
  }
}

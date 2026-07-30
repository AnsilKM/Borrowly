import 'package:flutter/foundation.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import 'mock_notification_repository.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  final MockNotificationRepository _fallbackMockRepo = MockNotificationRepository();

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
        debugPrint('Supabase getNotifications fallback to local: $e');
      }
    }

    return _fallbackMockRepo.getNotifications(userId);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('id', notificationId);
        return;
      } catch (e) {
        debugPrint('Supabase markAsRead fallback to local: $e');
      }
    }

    return _fallbackMockRepo.markAsRead(notificationId);
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        await client.from('notifications').update({'is_read': true}).eq('user_id', userId);
        return;
      } catch (e) {
        debugPrint('Supabase markAllAsRead fallback to local: $e');
      }
    }

    return _fallbackMockRepo.markAllAsRead(userId);
  }
}

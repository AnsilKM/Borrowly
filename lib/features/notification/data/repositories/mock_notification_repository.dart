import 'package:borrowly/features/notification/domain/entities/notification_entity.dart';
import 'package:borrowly/features/notification/domain/repositories/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  final List<NotificationEntity> _notifications = [
    NotificationEntity(
      id: 'notif_1',
      title: 'Borrow Request Approved!',
      body: 'Marcus Vance approved your request for DeWalt Cordless Drill. Coordinate physical meetup.',
      type: NotificationType.request,
      isRead: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      targetRoute: '/activity',
    ),
    NotificationEntity(
      id: 'notif_2',
      title: 'New Message from Sarah',
      body: 'Thanks for returning the tent in great shape!',
      type: NotificationType.chat,
      isRead: false,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      targetRoute: '/chat/conv_2',
    ),
    NotificationEntity(
      id: 'notif_3',
      title: 'Welcome to Borrowly Neighborhood!',
      body: 'Your 5 km search radius is active. Start sharing tools and camping equipment with neighbors.',
      type: NotificationType.system,
      isRead: true,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      targetRoute: '/',
    ),
  ];

  @override
  Future<List<NotificationEntity>> getNotifications(String userId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _notifications;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:borrowly/features/notification/data/repositories/supabase_notification_repository.dart';
import 'package:borrowly/features/notification/domain/entities/notification_entity.dart';
import 'package:borrowly/features/notification/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository();
});

final notificationsProvider = FutureProvider<List<NotificationEntity>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications('guest_user_id');
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final asyncVal = ref.watch(notificationsProvider);
  return asyncVal.when(
    data: (list) => list.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

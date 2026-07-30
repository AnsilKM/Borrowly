import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/widgets/borrowly_empty_state.dart';
import 'package:borrowly/features/notification/domain/entities/notification_entity.dart';
import 'package:borrowly/features/notification/presentation/providers/notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.request:
        return Icons.handshake_outlined;
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notificationsAsync = ref.watch(notificationsProvider);
    final repo = ref.read(notificationRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Neighborhood Notifications', style: AppTypography.headingMedium(isDark)),
        actions: [
          TextButton(
            onPressed: () async {
              await repo.markAllAsRead('guest_user_id');
              ref.invalidate(notificationsProvider);
            },
            child: Text('Mark All Read', style: AppTypography.bodySmall(isDark).copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: SafeArea(
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const Center(
                child: BorrowlyEmptyState(
                  title: 'No Notifications Yet',
                  description: 'Alerts regarding borrow requests, messages, and updates will show up here.',
                  icon: Icons.notifications_none_outlined,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = notifications[index];

                return BorrowlyCard(
                  variant: item.isRead ? BorrowlyCardVariant.flat : BorrowlyCardVariant.outlined,
                  onTap: () async {
                    await repo.markAsRead(item.id);
                    ref.invalidate(notificationsProvider);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs + 2),
                        decoration: BoxDecoration(
                          color: item.isRead
                              ? (isDark ? AppColors.darkSurface : AppColors.surface)
                              : AppColors.primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(item.type),
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(item.title, style: AppTypography.headingSmall(isDark)),
                                ),
                                if (!item.isRead)
                                  const BorrowlyBadge(label: 'NEW', variant: BorrowlyBadgeVariant.primary),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(item.body, style: AppTypography.bodyMedium(isDark)),
                            const SizedBox(height: 6),
                            Text(
                              '${item.timestamp.hour}:${item.timestamp.minute.toString().padLeft(2, "0")}',
                              style: AppTypography.bodySmall(isDark).copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: BorrowlyEmptyState(title: 'Error loading notifications', description: err.toString(), icon: Icons.error_outline),
          ),
        ),
      ),
    );
  }
}

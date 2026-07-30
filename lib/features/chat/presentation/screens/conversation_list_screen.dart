import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/widgets/borrowly_empty_state.dart';
import 'package:borrowly/features/chat/presentation/providers/chat_provider.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Neighbor Messages', style: AppTypography.headingMedium(isDark)),
      ),
      body: SafeArea(
        child: conversationsAsync.when(
          data: (conversations) {
            if (conversations.isEmpty) {
              return const Center(
                child: BorrowlyEmptyState(
                  title: 'No Active Messages',
                  description: 'Start borrowing or lending items to message local neighbors.',
                  icon: Icons.chat_bubble_outline,
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final conv = conversations[index];

                return BorrowlyCard(
                  variant: BorrowlyCardVariant.outlined,
                  onTap: () {
                    context.push('/chat/${conv.id}?title=${Uri.encodeComponent(conv.otherParticipantName)}&item=${Uri.encodeComponent(conv.itemTitle)}');
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: conv.otherParticipantAvatar != null ? NetworkImage(conv.otherParticipantAvatar!) : null,
                        child: conv.otherParticipantAvatar == null
                            ? Text(conv.otherParticipantName[0], style: const TextStyle(fontWeight: FontWeight.bold))
                            : null,
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
                                  child: Text(
                                    conv.otherParticipantName,
                                    style: AppTypography.headingSmall(isDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${conv.lastMessageTime.hour}:${conv.lastMessageTime.minute.toString().padLeft(2, "0")}',
                                  style: AppTypography.bodySmall(isDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            BorrowlyBadge(label: conv.itemTitle, variant: BorrowlyBadgeVariant.neutral),
                            const SizedBox(height: 4),
                            Text(
                              conv.lastMessage,
                              style: AppTypography.bodyMedium(isDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
            child: BorrowlyEmptyState(title: 'Error loading chats', description: err.toString(), icon: Icons.error_outline),
          ),
        ),
      ),
    );
  }
}

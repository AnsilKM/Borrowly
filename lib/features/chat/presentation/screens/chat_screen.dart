import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/chat/presentation/providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String participantName;
  final String itemTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.participantName,
    required this.itemTitle,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = ref.watch(chatControllerProvider(widget.conversationId));
    final chatController = ref.read(chatControllerProvider(widget.conversationId).notifier);
    final user = ref.watch(authProvider).user;
    final currentUserId = user?.id ?? 'guest_user_id';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.participantName,
              style: AppTypography.headingMedium(isDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Item: ${widget.itemTitle}',
              style: AppTypography.bodySmall(isDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: BorrowlyBadge(label: 'Physical Handover', variant: BorrowlyBadgeVariant.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == currentUserId;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.primary
                            : (isDark ? AppColors.darkSurface : AppColors.surfaceSubtle),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(AppRadii.md),
                          topRight: const Radius.circular(AppRadii.md),
                          bottomLeft: Radius.circular(isMe ? AppRadii.md : 2),
                          bottomRight: Radius.circular(isMe ? 2 : AppRadii.md),
                        ),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isMe ? AppColors.textPrimary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, "0")}',
                            style: TextStyle(
                              color: isMe ? Colors.black54 : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Chat Input Bar
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: AppTypography.bodyMedium(isDark),
                      decoration: const InputDecoration(
                        hintText: 'Type a message to coordinate meetup...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: () {
                      if (_textController.text.isNotEmpty) {
                        chatController.sendTextMessage(
                          text: _textController.text,
                          senderId: currentUserId,
                          senderName: user?.fullName ?? 'Alex Morgan',
                        );
                        _textController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

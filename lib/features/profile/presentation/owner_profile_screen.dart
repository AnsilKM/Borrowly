import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/utils/avatar_provider_util.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';
import 'package:borrowly/features/item/presentation/widgets/item_card.dart';

class OwnerProfileScreen extends ConsumerWidget {
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final String? itemTitle;

  const OwnerProfileScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    this.itemTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nearbyItemsAsync = ref.watch(nearbyItemsProvider);
    final authUser = ref.watch(authProvider).user;

    final isCurrentUser = authUser != null &&
        !authUser.isGuest &&
        (ownerId == authUser.id || ownerId == '00000000-0000-0000-0000-000000000001');

    final displayName = (isCurrentUser && authUser.fullName.isNotEmpty)
        ? authUser.fullName
        : (ownerName.isNotEmpty ? ownerName : 'Neighbor Owner');

    final displayAvatar = isCurrentUser
        ? authUser.displayAvatarUrl
        : (ownerAvatar != null && ownerAvatar!.isNotEmpty ? ownerAvatar : 'assets/icons/app_icon.png');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Owner Profile',
          style: AppTypography.headingMedium(isDark).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.share_outlined,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            onPressed: () async {
              final shareUrl = 'https://AnsilKM.github.io/Borrowly/?owner=$ownerId';
              await Share.share(
                'Check out $displayName\'s profile and listings on Borrowly!\n$shareUrl',
                subject: '$displayName\'s Borrowly Profile',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Identity Header Card
              BorrowlyCard(
                variant: BorrowlyCardVariant.warm,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2.5),
                            boxShadow: AppShadows.medium,
                          ),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            backgroundImage: getAvatarImageProvider(displayAvatar),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      displayName,
                      style: AppTypography.headingLarge(isDark).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '4.9 (24 neighborhood reviews)',
                          style: AppTypography.bodyMedium(isDark).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BorrowlyBadge(
                          label: 'Verified Owner',
                          variant: BorrowlyBadgeVariant.success,
                          icon: Icon(Icons.verified_user_rounded),
                        ),
                        SizedBox(width: AppSpacing.xs + 2),
                        BorrowlyBadge(
                          label: '< 15 min reply',
                          variant: BorrowlyBadgeVariant.distance,
                          icon: Icon(Icons.bolt_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Direct Connect Action Container
              Text(
                'Direct Connection',
                style: AppTypography.labelText(isDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              BorrowlyCard(
                variant: BorrowlyCardVariant.elevated,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_chat_read_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instant Neighbor Chat',
                                style: AppTypography.headingSmall(isDark).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Direct messaging available to negotiate handover & availability.',
                                style: AppTypography.bodySmall(isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: BorrowlyButton(
                            label: 'Direct Chat with $displayName',
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                            variant: BorrowlyButtonVariant.primary,
                            isFullWidth: true,
                            onPressed: () {
                              ref.read(authProvider.notifier).executeProtectedAction(
                                context,
                                actionTitle: 'Connect with $displayName',
                                onAuthenticated: () {
                                  final itemQuery = itemTitle != null ? '&item=${Uri.encodeComponent(itemTitle!)}' : '';
                                  context.push(
                                    '/chat/$ownerId?title=${Uri.encodeComponent(displayName)}$itemQuery',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Items Shared by this Owner
              Text(
                'Listings by $displayName',
                style: AppTypography.headingMedium(isDark).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              nearbyItemsAsync.when(
                data: (items) {
                  final ownerItems = items
                      .where((item) => item.ownerId == ownerId || item.ownerName.toLowerCase() == displayName.toLowerCase())
                      .toList();

                  if (ownerItems.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: AppRadii.borderLg,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 8),
                          Text(
                            'No active listings visible right now',
                            style: AppTypography.bodyMedium(isDark),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: ownerItems.length,
                    itemBuilder: (context, index) {
                      return ItemCard(item: ownerItems[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, _) => Text('Could not load listings', style: AppTypography.bodySmall(isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

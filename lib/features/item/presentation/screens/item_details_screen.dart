import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:borrowly/core/widgets/borrowly_empty_state.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/borrow/presentation/widgets/request_borrow_bottom_sheet.dart';
import 'package:borrowly/features/item/domain/entities/item_entity.dart';
import 'package:borrowly/features/item/domain/usecases/get_item_details_usecase.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';
import 'package:borrowly/features/item/presentation/providers/wishlist_provider.dart';

final getItemDetailsUseCaseProvider = Provider<GetItemDetailsUseCase>((ref) {
  return GetItemDetailsUseCase(ref.watch(itemRepositoryProvider));
});

final itemDetailsProvider = FutureProvider.family<ItemEntity?, String>((ref, itemId) async {
  final usecase = ref.watch(getItemDetailsUseCaseProvider);
  final result = await usecase(itemId);
  return result.fold(
    onSuccess: (item) => item,
    onError: (failure) => throw Exception(failure.message),
  );
});

class ItemDetailsScreen extends ConsumerStatefulWidget {
  final String itemId;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
  });

  @override
  ConsumerState<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends ConsumerState<ItemDetailsScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemAsync = ref.watch(itemDetailsProvider(widget.itemId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: itemAsync.when(
        data: (item) {
          if (item == null) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: BorrowlyEmptyState(
                  title: 'Item Not Found',
                  description: 'This listing may have been removed by the owner.',
                  icon: Icons.search_off_outlined,
                ),
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Full-Bleed Hero Image Carousel
                    Stack(
                      children: [
                        SizedBox(
                          height: 360,
                          child: PageView.builder(
                            itemCount: item.images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final imgStr = item.images[index];
                              final isNetworkUrl = imgStr.startsWith('http://') || imgStr.startsWith('https://');

                              if (isNetworkUrl) {
                                return CachedNetworkImage(
                                  imageUrl: imgStr,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                    child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                    child: const Icon(Icons.broken_image, size: 50, color: AppColors.textMuted),
                                  ),
                                );
                              }

                              return Image.file(
                                File(imgStr),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                  child: const Icon(Icons.broken_image, size: 50, color: AppColors.textMuted),
                                ),
                              );
                            },
                          ),
                        ),

                        // Gradient bottom vignette overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Back Floating Button
                        Positioned(
                          top: MediaQuery.of(context).padding.top + AppSpacing.xs,
                          left: AppSpacing.md,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),

                        // Share & Wishlist Favorite Buttons
                        Positioned(
                          top: MediaQuery.of(context).padding.top + AppSpacing.xs,
                          right: AppSpacing.md,
                          child: Consumer(
                            builder: (context, ref, child) {
                              final isWishlisted = ref.watch(isItemWishlistedProvider(item.id));
                              return Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                                      onPressed: () async {
                                        final shareUrl = 'https://AnsilKM.github.io/Borrowly/?item=${item.id}';
                                        final shareText = 'Check out "${item.title}" available for borrow on Borrowly!\n$shareUrl';
                                        await Share.share(
                                          shareText,
                                          subject: 'Borrow ${item.title} on Borrowly',
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isWishlisted ? AppColors.danger : Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        ref.read(wishlistIdsProvider.notifier).toggleWishlist(item.id);
                                        BorrowlyToast.show(
                                          context,
                                          isWishlisted ? 'Removed from Wishlist' : 'Saved to Wishlist!',
                                          icon: isWishlisted ? Icons.favorite_border_rounded : Icons.favorite_rounded,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Page Indicator Dots
                        if (item.images.length > 1)
                          Positioned(
                            bottom: AppSpacing.lg,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                item.images.length,
                                (idx) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentImageIndex == idx ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == idx ? AppColors.primary : Colors.white70,
                                    borderRadius: AppRadii.borderFull,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // 2. Overlapping Glass Summary Header Card
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: BorrowlyCard(
                          variant: BorrowlyCardVariant.warm,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  BorrowlyBadge(
                                    label: item.category.label,
                                    variant: BorrowlyBadgeVariant.primary,
                                  ),
                                  const Spacer(),
                                  BorrowlyBadge(
                                    label: item.formattedDistance,
                                    variant: BorrowlyBadgeVariant.distance,
                                    icon: const Icon(Icons.near_me_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                item.title,
                                style: AppTypography.displayLarge(isDark).copyWith(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs + 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    item.formattedPrice,
                                    style: AppTypography.displayLarge(isDark).copyWith(
                                      fontSize: 24,
                                      color: item.isFree ? AppColors.success : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  if (item.depositAmount > 0)
                                    Text(
                                      '\$${item.depositAmount.toStringAsFixed(0)} deposit',
                                      style: AppTypography.bodyMedium(isDark).copyWith(
                                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${item.ratingScore.toStringAsFixed(1)} ',
                                        style: AppTypography.headingSmall(isDark).copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '(${item.reviewCount})',
                                        style: AppTypography.bodySmall(isDark),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. About This Item Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About this item',
                            style: AppTypography.headingMedium(isDark).copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs + 2),
                          BorrowlyCard(
                            variant: BorrowlyCardVariant.elevated,
                            padding: const EdgeInsets.all(AppSpacing.md + 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: AppTypography.bodyLarge(isDark).copyWith(
                                    fontSize: 14.5,
                                    height: 1.5,
                                  ),
                                ),
                                const Divider(height: AppSpacing.lg),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Item Condition',
                                      style: AppTypography.bodyMedium(isDark).copyWith(
                                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                      ),
                                    ),
                                    const BorrowlyBadge(
                                      label: 'Excellent',
                                      variant: BorrowlyBadgeVariant.success,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Interactive Owner Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner & Handover',
                            style: AppTypography.headingMedium(isDark).copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs + 2),
                          BorrowlyCard(
                            variant: BorrowlyCardVariant.elevated,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            onTap: () {
                              final avatarParam = item.ownerAvatar != null ? '&avatar=${Uri.encodeComponent(item.ownerAvatar!)}' : '';
                              context.push(
                                '/owner/${item.ownerId}?name=${Uri.encodeComponent(item.ownerName)}$avatarParam&item=${Uri.encodeComponent(item.title)}',
                              );
                            },
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                      backgroundImage: item.ownerAvatar != null ? NetworkImage(item.ownerAvatar!) : null,
                                      child: item.ownerAvatar == null
                                          ? Text(
                                              item.ownerName.isNotEmpty ? item.ownerName[0] : 'O',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.ownerName,
                                            style: AppTypography.headingSmall(isDark).copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.primary),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '4.9 ⭐ • Reply time < 15 mins',
                                        style: AppTypography.bodySmall(isDark),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 5. In-Person Settlement Policy Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: BorrowlyCard(
                        variant: BorrowlyCardVariant.warm,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_outlined, color: AppColors.warning, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'In-Person Cash Settlement',
                                    style: AppTypography.headingSmall(isDark).copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Pay fee & deposit directly during physical handover.',
                                    style: AppTypography.bodySmall(isDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),

              // 6. Floating Glass Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: BorrowlyButton(
                            label: 'Chat',
                            variant: BorrowlyButtonVariant.secondary,
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                            onPressed: () {
                              ref.read(authProvider.notifier).executeProtectedAction(
                                context,
                                actionTitle: 'Chat with ${item.ownerName}',
                                onAuthenticated: () {
                                  context.push(
                                    '/chat/${item.id}?title=${Uri.encodeComponent(item.ownerName)}&item=${Uri.encodeComponent(item.title)}',
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 3,
                          child: BorrowlyButton(
                            label: 'Request to Borrow',
                            variant: BorrowlyButtonVariant.primary,
                            onPressed: () {
                              ref.read(authProvider.notifier).executeProtectedAction(
                                context,
                                actionTitle: 'Borrow "${item.title}"',
                                onAuthenticated: () {
                                  RequestBorrowBottomSheet.show(context, item: item);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, _) => Center(
          child: BorrowlyEmptyState(
            title: 'Error Loading Details',
            description: error.toString(),
            icon: Icons.error_outline,
          ),
        ),
      ),
    );
  }
}

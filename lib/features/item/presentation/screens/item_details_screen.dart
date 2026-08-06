import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:borrowly/app/router/routes.dart';
import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/utils/borrowly_logger.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/widgets/borrowly_empty_state.dart';
import 'package:borrowly/core/widgets/borrowly_image_preview_modal.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';
import 'package:borrowly/core/utils/avatar_provider_util.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/borrow/presentation/widgets/request_borrow_bottom_sheet.dart';
import 'package:borrowly/features/item/domain/entities/item_entity.dart';
import 'package:borrowly/features/item/domain/usecases/get_item_details_usecase.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';
import 'package:borrowly/features/item/presentation/providers/wishlist_provider.dart';
import 'add_item_screen.dart';

final getItemDetailsUseCaseProvider = Provider<GetItemDetailsUseCase>((ref) {
  return GetItemDetailsUseCase(ref.watch(itemRepositoryProvider));
});

final itemDetailsProvider = FutureProvider.family<ItemEntity?, String>((ref, itemId) async {
  BorrowlyLogger.event('ItemDetails: Fetch Started', parameters: {'itemId': itemId});
  final usecase = ref.watch(getItemDetailsUseCaseProvider);
  final result = await usecase(itemId);
  final item = result.fold(
    onSuccess: (item) => item,
    onError: (failure) {
      BorrowlyLogger.error('ItemDetails: UseCase returned error', failure.message);
      throw Exception(failure.message);
    },
  );

  if (item != null) {
    BorrowlyLogger.info('✅ ItemDetails: Item loaded successfully on first try → "${item.title}" (${item.id})');
    return item;
  }

  // If null on first attempt, Supabase auth session may not have been
  // restored yet (cold-start via deep link). Retry once after a short delay.
  BorrowlyLogger.warning('⚠️ ItemDetails: item is null on first load (itemId=$itemId) — auth session may not be ready. Retrying in 1.5s...');
  await Future.delayed(const Duration(milliseconds: 1500));

  BorrowlyLogger.info('🔄 ItemDetails: Retrying fetch for itemId=$itemId...');
  final retry = await usecase(itemId);
  return retry.fold(
    onSuccess: (retryItem) {
      if (retryItem != null) {
        BorrowlyLogger.info('✅ ItemDetails: Retry succeeded → "${retryItem.title}" (${retryItem.id})');
      } else {
        BorrowlyLogger.error('ItemDetails: Retry also returned null — item truly does not exist for itemId=$itemId');
      }
      return retryItem;
    },
    onError: (failure) {
      BorrowlyLogger.error('ItemDetails: Retry also failed', failure.message);
      throw Exception(failure.message);
    },
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

    return PopScope(
      // When there is no route to pop back to (cold-start via deep link),
      // navigate to Home instead of exiting the app.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Log both GoRouter and Navigator canPop for diagnostics
        final routerCanPop = GoRouter.of(context).canPop();
        final navCanPop = Navigator.of(context).canPop();
        BorrowlyLogger.info(
          'ItemDetails: System back pressed | '
          'routerCanPop=$routerCanPop | navCanPop=$navCanPop',
        );
        if (routerCanPop) {
          BorrowlyLogger.info('ItemDetails: System back → popping to previous route');
          GoRouter.of(context).pop();
        } else {
          BorrowlyLogger.info('ItemDetails: System back → no back stack, going to home');
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        body: itemAsync.when(
          data: (item) {
            if (item == null) {
              BorrowlyLogger.warning('⚠️ ItemDetails: Rendering "Item Not Found" screen (item=null after retry)');
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
            BorrowlyLogger.info('🖼️ ItemDetails: Rendering item screen → "${item.title}"');

            final authState = ref.watch(authProvider);
            final currentUserId = authState.user?.id;
            final isOwner = currentUserId != null &&
                (currentUserId == item.ownerId ||
                 (item.ownerId == '00000000-0000-0000-0000-000000000001' && authState.isAuthenticated));

          return Stack(
            children: [
              Column(
                children: [
                  // 1. Fixed Top Hero Image Header (Fixed 340px height — stays completely stationary!)
                  SizedBox(
                    height: 340,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
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

                              Widget imgWidget;
                              if (isNetworkUrl) {
                                imgWidget = CachedNetworkImage(
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
                              } else {
                                imgWidget = Image.file(
                                  File(imgStr),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                    child: const Icon(Icons.broken_image, size: 50, color: AppColors.textMuted),
                                  ),
                                );
                              }

                              return GestureDetector(
                                onTap: () => BorrowlyImagePreviewModal.show(
                                  context,
                                  images: item.images,
                                  initialIndex: index,
                                  title: item.title,
                                ),
                                child: imgWidget,
                              );
                            },
                          ),
                        ),

                        // Gradient bottom vignette overlay
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.5),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.35),
                                  ],
                                ),
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
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                              onPressed: () {
                                final router = GoRouter.of(context);
                                if (router.canPop()) {
                                  router.pop();
                                } else {
                                  context.go(AppRoutes.home);
                                }
                              },
                            ),
                          ),
                        ),

                        // Share, Wishlist & Delete Top Buttons
                        Positioned(
                          top: MediaQuery.of(context).padding.top + AppSpacing.xs,
                          right: AppSpacing.md,
                          child: Consumer(
                            builder: (context, ref, child) {
                              final isWishlisted = ref.watch(isItemWishlistedProvider(item.id));
                              return Row(
                                children: [
                                  if (isOwner)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.danger,
                                          size: 20,
                                        ),
                                        tooltip: 'Delete Listing',
                                        onPressed: () {
                                          _showDeleteConfirmationDialog(context, ref, item);
                                        },
                                      ),
                                    ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
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
                                      color: Colors.black.withValues(alpha: 0.5),
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
                  ),

                  // 2. Scrollable Item Details Body Below Fixed Hero Header
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Overlapping Glass Summary Header Card
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
                                            '₹${item.depositAmount.toStringAsFixed(0)} deposit',
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

                          // 4. Interactive Owner Section (Hidden for owner's own listings)
                          if (!isOwner) ...[
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
                                        Builder(
                                          builder: (context) {
                                            final authUser = authState.user;
                                            final isOwnerItem = isOwner || (authUser != null && (item.ownerId == authUser.id || item.ownerId == '00000000-0000-0000-0000-000000000001'));
                                            final displayOwnerAvatar = isOwnerItem && authUser != null
                                                ? authUser.displayAvatarUrl
                                                : ((item.ownerAvatar != null && item.ownerAvatar!.isNotEmpty)
                                                    ? item.ownerAvatar!
                                                    : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(item.ownerName.isNotEmpty ? item.ownerName : "Neighbor")}&background=0D9488&color=ffffff&bold=true&size=200');

                                            return Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 26,
                                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                                  backgroundImage: getAvatarImageProvider(displayOwnerAvatar),
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
                                            );
                                          },
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Builder(
                                                    builder: (context) {
                                                      final authUser = authState.user;
                                                      final isOwnerItem = isOwner || (authUser != null && (item.ownerId == authUser.id || item.ownerId == '00000000-0000-0000-0000-000000000001'));
                                                      final displayOwnerName = isOwnerItem && authUser != null && authUser.fullName.isNotEmpty
                                                          ? authUser.fullName
                                                          : item.ownerName;

                                                      return Text(
                                                        displayOwnerName,
                                                        style: AppTypography.headingSmall(isDark).copyWith(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 16,
                                                        ),
                                                      );
                                                    },
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
                          ],

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
                                          const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 6. Tight Floating Glass Capsule Dock (Cream background height strictly matches button height!)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.darkSurface : AppColors.surfaceWarm).withValues(alpha: 0.88),
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.15) : AppColors.border.withValues(alpha: 0.6),
                            width: 1.0,
                          ),
                        ),
                        child: Builder(
                        builder: (context) {
                          final authState = ref.watch(authProvider);
                          final currentUserId = authState.user?.id;
                          final isOwner = currentUserId != null &&
                              (currentUserId == item.ownerId ||
                               (item.ownerId == '00000000-0000-0000-0000-000000000001' && authState.isAuthenticated));

                          if (isOwner) {
                            return Row(
                              children: [
                                // 1. Glassmorphic Edit Listing Button
                                Expanded(
                                  flex: 1,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => AddItemScreen(editItem: item),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.18),
                                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                                          border: Border.all(
                                            color: AppColors.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              color: AppColors.primary,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Edit Listing',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),

                                // 2. Pause / Mark Available Glass Button
                                Expanded(
                                  flex: 1,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                                      onTap: () {
                                         final isPausing = item.isAvailable;
                                         showDialog(
                                           context: context,
                                           builder: (dialogCtx) => AlertDialog(
                                             backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                                             shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
                                             title: Row(
                                               children: [
                                                 Icon(
                                                   isPausing ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                                   color: isPausing ? AppColors.accent : AppColors.primary,
                                                   size: 24,
                                                 ),
                                                 const SizedBox(width: 8),
                                                 Text(
                                                   isPausing ? 'Pause Listing?' : 'Mark as Available?',
                                                   style: AppTypography.headingMedium(isDark).copyWith(fontWeight: FontWeight.bold),
                                                 ),
                                               ],
                                             ),
                                             content: Text(
                                               isPausing
                                                   ? 'Are you sure you want to pause "${item.title}"? It will be marked as ON HOLD and hidden from neighbor searches until reactivated.'
                                                   : 'Are you sure you want to make "${item.title}" active and visible to nearby neighbors again?',
                                               style: AppTypography.bodyMedium(isDark),
                                             ),
                                             actions: [
                                               TextButton(
                                                 onPressed: () => Navigator.of(dialogCtx).pop(),
                                                 child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                                               ),
                                               ElevatedButton(
                                                 style: ElevatedButton.styleFrom(
                                                   backgroundColor: isPausing ? AppColors.accent : AppColors.primary,
                                                   foregroundColor: Colors.white,
                                                   shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
                                                 ),
                                                 onPressed: () async {
                                                   Navigator.of(dialogCtx).pop();
                                                   try {
                                                     final repo = ref.read(itemRepositoryProvider);
                                                     final newStatus = !item.isAvailable;
                                                      await repo.toggleItemAvailability(item.id, newStatus);
                                                      ref.invalidate(itemDetailsProvider(item.id));
                                                      ref.invalidateAllItemProviders();

                                                     if (context.mounted) {
                                                       BorrowlyToast.show(
                                                         context,
                                                         newStatus ? 'Listing Active & Visible to Neighbors' : 'Listing Paused (ON HOLD)',
                                                         icon: newStatus ? Icons.check_circle_outline : Icons.pause_circle_outline,
                                                       );
                                                     }
                                                   } catch (e) {
                                                     if (context.mounted) {
                                                       BorrowlyToast.show(context, 'Failed to update listing status: $e');
                                                     }
                                                   }
                                                 },
                                                 child: Text(isPausing ? 'Confirm Pause' : 'Confirm Active'),
                                               ),
                                             ],
                                           ),
                                         );
                                       },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: BoxDecoration(
                                          color: item.isAvailable
                                              ? AppColors.accent.withValues(alpha: 0.22)
                                              : AppColors.primary.withValues(alpha: 0.22),
                                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                                          border: Border.all(
                                            color: item.isAvailable ? AppColors.accent : AppColors.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              item.isAvailable ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                              color: item.isAvailable ? AppColors.accent : AppColors.primary,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              item.isAvailable ? 'Pause Listing' : 'Mark Available',
                                              style: TextStyle(
                                                color: item.isAvailable ? AppColors.accent : AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          // Neighbor / Borrower Standard Glass Action Bar
                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: BorrowlyButton(
                                  label: 'Chat',
                                  variant: BorrowlyButtonVariant.secondary,
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                  onPressed: () {
                                    BorrowlyLogger.event('ItemDetails: Chat Button Tapped', parameters: {
                                      'authStatus': authState.status.name,
                                      'isAuthenticated': authState.isAuthenticated,
                                      'userId': authState.user?.id ?? 'null',
                                      'isGuest': authState.isGuest,
                                    });
                                    ref.read(authProvider.notifier).executeProtectedAction(
                                      context,
                                      actionTitle: 'Chat with ${item.ownerName}',
                                      onAuthenticated: () {
                                        BorrowlyLogger.info('✅ Chat: Auth passed, pushing chat screen');
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
                                  label: item.isAvailable ? 'Request to Borrow' : 'Currently Borrowed',
                                  variant: item.isAvailable ? BorrowlyButtonVariant.primary : BorrowlyButtonVariant.outline,
                                  onPressed: item.isAvailable
                                      ? () {
                                          BorrowlyLogger.event('ItemDetails: Borrow Button Tapped', parameters: {
                                            'authStatus': authState.status.name,
                                            'isAuthenticated': authState.isAuthenticated,
                                            'userId': authState.user?.id ?? 'null',
                                          });
                                          ref.read(authProvider.notifier).executeProtectedAction(
                                            context,
                                            actionTitle: 'Borrow "${item.title}"',
                                            onAuthenticated: () {
                                              BorrowlyLogger.info('✅ Borrow: Auth passed, showing request sheet');
                                              RequestBorrowBottomSheet.show(context, item: item);
                                            },
                                          );
                                        }
                                      : () {
                                          BorrowlyToast.show(context, 'This item is currently out on loan with another neighbor');
                                        },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
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
    ),
  );
}

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, ItemEntity item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            const SizedBox(width: 8),
            Text(
              'Delete Listing?',
              style: AppTypography.headingMedium(isDark).copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${item.title}"? This action cannot be undone.',
          style: AppTypography.bodyMedium(isDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              try {
                final repo = ref.read(itemRepositoryProvider);
                await repo.deleteItem(item.id);
                ref.invalidateAllItemProviders();

                if (context.mounted) {
                  BorrowlyToast.show(
                    context,
                    'Listing permanently deleted.',
                    icon: Icons.delete_forever_rounded,
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  BorrowlyToast.show(context, 'Failed to delete listing: $e');
                }
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
}


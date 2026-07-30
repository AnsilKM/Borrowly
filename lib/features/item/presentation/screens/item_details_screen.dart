import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/widgets/borrowly_empty_state.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/borrow/presentation/widgets/request_borrow_bottom_sheet.dart';
import 'package:borrowly/features/item/domain/entities/item_entity.dart';
import 'package:borrowly/features/item/domain/usecases/get_item_details_usecase.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';

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
  bool _isFavorite = false;

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
                    // 1. Large Hero Header Image Carousel
                    Stack(
                      children: [
                        SizedBox(
                          height: 340,
                          child: PageView.builder(
                            itemCount: item.images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: item.images[index],
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
                            },
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

                        // Share & Favorite Buttons
                        Positioned(
                          top: MediaQuery.of(context).padding.top + AppSpacing.xs,
                          right: AppSpacing.md,
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                                  onPressed: () {},
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
                                    _isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                                    color: _isFavorite ? AppColors.danger : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isFavorite = !_isFavorite;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Page Indicator Dots
                        if (item.images.length > 1)
                          Positioned(
                            bottom: AppSpacing.md,
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
                                    color: _currentImageIndex == idx ? AppColors.primary : Colors.white60,
                                    borderRadius: AppRadii.borderFull,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // 2. Main Title, Price & Details Card Header
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTypography.displayLarge(isDark).copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs + 2),

                          Row(
                            children: [
                              Text(
                                item.formattedPrice,
                                style: AppTypography.displayLarge(isDark).copyWith(
                                  fontSize: 22,
                                  color: item.isFree ? AppColors.success : AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.ratingScore.toStringAsFixed(1)} ',
                                    style: AppTypography.headingSmall(isDark).copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    '(${item.reviewCount})',
                                    style: AppTypography.bodySmall(isDark),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              BorrowlyBadge(
                                label: item.formattedDistance,
                                variant: BorrowlyBadgeVariant.distance,
                                icon: const Icon(Icons.near_me_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          const BorrowlyBadge(
                            label: 'Available today',
                            variant: BorrowlyBadgeVariant.success,
                          ),
                        ],
                      ),
                    ),

                    // 3. About This Item Section Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: BorrowlyCard(
                        variant: BorrowlyCardVariant.warm,
                        padding: const EdgeInsets.all(AppSpacing.lg),
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
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              item.description,
                              style: AppTypography.bodyLarge(isDark).copyWith(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Condition',
                                  style: AppTypography.bodyMedium(isDark).copyWith(
                                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  'Excellent',
                                  style: AppTypography.bodyMedium(isDark).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Owner Card Section (Rohit Sharma profile matching design reference)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner',
                            style: AppTypography.headingMedium(isDark).copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs + 2),
                          BorrowlyCard(
                            variant: BorrowlyCardVariant.elevated,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                  backgroundImage: item.ownerAvatar != null ? NetworkImage(item.ownerAvatar!) : null,
                                  child: item.ownerAvatar == null
                                      ? Text(
                                          item.ownerName.isNotEmpty ? item.ownerName[0] : 'O',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.ownerName,
                                        style: AppTypography.headingSmall(isDark).copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                          const SizedBox(width: 3),
                                          Text(
                                            '4.7 (18 reviews)',
                                            style: AppTypography.bodySmall(isDark),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),

              // Sticky Floating Bottom Action Bar matching Master Reference ("Chat" & "Borrow")
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    boxShadow: AppShadows.floatingNav,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: BorrowlyButton(
                            label: 'Chat',
                            variant: BorrowlyButtonVariant.outline,
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
                            label: 'Borrow',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/borrowly_badge.dart';
import '../../../core/widgets/borrowly_button.dart';
import '../../../core/widgets/borrowly_card.dart';
import '../../../core/widgets/borrowly_empty_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../item/presentation/providers/home_items_provider.dart';
import '../../item/presentation/providers/wishlist_provider.dart';
import '../../item/presentation/widgets/category_selection_bottom_sheet.dart';
import '../../item/presentation/widgets/category_selector.dart';
import '../../item/presentation/widgets/home_search_bar.dart';
import '../../item/presentation/widgets/item_card.dart';
import '../../item/presentation/widgets/item_card_skeleton.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final selectedRadius = ref.watch(selectedRadiusProvider);
    final topPadding = MediaQuery.of(context).viewPadding.top;

    final nearbyItemsAsync = ref.watch(nearbyItemsProvider);
    final freeItemsAsync = ref.watch(freeItemsProvider);
    final recentlyAddedAsync = ref.watch(recentlyAddedItemsProvider);

    final userName = (user != null && user.fullName.isNotEmpty && !user.isGuest)
        ? user.fullName.split(' ').first
        : 'Neighbor';

    final distanceOptions = [1, 2, 3, 5];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(nearbyItemsProvider);
            ref.invalidate(freeItemsProvider);
            ref.invalidate(recentlyAddedItemsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Sleek Glass Header Bar (Greeting & Quick Shortcuts)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: topPadding > 0 ? topPadding + AppSpacing.sm : AppSpacing.lg,
                    bottom: AppSpacing.xs,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // User Greeting & Location
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hello, $userName',
                                  style: AppTypography.displayLarge(isDark).copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('👋', style: TextStyle(fontSize: 20)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.near_me_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Oakwood Drive • $selectedRadius km radius',
                                  style: AppTypography.bodySmall(isDark).copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions: Wishlist Heart & User Avatar
                      Row(
                        children: [
                          Consumer(
                            builder: (context, ref, child) {
                              final wishlistedCount = ref.watch(wishlistIdsProvider).length;
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurface : AppColors.surfaceWarm,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: wishlistedCount > 0
                                            ? AppColors.danger.withValues(alpha: 0.4)
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        wishlistedCount > 0 ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: wishlistedCount > 0
                                            ? AppColors.danger
                                            : (isDark ? Colors.white70 : AppColors.textSecondary),
                                        size: 22,
                                      ),
                                      onPressed: () => context.push(AppRoutes.wishlist),
                                    ),
                                  ),
                                  if (wishlistedCount > 0)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.danger,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),
                                        child: Text(
                                          '$wishlistedCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(width: AppSpacing.xs + 2),

                          if (authState.isGuest)
                            BorrowlyButton(
                              label: 'Sign In',
                              size: BorrowlyButtonSize.small,
                              variant: BorrowlyButtonVariant.outline,
                              onPressed: () => context.push(AppRoutes.login),
                            )
                          else
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.profile),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primary, width: 2),
                                      boxShadow: AppShadows.subtle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.surfaceWarm,
                                      backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                                      child: user?.avatarUrl == null
                                          ? Text(
                                              userName[0].toUpperCase(),
                                              style: TextStyle(
                                                color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 11,
                                      height: 11,
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Interactive Radius Distance Filter Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  child: BorrowlyCard(
                    variant: BorrowlyCardVariant.warm,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.radar_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Text(
                          'Distance Radius:',
                          style: AppTypography.labelText(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: distanceOptions.map((km) {
                                final isSelected = selectedRadius == km;
                                return GestureDetector(
                                  onTap: () {
                                    ref.read(selectedRadiusProvider.notifier).state = km;
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                                      borderRadius: AppRadii.borderPill,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : AppColors.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      '${km}km',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Master Design Search Bar
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: HomeSearchBar(),
                ),
              ),

              // 4. Categories Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.md,
                    bottom: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: AppTypography.headingMedium(isDark).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => CategorySelectionBottomSheet.show(context),
                        child: Text(
                          'View all',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Horizontal Category Selector Chips
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: CategorySelector(),
                ),
              ),

              // 6. Section: Free Shares Carousel (Zero-Cost Neighbor Loans)
              freeItemsAsync.when(
                data: (freeItems) {
                  if (freeItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Row(
                            children: [
                              Text(
                                'Free Community Loans',
                                style: AppTypography.headingMedium(isDark).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const BorrowlyBadge(
                                label: 'FREE 🎁',
                                variant: BorrowlyBadgeVariant.success,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        SizedBox(
                          height: 245,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: freeItems.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 175,
                                child: ItemCard(item: freeItems[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // 7. Section: Nearby Available Items Grid Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    bottom: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Nearby Items',
                            style: AppTypography.headingMedium(isDark).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          BorrowlyBadge(
                            label: '$selectedRadius km',
                            variant: BorrowlyBadgeVariant.distance,
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.productList),
                        child: Text(
                          'See All →',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 8. Nearby Items Grid View
              nearbyItemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: BorrowlyCard(
                          variant: BorrowlyCardVariant.warm,
                          child: BorrowlyEmptyState(
                            title: 'No Items Within $selectedRadius km',
                            description: 'Expand your neighborhood search radius to discover tools, outdoor gear, and kitchenware near you.',
                            icon: Icons.near_me_disabled_outlined,
                            actionLabel: 'Expand Radius to 5 km',
                            onActionPressed: () {
                              ref.read(selectedRadiusProvider.notifier).state = 5;
                            },
                          ),
                        ),
                      ),
                    );
                  }

                  final crossAxisCount = context.responsiveValue<int>(
                    mobile: 2,
                    tablet: 3,
                    desktop: 4,
                  );

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ItemCard(item: items[index]);
                        },
                        childCount: items.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ItemCardSkeleton(),
                      childCount: 4,
                    ),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: BorrowlyCard(
                      variant: BorrowlyCardVariant.outlined,
                      child: BorrowlyEmptyState(
                        title: 'Unable to Load Items',
                        description: error.toString(),
                        icon: Icons.error_outline,
                        actionLabel: 'Retry',
                        onActionPressed: () => ref.invalidate(nearbyItemsProvider),
                      ),
                    ),
                  ),
                ),
              ),

              // 9. Section: Recently Added Items Carousel
              recentlyAddedAsync.when(
                data: (recentItems) {
                  if (recentItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recently Added',
                                style: AppTypography.headingMedium(isDark).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.search),
                                child: Text(
                                  'See all',
                                  style: AppTypography.bodySmall(isDark).copyWith(
                                    color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        SizedBox(
                          height: 245,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: recentItems.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 175,
                                child: ItemCard(item: recentItems[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl + 80)),
            ],
          ),
        ),
      ),
    );
  }
}

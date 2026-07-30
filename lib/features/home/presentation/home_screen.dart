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
        : 'Guest';

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
              // Header Section showing User greeting and Location details
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: topPadding > 0 ? topPadding + AppSpacing.md : AppSpacing.xl,
                    bottom: AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Hi, $userName',
                                  style: AppTypography.displayLarge(isDark).copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text('👋', style: TextStyle(fontSize: 22)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Oakwood Drive • Within $selectedRadius km',
                                  style: AppTypography.bodyMedium(isDark).copyWith(
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                          child: Container(
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
                        ),
                    ],
                  ),
                ),
              ),

              // Master Design Search Bar
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: HomeSearchBar(),
                ),
              ),

              // Categories Header Row
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
                        onTap: () => context.push(AppRoutes.search),
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

              // Category Selector Chips
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: CategorySelector(),
                ),
              ),

              // Section: Nearby for you (Asymmetrical Cards with Price & Distance)
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
                      Text(
                        'Nearby for you',
                        style: AppTypography.headingMedium(isDark).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      BorrowlyBadge(
                        label: 'Within $selectedRadius km',
                        variant: BorrowlyBadgeVariant.distance,
                        icon: const Icon(Icons.near_me_rounded),
                      ),
                    ],
                  ),
                ),
              ),

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

              // Section: Free Shares Row (Horizontal Scroll)
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
                                'Free Shares Nearby',
                                style: AppTypography.headingMedium(isDark).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const BorrowlyBadge(
                                label: 'FREE',
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

              // Section: Recently Added
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
                                'Recently added',
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

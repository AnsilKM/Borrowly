import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/responsive_layout.dart';
import '../../../../core/widgets/borrowly_badge.dart';
import '../../../../core/widgets/borrowly_card.dart';
import '../../../../core/widgets/borrowly_empty_state.dart';
import '../../domain/entities/item_entity.dart';
import '../providers/home_items_provider.dart';
import '../widgets/item_card.dart';

/// Versatile Product List Screen for displaying either:
/// 1. "My Listings" (isMyListings == true)
/// 2. "Nearby Items" (isMyListings == false, clicked from Home "See All")
class ProductListScreen extends ConsumerWidget {
  final String title;
  final bool isMyListings;

  const ProductListScreen({
    super.key,
    this.title = 'Nearby Items',
    this.isMyListings = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedRadius = ref.watch(selectedRadiusProvider);

    final AsyncValue<List<ItemEntity>> itemsAsync = isMyListings
        ? ref.watch(userListingsProvider)
        : ref.watch(nearbyItemsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: !isMyListings,
        title: Text(
          title,
          style: AppTypography.headingMedium(isDark),
        ),
        centerTitle: true,
        actions: [
          if (isMyListings)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
              tooltip: 'Add New Listing',
              onPressed: () => context.push(AppRoutes.addItem),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: BorrowlyBadge(
                  label: '$selectedRadius km Radius',
                  variant: BorrowlyBadgeVariant.distance,
                  icon: const Icon(Icons.near_me_rounded),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: isMyListings
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addItem),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'List New Item',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            if (isMyListings) {
              ref.invalidate(userListingsProvider);
            } else {
              ref.invalidate(nearbyItemsProvider);
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            slivers: [
              // Header Summary Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: BorrowlyCard(
                    variant: BorrowlyCardVariant.warm,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isMyListings ? Icons.inventory_2_rounded : Icons.storefront_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMyListings ? 'Your Active Listings' : 'Neighborhood Marketplace',
                                style: AppTypography.headingSmall(isDark).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMyListings
                                    ? 'Items you share with nearby neighbors for cash or free loan.'
                                    : 'All available items shared by neighbors within $selectedRadius km.',
                                style: AppTypography.bodySmall(isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Product List Grid (Same Design as Home Screen)
              itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: BorrowlyCard(
                          variant: BorrowlyCardVariant.flat,
                          child: BorrowlyEmptyState(
                            title: isMyListings ? 'No Active Listings Yet' : 'No Items Found',
                            description: isMyListings
                                ? 'Share tools, outdoor gear, or household items with neighbors to earn or help out.'
                                : 'Try expanding your distance radius or searching for a different category.',
                            icon: isMyListings ? Icons.inventory_2_outlined : Icons.search_off_rounded,
                            actionLabel: isMyListings ? 'Add Your First Item' : 'Reset Filters',
                            onActionPressed: () {
                              if (isMyListings) {
                                context.push(AppRoutes.addItem);
                              } else {
                                ref.read(selectedRadiusProvider.notifier).state = 5;
                              }
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
                          return ItemCard(item: items[index], isMyListing: isMyListings);
                        },
                        childCount: items.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, stack) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: BorrowlyEmptyState(
                      title: 'Unable to Load Items',
                      description: err.toString(),
                      icon: Icons.error_outline_rounded,
                      actionLabel: 'Retry',
                      onActionPressed: () {
                        if (isMyListings) {
                          ref.invalidate(userListingsProvider);
                        } else {
                          ref.invalidate(nearbyItemsProvider);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
        ),
      ),
    );
  }
}

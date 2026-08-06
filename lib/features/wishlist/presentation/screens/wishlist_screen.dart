import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_empty_state.dart';
import 'package:borrowly/features/item/presentation/providers/wishlist_provider.dart';
import 'package:borrowly/features/item/presentation/widgets/item_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wishlistItemsAsync = ref.watch(wishlistItemsProvider);
    final wishlistedIds = ref.watch(wishlistIdsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Saved Wishlist',
          style: AppTypography.headingMedium(isDark).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: BorrowlyBadge(
                label: '${wishlistedIds.length} Saved',
                variant: BorrowlyBadgeVariant.primary,
                icon: const Icon(Icons.favorite_rounded, size: 12),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(wishlistItemsProvider);
          },
          child: wishlistItemsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const BorrowlyEmptyState(
                          title: 'Your Wishlist is Empty',
                          description: 'Tap the heart icon on any item in your neighborhood to save it for later.',
                          icon: Icons.favorite_border_rounded,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppRadii.borderPill,
                            ),
                          ),
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.explore_outlined, size: 18),
                          label: const Text('Explore Neighborhood Items'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ItemCard(item: item);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => Center(
              child: BorrowlyEmptyState(
                title: 'Could Not Load Wishlist',
                description: err.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

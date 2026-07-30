import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/borrowly_badge.dart';
import '../../../core/widgets/borrowly_card.dart';
import '../../../core/widgets/borrowly_empty_state.dart';
import '../../../core/widgets/borrowly_text_field.dart';
import '../../item/presentation/widgets/item_card.dart';
import '../../item/presentation/widgets/item_card_skeleton.dart';
import 'providers/search_provider.dart';
import 'widgets/search_filter_bottom_sheet.dart';
import 'widgets/search_suggestions.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: ref.read(searchStateProvider).query);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(searchStateProvider);
    final searchNotifier = ref.read(searchStateProvider.notifier);
    final searchResultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Header with Back Button
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  Expanded(
                    child: BorrowlyTextField(
                      controller: _textController,
                      hintText: 'Search items, categories...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      onChanged: (val) {
                        searchNotifier.setQuery(val);
                      },
                      suffixIcon: _textController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _textController.clear();
                                searchNotifier.setQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  GestureDetector(
                    onTap: () => SearchFilterBottomSheet.show(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surfaceWarm,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 20,
                            color: isDark ? AppColors.primaryLight : AppColors.olive,
                          ),
                          if (searchState.activeFilterCount > 0)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Filters Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  BorrowlyBadge(
                    label: '${searchState.maxDistanceKm.toInt()} km Radius',
                    variant: BorrowlyBadgeVariant.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (searchState.category.label != 'All Items') ...[
                    BorrowlyBadge(
                      label: searchState.category.label,
                      variant: BorrowlyBadgeVariant.neutral,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  if (searchState.pricingFilter.name != 'all') ...[
                    BorrowlyBadge(
                      label: searchState.pricingFilter.name == 'freeOnly' ? 'FREE Only' : 'Paid Only',
                      variant: BorrowlyBadgeVariant.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Main Results
            Expanded(
              child: searchResultsAsync.when(
                data: (items) {
                  if (_textController.text.isEmpty && items.length == 7) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SearchSuggestions(),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Text(
                            'All Items Nearby (${items.length})',
                            style: AppTypography.headingMedium(isDark).copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return ItemCard(item: items[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: BorrowlyCard(
                        variant: BorrowlyCardVariant.warm,
                        child: BorrowlyEmptyState(
                          title: 'No Matching Items Found',
                          description: 'Try searching for another keyword or expand your neighborhood radius.',
                          icon: Icons.search_off_rounded,
                          actionLabel: 'Reset Filters',
                          onActionPressed: () {
                            _textController.clear();
                            searchNotifier.resetFilters();
                          },
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ItemCard(item: items[index]);
                    },
                  );
                },
                loading: () => GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) => const ItemCardSkeleton(),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: BorrowlyCard(
                    variant: BorrowlyCardVariant.outlined,
                    child: BorrowlyEmptyState(
                      title: 'Search Error',
                      description: error.toString(),
                      icon: Icons.error_outline_rounded,
                      actionLabel: 'Retry',
                      onActionPressed: () => ref.invalidate(searchResultsProvider),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

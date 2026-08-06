import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/features/item/domain/entities/item_category.dart';
import 'package:borrowly/features/item/domain/repositories/item_repository.dart';
import '../providers/search_provider.dart';


class SearchFilterBottomSheet extends ConsumerWidget {
  const SearchFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SearchFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(searchStateProvider);
    final searchNotifier = ref.read(searchStateProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadii.xl),
            topRight: Radius.circular(AppRadii.xl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Search Filters', style: AppTypography.headingMedium(isDark)),
                    TextButton(
                      onPressed: () {
                        searchNotifier.resetFilters();
                      },
                      child: Text(
                        'Reset All',
                        style: AppTypography.bodySmall(isDark).copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                // 1. Distance Radius Filter (Interactive Slider)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Maximum Search Radius', style: AppTypography.labelText(isDark)),
                    Text(
                      '${searchState.maxDistanceKm.toInt()} km',
                      style: AppTypography.bodySmall(isDark).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Slider(
                  value: searchState.maxDistanceKm,
                  min: 1.0,
                  max: 15.0,
                  divisions: 14,
                  activeColor: AppColors.primary,
                  label: '${searchState.maxDistanceKm.toInt()} km',
                  onChanged: (radius) {
                    searchNotifier.setMaxDistance(radius);
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Pricing Filter (All, Free Only, Paid Only)
                Text('Pricing Filter', style: AppTypography.labelText(isDark)),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    _PricingChip(
                      label: 'All Items',
                      isSelected: searchState.pricingFilter == ItemPricingFilter.all,
                      onTap: () => searchNotifier.setPricingFilter(ItemPricingFilter.all),
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _PricingChip(
                      label: 'FREE Only',
                      isSelected: searchState.pricingFilter == ItemPricingFilter.freeOnly,
                      onTap: () => searchNotifier.setPricingFilter(ItemPricingFilter.freeOnly),
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _PricingChip(
                      label: 'Paid Only',
                      isSelected: searchState.pricingFilter == ItemPricingFilter.paidOnly,
                      onTap: () => searchNotifier.setPricingFilter(ItemPricingFilter.paidOnly),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Category Selector
                Text('Category', style: AppTypography.labelText(isDark)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: ItemCategory.values.map((cat) {
                    final isSelected = searchState.category == cat;
                    return ChoiceChip(
                      label: Text(cat.label),
                      avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : null),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (val) {
                        if (val) searchNotifier.setCategory(cat);
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Sort By Selector
                Text('Sort Results By', style: AppTypography.labelText(isDark)),
                const SizedBox(height: AppSpacing.xs),
                Column(
                  children: [
                    _SortTile(
                      label: 'Nearest First (Distance)',
                      isSelected: searchState.sortBy == ItemSortOption.nearest,
                      onTap: () => searchNotifier.setSortBy(ItemSortOption.nearest),
                      isDark: isDark,
                    ),
                    _SortTile(
                      label: 'Price: Low to High',
                      isSelected: searchState.sortBy == ItemSortOption.priceLowToHigh,
                      onTap: () => searchNotifier.setSortBy(ItemSortOption.priceLowToHigh),
                      isDark: isDark,
                    ),
                    _SortTile(
                      label: 'Price: High to Low',
                      isSelected: searchState.sortBy == ItemSortOption.priceHighToLow,
                      onTap: () => searchNotifier.setSortBy(ItemSortOption.priceHighToLow),
                      isDark: isDark,
                    ),
                    _SortTile(
                      label: 'Newest First',
                      isSelected: searchState.sortBy == ItemSortOption.newest,
                      onTap: () => searchNotifier.setSortBy(ItemSortOption.newest),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Apply Button
                BorrowlyButton(
                  label: 'Apply Filters',
                  isFullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PricingChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _PricingChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primary,
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _SortTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.borderMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
              : Colors.transparent,
          borderRadius: AppRadii.borderMd,
          border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodyMedium(isDark).copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

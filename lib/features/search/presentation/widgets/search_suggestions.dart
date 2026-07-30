import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../providers/search_provider.dart';

class SearchSuggestions extends ConsumerWidget {
  const SearchSuggestions({super.key});

  static const List<String> popularSearches = [
    'Cordless Drill',
    'Camping Tent',
    'Lawn Mower',
    'Ladder',
    'Sony Camera',
    'Pressure Washer',
    'Board Games',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Popular Neighborhood Searches',
                style: AppTypography.headingSmall(isDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: popularSearches.map((term) {
              return ActionChip(
                label: Text(term),
                avatar: const Icon(Icons.search, size: 14, color: AppColors.primaryDark),
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                labelStyle: TextStyle(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontSize: 12,
                ),
                shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderFull),
                onPressed: () {
                  ref.read(searchStateProvider.notifier).setQuery(term);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

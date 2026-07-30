import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../providers/home_items_provider.dart';

class RadiusFilterChips extends ConsumerWidget {
  const RadiusFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedRadius = ref.watch(selectedRadiusProvider);

    final radiiOptions = [1, 2, 3, 5];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: radiiOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final radius = radiiOptions[index];
          final isSelected = selectedRadius == radius;

          return ChoiceChip(
            label: Text('$radius km ${radius == 5 ? "(Max)" : ""}'),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref.read(selectedRadiusProvider.notifier).state = radius;
              }
            },
            avatar: Icon(
              Icons.near_me_outlined,
              size: 14,
              color: isSelected ? AppColors.textPrimary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            ),
            selectedColor: AppColors.primary,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
            side: BorderSide(
              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.border),
            ),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.textPrimary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            shape: const RoundedRectangleBorder(borderRadius: AppRadii.borderFull),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

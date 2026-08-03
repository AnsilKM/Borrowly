import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/borrowly_card.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: BorrowlyCard(
        variant: BorrowlyCardVariant.warm,
        borderRadius: AppRadii.borderPill,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        onTap: () => context.push(AppRoutes.search),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 22,
              color: isDark ? AppColors.darkTextSecondary : AppColors.olive,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Search items, categories...',
                style: AppTypography.bodyMedium(isDark).copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

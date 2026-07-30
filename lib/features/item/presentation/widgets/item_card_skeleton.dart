import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/borrowly_card.dart';

class ItemCardSkeleton extends StatelessWidget {
  const ItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BorrowlyCard(
      variant: BorrowlyCardVariant.outlined,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadii.md),
                topRight: Radius.circular(AppRadii.md),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
                    borderRadius: AppRadii.borderSm,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
                    borderRadius: AppRadii.borderSm,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
                        borderRadius: AppRadii.borderSm,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
                        borderRadius: AppRadii.borderSm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

class BorrowlyCategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const BorrowlyCategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm);

    final fgColor = isSelected
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    final borderColor = isSelected
        ? AppColors.primary
        : (isDark ? AppColors.darkBorder : AppColors.borderSubtle);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadii.borderPill,
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkSurface : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : (isDark ? AppColors.primaryLight : AppColors.olive),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodyMedium(isDark).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

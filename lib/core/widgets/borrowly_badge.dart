import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum BorrowlyBadgeVariant { primary, success, warning, danger, neutral, price, distance }

class BorrowlyBadge extends StatelessWidget {
  final String label;
  final Widget? icon;
  final BorrowlyBadgeVariant variant;

  const BorrowlyBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = BorrowlyBadgeVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case BorrowlyBadgeVariant.primary:
        bg = AppColors.primary.withValues(alpha: 0.14);
        fg = isDark ? AppColors.primaryLight : AppColors.primaryDark;
        break;
      case BorrowlyBadgeVariant.success:
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        break;
      case BorrowlyBadgeVariant.warning:
        bg = AppColors.warning.withValues(alpha: 0.14);
        fg = AppColors.warning;
        break;
      case BorrowlyBadgeVariant.danger:
        bg = AppColors.danger.withValues(alpha: 0.12);
        fg = AppColors.danger;
        break;
      case BorrowlyBadgeVariant.neutral:
        bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle;
        fg = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
        break;
      case BorrowlyBadgeVariant.price:
        bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm;
        fg = isDark ? AppColors.primaryLight : AppColors.primaryDark;
        border = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          width: 0.8,
        );
        break;
      case BorrowlyBadgeVariant.distance:
        bg = isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle.withValues(alpha: 0.6);
        fg = isDark ? AppColors.darkTextSecondary : AppColors.olive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.borderPill,
        border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: fg, size: 12),
              child: icon!,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.badgeText(fg).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

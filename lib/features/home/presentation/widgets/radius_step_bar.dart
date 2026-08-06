import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../item/presentation/providers/home_items_provider.dart';

/// Clean, minimal segmented distance radius selector for the Home Screen.
/// Replaces progress bars with a sleek pill selector matching Borrowly aesthetics.
class RadiusStepBar extends ConsumerWidget {
  const RadiusStepBar({super.key});

  static const _steps = [1, 2, 3, 5];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedRadius = ref.watch(selectedRadiusProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWarm,
        borderRadius: AppRadii.borderXl,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon & Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: AppColors.primary,
                  size: 15,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Radius:',
                style: AppTypography.labelText(isDark).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),

          // 4 Segmented Pills
          Expanded(
            child: Row(
              children: _steps.map((km) {
                final isSelected = selectedRadius == km;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        ref.read(selectedRadiusProvider.notifier).state = km;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkSurfaceSubtle : Colors.white),
                          borderRadius: AppRadii.borderPill,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$km km',
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

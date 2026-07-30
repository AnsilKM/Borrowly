import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

class BorrowlyTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const BorrowlyTextField({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xxs + 2),
            child: Text(
              label!,
              style: AppTypography.labelText(isDark).copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTypography.bodyLarge(isDark).copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            hintStyle: AppTypography.bodyMedium(isDark).copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.borderPill,
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.borderPill,
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadii.borderPill,
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
                    child: IconTheme(
                      data: IconThemeData(
                        color: isDark ? AppColors.darkTextMuted : AppColors.olive,
                        size: 20,
                      ),
                      child: prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md, left: AppSpacing.xs),
                    child: IconTheme(
                      data: IconThemeData(
                        color: isDark ? AppColors.darkTextMuted : AppColors.olive,
                        size: 20,
                      ),
                      child: suffixIcon!,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
        ),
      ],
    );
  }
}

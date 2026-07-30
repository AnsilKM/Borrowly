import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum BorrowlyButtonVariant { primary, secondary, outline, text }

enum BorrowlyButtonSize { small, medium, large }

class BorrowlyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final BorrowlyButtonVariant variant;
  final BorrowlyButtonSize size;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;

  const BorrowlyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BorrowlyButtonVariant.primary,
    this.size = BorrowlyButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  State<BorrowlyButton> createState() => _BorrowlyButtonState();
}

class _BorrowlyButtonState extends State<BorrowlyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double height = switch (widget.size) {
      BorrowlyButtonSize.small => 38.0,
      BorrowlyButtonSize.medium => 48.0,
      BorrowlyButtonSize.large => 56.0,
    };

    final EdgeInsets padding = switch (widget.size) {
      BorrowlyButtonSize.small => const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      BorrowlyButtonSize.medium => const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      BorrowlyButtonSize.large => const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
    };

    Color backgroundColor;
    Color textColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case BorrowlyButtonVariant.primary:
        backgroundColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case BorrowlyButtonVariant.secondary:
        backgroundColor = isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        borderSide = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.olive.withValues(alpha: 0.2),
          width: 1,
        );
        break;
      case BorrowlyButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.olive;
        borderSide = BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.olive,
          width: 1.5,
        );
        break;
      case BorrowlyButtonVariant.text:
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
        break;
    }

    if (widget.onPressed == null || widget.isLoading) {
      backgroundColor = (widget.variant == BorrowlyButtonVariant.outline || widget.variant == BorrowlyButtonVariant.text)
          ? Colors.transparent
          : (isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle);
      textColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    }

    final buttonChild = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ] else if (widget.icon != null) ...[
          IconTheme(
            data: IconThemeData(color: textColor, size: 18),
            child: widget.icon!,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          widget.label,
          style: AppTypography.buttonText(textColor),
        ),
      ],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        height: height,
        width: widget.isFullWidth ? double.infinity : null,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Material(
            color: backgroundColor,
            borderRadius: AppRadii.borderPill,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: (widget.isLoading || widget.onPressed == null) ? null : widget.onPressed,
              borderRadius: AppRadii.borderPill,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: AppRadii.borderPill,
                  border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
                ),
                alignment: Alignment.center,
                child: buttonChild,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

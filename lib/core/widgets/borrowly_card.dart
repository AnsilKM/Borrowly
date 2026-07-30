import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum BorrowlyCardVariant { outlined, elevated, flat, warm }

class BorrowlyCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorrowlyCardVariant variant;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const BorrowlyCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.variant = BorrowlyCardVariant.elevated,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<BorrowlyCard> createState() => _BorrowlyCardState();
}

class _BorrowlyCardState extends State<BorrowlyCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.02,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ?? AppRadii.borderXl;

    Color backgroundColor = switch (widget.variant) {
      BorrowlyCardVariant.outlined => isDark ? AppColors.darkSurface : AppColors.surface,
      BorrowlyCardVariant.elevated => isDark ? AppColors.darkSurface : AppColors.surface,
      BorrowlyCardVariant.flat => isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
      BorrowlyCardVariant.warm => isDark ? AppColors.darkSurface : AppColors.surfaceWarm,
    };

    Border? border = switch (widget.variant) {
      BorrowlyCardVariant.outlined => Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 1,
        ),
      BorrowlyCardVariant.warm => Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
          width: 1,
        ),
      BorrowlyCardVariant.elevated => Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSubtle.withValues(alpha: 0.8),
          width: 0.8,
        ),
      BorrowlyCardVariant.flat => null,
    };

    List<BoxShadow>? boxShadow = widget.variant == BorrowlyCardVariant.elevated
        ? (isDark ? AppShadows.subtle : AppShadows.medium)
        : null;

    final cardContent = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: effectiveRadius,
          child: Padding(
            padding: widget.padding,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return cardContent;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: cardContent,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import 'borrowly_button.dart';
import 'borrowly_card.dart';

class BorrowlyErrorBoundary extends StatefulWidget {
  final Widget child;

  const BorrowlyErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  State<BorrowlyErrorBoundary> createState() => _BorrowlyErrorBoundaryState();
}

class _BorrowlyErrorBoundaryState extends State<BorrowlyErrorBoundary> {
  bool _hasError = false;
  String _errorDetails = '';

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetails = details.exceptionAsString();
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: BorrowlyCard(
                variant: BorrowlyCardVariant.outlined,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: AppColors.warning),
                    const SizedBox(height: AppSpacing.md),
                    Text('Something went wrong', style: AppTypography.headingMedium(isDark)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'An unexpected UI rendering issue occurred. Please try reloading.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(isDark),
                    ),
                    if (_errorDetails.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _errorDetails,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall(isDark).copyWith(fontSize: 10, color: AppColors.danger),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    BorrowlyButton(
                      label: 'Reload View',
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorDetails = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

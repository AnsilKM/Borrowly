import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:borrowly/app/router/routes.dart';
import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';
import '../providers/auth_provider.dart';

class LoginPromptBottomSheet extends ConsumerWidget {
  final String actionTitle;

  const LoginPromptBottomSheet({
    super.key,
    required this.actionTitle,
  });

  static Future<void> show(BuildContext context, {required String actionTitle}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoginPromptBottomSheet(actionTitle: actionTitle),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authController = ref.read(authProvider.notifier);
    final authState = ref.watch(authProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadii.xl),
            topRight: Radius.circular(AppRadii.xl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // Sheet grab handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: AppRadii.borderFull,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Icon Badge
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title & Description
              Text(
                'Sign In Required to $actionTitle',
                style: AppTypography.headingMedium(isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Borrowly allows guest browsing within 5 km, but signing in is required for secure physical handovers, borrowing items, listing, and chat.',
                style: AppTypography.bodyMedium(isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Google Sign In
              BorrowlyButton(
                label: 'Continue with Google',
                isFullWidth: true,
                isLoading: authState.status == AuthStatus.loading,
                icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.textPrimary),
                onPressed: () async {
                  try {
                    await authController.signInWithGoogle();
                    final currentUser = ref.read(authProvider).user;
                    if (context.mounted && ref.read(authProvider).isAuthenticated) {
                      Navigator.of(context).pop();
                      if (currentUser?.isNewUser == true) {
                        context.push(AppRoutes.profileSetup);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final msg = e.toString().replaceAll('Exception: ', '');
                      if (!msg.contains('cancelled')) {
                        BorrowlyToast.show(context, msg, isError: true);
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Dismiss Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel & Keep Browsing as Guest',
                  style: AppTypography.bodySmall(isDark).copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

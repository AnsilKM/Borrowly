import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/borrowly_badge.dart';
import '../../../../core/widgets/borrowly_button.dart';
import '../../../../core/widgets/borrowly_card.dart';
import '../../../../core/widgets/borrowly_toast.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authController = ref.read(authProvider.notifier);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              
              // App Brand Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadii.borderMd,
                    ),
                    child: const Icon(
                      Icons.handshake,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Borrowly',
                        style: AppTypography.displayLarge(isDark).copyWith(fontSize: 26),
                      ),
                      const SizedBox(height: 2),
                      const BorrowlyBadge(
                        label: '1–5 km Hyper-local',
                        variant: BorrowlyBadgeVariant.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Value Proposition Banner
              Text(
                'Borrow items from verified neighbors near you.',
                style: AppTypography.headingLarge(isDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Power tools, camping equipment, cameras, and ladder sharing — physical handover only.',
                style: AppTypography.bodyMedium(isDark),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Feature Highlights Cards
              Expanded(
                child: ListView(
                  children: [
                    _FeatureCard(
                      icon: Icons.remove_red_eye_outlined,
                      title: 'Browse Freely as Guest',
                      subtitle: 'Explore nearby items within 1–5 km without an account.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FeatureCard(
                      icon: Icons.handshake_outlined,
                      title: 'Physical Handover Only',
                      subtitle: 'Meet local neighbors directly. No shipping or delivery fees.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _FeatureCard(
                      icon: Icons.security_outlined,
                      title: 'Verified Community',
                      subtitle: 'Sign in with Google or Apple when ready to borrow or list.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              if (authState.status == AuthStatus.loading) ...[
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ] else ...[
                // Primary Option: Guest Mode for friction-free onboarding
                BorrowlyButton(
                  label: 'Browse Nearby as Guest',
                  isFullWidth: true,
                  icon: const Icon(Icons.explore_outlined, size: 20, color: AppColors.textPrimary),
                  onPressed: () async {
                    await authController.continueAsGuest();
                    if (context.mounted) {
                      context.go(AppRoutes.home);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Social Sign In
                BorrowlyButton(
                  label: 'Sign in with Google',
                  variant: BorrowlyButtonVariant.outline,
                  isFullWidth: true,
                  icon: const Icon(Icons.g_mobiledata, size: 26),
                  onPressed: () async {
                    try {
                      await authController.signInWithGoogle();
                      if (context.mounted && ref.read(authProvider).isAuthenticated) {
                        context.go(AppRoutes.profileSetup);
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
              ],
              const SizedBox(height: AppSpacing.sm),

              Text(
                'By continuing, you agree to Borrowly\'s Community Guidelines.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return BorrowlyCard(
      variant: BorrowlyCardVariant.flat,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: AppRadii.borderSm,
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headingSmall(isDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySmall(isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

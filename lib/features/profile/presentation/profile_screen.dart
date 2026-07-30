import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:borrowly/app/router/routes.dart';
import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final userName = (user != null && user.fullName.isNotEmpty) ? user.fullName : 'Guest Neighbor';
    final userEmail = (user != null && user.email.isNotEmpty) ? user.email : 'guest@borrowly.app';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              Text(
                'My Profile',
                style: AppTypography.displayLarge(isDark).copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Warm User Profile Card
              BorrowlyCard(
                variant: BorrowlyCardVariant.warm,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        boxShadow: AppShadows.medium,
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 38,
                        backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                        child: user?.avatarUrl == null
                            ? Text(
                                userName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                    Text(
                      userName,
                      style: AppTypography.headingLarge(isDark).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: AppTypography.bodyMedium(isDark).copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BorrowlyBadge(
                          label: authState.isGuest ? 'Guest Account' : 'Verified Member',
                          variant: authState.isGuest ? BorrowlyBadgeVariant.warning : BorrowlyBadgeVariant.success,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        BorrowlyBadge(
                          label: '${user?.searchRadiusKm ?? 5} km Radius',
                          variant: BorrowlyBadgeVariant.distance,
                          icon: const Icon(Icons.near_me_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Community Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: authState.isGuest ? '0' : '5',
                      label: 'Borrows',
                      icon: Icons.handshake_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: _StatCard(
                      value: authState.isGuest ? '0' : '8',
                      label: 'Shared',
                      icon: Icons.inventory_2_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: _StatCard(
                      value: authState.isGuest ? 'N/A' : '4.9 ⭐',
                      label: 'Rating',
                      icon: Icons.star_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Actions
              if (authState.isGuest) ...[
                BorrowlyButton(
                  label: 'Sign In or Register',
                  isFullWidth: true,
                  icon: const Icon(Icons.login_rounded),
                  onPressed: () => context.push(AppRoutes.login),
                ),
              ] else ...[
                BorrowlyButton(
                  label: 'Edit Neighborhood Profile',
                  variant: BorrowlyButtonVariant.secondary,
                  isFullWidth: true,
                  icon: const Icon(Icons.edit_location_alt_rounded),
                  onPressed: () => context.push(AppRoutes.profileSetup),
                ),
                const SizedBox(height: AppSpacing.sm),
                BorrowlyButton(
                  label: 'Logout Session',
                  variant: BorrowlyButtonVariant.outline,
                  isFullWidth: true,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Row(
                            children: [
                              Icon(Icons.logout_rounded, color: AppColors.danger),
                              SizedBox(width: 8),
                              Text('Logout Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          content: const Text(
                            'Are you sure you want to log out of your Borrowly session?',
                            style: TextStyle(fontSize: 14),
                          ),
                          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                await ref.read(authProvider.notifier).signOut();
                                if (context.mounted) {
                                  BorrowlyToast.show(
                                    context,
                                    'Logged out. Returned to Guest Mode.',
                                    icon: Icons.check_circle_outline_rounded,
                                  );
                                }
                              },
                              child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return BorrowlyCard(
      variant: BorrowlyCardVariant.elevated,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headingSmall(isDark).copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall(isDark).copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

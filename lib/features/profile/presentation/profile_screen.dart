import 'dart:io';
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
import 'package:borrowly/core/widgets/borrowly_image_picker_bottom_sheet.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/borrow/presentation/providers/borrow_provider.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'No Phone Added';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final userName = (user != null && user.fullName.isNotEmpty) ? user.fullName : 'Guest Neighbor';
    final userEmail = (user != null && user.email.isNotEmpty) ? user.email : 'guest@borrowly.app';
    final userPhone = _formatPhoneNumber(user?.phone);

    final borrowerRequestsAsync = authState.isGuest ? null : ref.watch(userBorrowRequestsProvider(false));
    final userListingsAsync = authState.isGuest ? null : ref.watch(userListingsProvider);

    final borrowsCountStr = authState.isGuest
        ? '0'
        : (borrowerRequestsAsync?.when(
              data: (reqs) => '${reqs.length}',
              loading: () => '...',
              error: (_, __) => '0',
            ) ?? '0');

    final userItems = userListingsAsync?.when(
          data: (items) => items,
          loading: () => null,
          error: (_, __) => null,
        );

    final sharedCountStr = authState.isGuest
        ? '0'
        : (userItems != null ? '${userItems.length}' : '0');

    final ratingStr = authState.isGuest
        ? 'N/A'
        : (userItems != null && userItems.isNotEmpty
            ? '${(userItems.fold<double>(0, (sum, i) => sum + i.ratingScore) / userItems.length).toStringAsFixed(1)} ⭐'
            : '5.0 ⭐');

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
                child: Stack(
                  children: [
                    if (!authState.isGuest)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => context.push(AppRoutes.profileSetup),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            BorrowlyImagePickerBottomSheet.show(
                              context,
                              title: 'Update Profile Picture',
                              subtitle: 'Choose a photo for your neighbor profile',
                              initialPreviewPath: user?.avatarUrl,
                              onConfirmSave: (path) async {
                                await ref.read(authProvider.notifier).updateProfilePicture(path);
                                if (context.mounted) {
                                  BorrowlyToast.show(
                                    context,
                                    'Profile picture updated successfully!',
                                    icon: Icons.check_circle_rounded,
                                  );
                                }
                              },
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
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
                                  backgroundImage: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                                      ? (user.avatarUrl!.startsWith('http')
                                          ? NetworkImage(user.avatarUrl!) as ImageProvider
                                          : FileImage(File(user.avatarUrl!)))
                                      : null,
                                  child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
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
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
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
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              userPhone,
                              style: AppTypography.bodyMedium(isDark).copyWith(
                                fontWeight: FontWeight.w600,
                                color: user?.phone != null && user!.phone!.isNotEmpty
                                    ? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
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
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Community Stats (Real Dynamic Data)
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: borrowsCountStr,
                      label: 'Borrows',
                      icon: Icons.handshake_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: _StatCard(
                      value: sharedCountStr,
                      label: 'Shared',
                      icon: Icons.inventory_2_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: _StatCard(
                      value: ratingStr,
                      label: 'Rating',
                      icon: Icons.star_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Account & Legal Options Menu Card
              BorrowlyCard(
                variant: BorrowlyCardVariant.flat,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'My Listings',
                      subtitle: authState.isGuest
                          ? 'Sign in to view your posted items'
                          : '${userItems?.length ?? 0} active listing(s)',
                      isDark: isDark,
                      onTap: () {
                        if (authState.isGuest) {
                          context.push(AppRoutes.login);
                        } else {
                          context.push(AppRoutes.myListings);
                        }
                      },
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _ProfileMenuItem(
                      icon: Icons.description_outlined,
                      title: 'Terms & Conditions',
                      subtitle: 'Usage rules & physical handover policy',
                      isDark: isDark,
                      onTap: () => context.push(AppRoutes.terms),
                    ),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _ProfileMenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'How your neighborhood data is protected',
                      isDark: isDark,
                      onTap: () => context.push(AppRoutes.privacy),
                    ),
                  ],
                ),
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

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.headingSmall(isDark).copyWith(fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall(isDark),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}

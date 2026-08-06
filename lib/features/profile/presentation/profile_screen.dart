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
import 'package:borrowly/core/utils/avatar_provider_util.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';

import 'package:borrowly/core/location/location_provider.dart';
import '../../home/presentation/widgets/location_search_bottom_sheet.dart';

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
    final topPadding = MediaQuery.of(context).viewPadding.top;

    final userName = (user != null && user.fullName.isNotEmpty) ? user.fullName : 'Guest Neighbor';
    final userEmail = (user != null && user.email.isNotEmpty) ? user.email : 'guest@borrowly.app';
    final userPhone = _formatPhoneNumber(user?.phone);

    final userListingsAsync = authState.isGuest ? null : ref.watch(userListingsProvider);
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

    final locationState = ref.watch(activeLocationProvider).valueOrNull;
    final fix = locationState?.fix;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: topPadding > 0 ? topPadding + AppSpacing.sm : AppSpacing.lg,
            bottom: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title Header Row with Top-Right Logout Icon Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Profile',
                    style: AppTypography.displayLarge(isDark).copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!authState.isGuest)
                    IconButton(
                      tooltip: 'Logout',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.danger,
                          size: 20,
                        ),
                      ),
                      onPressed: () => _showLogoutDialog(context, ref),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Warm User Profile Header Card
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
                            if (authState.isGuest) {
                              BorrowlyToast.show(
                                context,
                                'Please sign in to update your profile photo.',
                                icon: Icons.lock_outline_rounded,
                              );
                              return;
                            }
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
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  radius: 38,
                                  backgroundImage: getAvatarImageProvider(user?.displayAvatarUrl),
                                ),
                              ),
                              if (!authState.isGuest)
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
                        GestureDetector(
                          onTap: () {
                            if (authState.isGuest) {
                              BorrowlyToast.show(
                                context,
                                'Please sign in to edit your profile details.',
                                icon: Icons.lock_outline_rounded,
                              );
                              return;
                            }
                            context.push(AppRoutes.profileSetup);
                          },
                          child: Text(
                            userName,
                            style: AppTypography.headingLarge(isDark).copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
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
                              label: fix != null ? '📍 ${fix.localityName}' : '📍 Location Off',
                              variant: BorrowlyBadgeVariant.distance,
                            ),
                          ],
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
                      value: sharedCountStr,
                      label: 'Listings',
                      icon: Icons.inventory_2_rounded,
                      isDark: isDark,
                      onTap: authState.isGuest
                          ? () => BorrowlyToast.show(context, 'Sign in to view active listings', icon: Icons.lock_outline_rounded)
                          : () => context.push(AppRoutes.myListings),
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

              // Account & Settings Menu Card
              BorrowlyCard(
                variant: BorrowlyCardVariant.flat,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.map_outlined,
                      title: 'Search Location',
                      subtitle: fix != null
                          ? 'Active: ${fix.localityName} (${fix.source.toUpperCase()})'
                          : 'Set your neighborhood location',
                      isDark: isDark,
                      onTap: () => LocationSearchBottomSheet.show(context),
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

              // Actions: Sign In (Guest) vs Log Out (Logged In)
              if (authState.isGuest)
                BorrowlyButton(
                  label: 'Sign In or Register',
                  isFullWidth: true,
                  variant: BorrowlyButtonVariant.primary,
                  icon: const Icon(Icons.login_rounded, size: 20),
                  onPressed: () => context.push(AppRoutes.login),
                )
              else
                BorrowlyButton(
                  label: 'Log Out Session',
                  isFullWidth: true,
                  variant: BorrowlyButtonVariant.outline,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                  onPressed: () => _showLogoutDialog(context, ref),
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BorrowlyCard(
      variant: BorrowlyCardVariant.elevated,
      onTap: onTap,
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

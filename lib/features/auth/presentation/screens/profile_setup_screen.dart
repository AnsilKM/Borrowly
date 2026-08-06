import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/borrowly_button.dart';
import '../../../../core/widgets/borrowly_text_field.dart';
import '../../../../core/widgets/borrowly_toast.dart';
import '../providers/auth_provider.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedRadiusKm = 5;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final activeRadius = ref.read(selectedRadiusProvider);
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _selectedRadiusKm = activeRadius > 0 ? activeRadius : user.searchRadiusKm;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final isEditing = user != null && !user.isNewUser && user.fullName.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Profile' : 'Complete Your Profile',
          style: AppTypography.headingMedium(isDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Edit Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : AppColors.surfaceWarm).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        user?.displayAvatarUrl ??
                            'https://ui-avatars.com/api/?name=Neighbor&background=0D9488&color=ffffff&bold=true',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName : 'Borrowly Neighbor',
                            style: AppTypography.headingSmall(isDark).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'Tap text fields below to edit',
                            style: AppTypography.bodySmall(isDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            isEditing ? 'Editing' : 'Setup',
                            style: TextStyle(
                              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 1: Personal Information
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Personal Information',
                    style: AppTypography.headingMedium(isDark).copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tap below to update your name and mobile number across Borrowly.',
                style: AppTypography.bodyMedium(isDark),
              ),
              const SizedBox(height: AppSpacing.md),

              // Full Name Field (With Suffix Edit Indicator)
              BorrowlyTextField(
                label: 'Full Name (Editable)',
                hintText: 'e.g. Alex Morgan',
                controller: _fullNameController,
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                suffixIcon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.md),

              // Phone Number Field (With Suffix Edit Indicator)
              BorrowlyTextField(
                label: 'Mobile Phone Number (10 Digits Required)',
                hintText: 'e.g. 9876543210',
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                suffixIcon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section 2: Neighborhood Radius
              Row(
                children: [
                  const Icon(Icons.near_me_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Default Search Radius',
                    style: AppTypography.headingMedium(isDark).copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [1, 2, 3, 5].map((radius) {
                  final isSelected = _selectedRadiusKm == radius;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRadiusKm = radius;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkSurface : AppColors.surfaceWarm),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.border),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.32),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$radius km',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                ),
                              ),
                              if (radius == 5) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '(Max)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.90)
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Submit Button
              BorrowlyButton(
                label: isEditing ? 'Save Profile Changes' : 'Save & Start Exploring',
                isFullWidth: true,
                isLoading: authState.status == AuthStatus.loading,
                onPressed: () async {
                  final phoneInput = _phoneController.text.trim();
                  final digitsOnly = phoneInput.replaceAll(RegExp(r'\D'), '');

                  if (phoneInput.isNotEmpty && digitsOnly.length != 10) {
                    BorrowlyToast.show(
                      context,
                      'Phone number must be exactly 10 digits',
                      icon: Icons.phone_android_rounded,
                    );
                    return;
                  }

                  await ref.read(authProvider.notifier).updateProfile(
                        fullName: _fullNameController.text.isEmpty ? 'Borrowly Neighbor' : _fullNameController.text,
                        phone: digitsOnly,
                        searchRadiusKm: _selectedRadiusKm,
                      );
                  ref.read(selectedRadiusProvider.notifier).state = _selectedRadiusKm;
                  ref.invalidate(nearbyItemsProvider);
                  if (context.mounted) {
                    BorrowlyToast.show(
                      context,
                      'Profile updated successfully!',
                      icon: Icons.check_circle_rounded,
                    );
                    context.go(AppRoutes.home);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

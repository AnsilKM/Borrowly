import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/borrowly_button.dart';
import '../../../../core/widgets/borrowly_card.dart';
import '../../../../core/widgets/borrowly_text_field.dart';
import '../../../../core/widgets/borrowly_toast.dart';
import '../providers/auth_provider.dart';

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
    if (user != null) {
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _selectedRadiusKm = user.searchRadiusKm;
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile', style: AppTypography.headingMedium(isDark)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Neighborhood Settings',
                style: AppTypography.headingLarge(isDark),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Set your contact info and neighborhood search radius for physical handovers.',
                style: AppTypography.bodyMedium(isDark),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Full Name Field
              BorrowlyTextField(
                label: 'Full Name',
                hintText: 'e.g. Alex Morgan',
                controller: _fullNameController,
                prefixIcon: const Icon(Icons.person_outline, size: 20),
              ),
              const SizedBox(height: AppSpacing.md),

              // Phone Number Field (With 10-Digit Validation)
              BorrowlyTextField(
                label: 'Phone Number (10 Digits Required)',
                hintText: 'e.g. 9876543210',
                keyboardType: TextInputType.phone,
                controller: _phoneController,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Search Radius Selector (1 km, 2 km, 3 km, 5 km)
              Text('Default Search Radius', style: AppTypography.labelText(isDark)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [1, 2, 3, 5].map((radius) {
                  final isSelected = _selectedRadiusKm == radius;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: BorrowlyCard(
                        variant: isSelected ? BorrowlyCardVariant.elevated : BorrowlyCardVariant.outlined,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        onTap: () {
                          setState(() {
                            _selectedRadiusKm = radius;
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              '$radius km',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              ),
                            ),
                            if (radius == 5)
                              Text(
                                '(Max)',
                                style: AppTypography.bodySmall(isDark).copyWith(fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Submit Button
              BorrowlyButton(
                label: 'Save & Start Exploring',
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
                  if (context.mounted) {
                    BorrowlyToast.show(
                      context,
                      'Profile & 10-digit phone number updated!',
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

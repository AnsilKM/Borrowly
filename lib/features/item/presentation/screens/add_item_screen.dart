import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:borrowly/app/router/routes.dart';
import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/widgets/borrowly_text_field.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/item/domain/entities/item_category.dart';
import 'package:borrowly/features/item/presentation/providers/add_item_provider.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '5');
  final _depositController = TextEditingController(text: '20');

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        ref.read(addItemProvider.notifier).addImagePath(image.path);
      }
    } catch (e) {
      ref.read(addItemProvider.notifier).addImagePath(
        'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formState = ref.watch(addItemProvider);
    final formNotifier = ref.read(addItemProvider.notifier);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('List Item for Neighborhood', style: AppTypography.headingMedium(isDark)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable Form Body
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handover Banner
                  BorrowlyCard(
                    variant: BorrowlyCardVariant.warm,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs + 2),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Physical Handover Only',
                                style: AppTypography.headingSmall(isDark).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Listings are shared locally with verified neighbors within 5 km.',
                                style: AppTypography.bodySmall(isDark),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Image Picker Section
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
                    child: Text(
                      'Item Photos',
                      style: AppTypography.labelText(isDark).copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add Photo Trigger Card
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: AppRadii.borderXl,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                              borderRadius: AppRadii.borderXl,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_rounded,
                                  color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: AppTypography.bodySmall(isDark).copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),

                        // Photo Thumbnails
                        ...formState.imagePaths.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final path = entry.value;

                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: AppRadii.borderXl,
                                  child: Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: path.startsWith('http')
                                            ? NetworkImage(path) as ImageProvider
                                            : const NetworkImage('https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => formNotifier.removeImagePath(idx),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Title Field
                  BorrowlyTextField(
                    label: 'Item Title',
                    hintText: 'e.g. Bosch Drill Machine 18V',
                    controller: _titleController,
                    onChanged: formNotifier.setTitle,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Category Picker
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
                    child: Text(
                      'Category',
                      style: AppTypography.labelText(isDark).copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: AppSpacing.xs + 2,
                    runSpacing: AppSpacing.xs + 2,
                    children: ItemCategory.values.where((c) => c != ItemCategory.all).map((cat) {
                      final isSelected = formState.category == cat;
                      return ChoiceChip(
                        label: Text(cat.label),
                        avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : (isDark ? AppColors.primaryLight : AppColors.olive)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) formNotifier.setCategory(cat);
                        },
                        selectedColor: AppColors.primary,
                        backgroundColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description Field
                  BorrowlyTextField(
                    label: 'Description',
                    hintText: 'Condition, accessories included, usage instructions...',
                    maxLines: 3,
                    controller: _descriptionController,
                    onChanged: formNotifier.setDescription,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // FREE Share vs Paid Switcher
                  BorrowlyCard(
                    variant: BorrowlyCardVariant.elevated,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Share for FREE',
                                    style: AppTypography.headingSmall(isDark).copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const BorrowlyBadge(label: 'FREE', variant: BorrowlyBadgeVariant.success),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Offer item to local neighbors at zero rental cost.',
                                style: AppTypography.bodySmall(isDark),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: formState.isFree,
                          activeThumbColor: AppColors.success,
                          onChanged: (val) {
                            formNotifier.setIsFree(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Daily Rent Rate (if not free)
                  if (!formState.isFree) ...[
                    BorrowlyTextField(
                      label: 'Daily Rate (₹/day)',
                      hintText: '120',
                      keyboardType: TextInputType.number,
                      controller: _priceController,
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                      onChanged: (val) {
                        final price = double.tryParse(val) ?? 0.0;
                        formNotifier.setDailyPrice(price);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Refundable Deposit Field
                  BorrowlyTextField(
                    label: 'Refundable Security Deposit (₹) (Optional)',
                    hintText: '500',
                    keyboardType: TextInputType.number,
                    controller: _depositController,
                    prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                    onChanged: (val) {
                      final deposit = double.tryParse(val) ?? 0.0;
                      formNotifier.setDepositAmount(deposit);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Error Banner
                  if (formState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: AppRadii.borderLg,
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                          const SizedBox(width: AppSpacing.xs + 2),
                          Expanded(
                            child: Text(
                              formState.errorMessage!,
                              style: AppTypography.bodySmall(isDark).copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Bottom Spacing for Sticky Bar
                  const SizedBox(height: 110),
                ],
              ),
            ),

            // Fixed Floating Sticky Bottom Publish Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  boxShadow: AppShadows.floatingNav,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: BorrowlyButton(
                    label: 'Publish Listing to Neighborhood',
                    isFullWidth: true,
                    isLoading: formState.isLoading,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    onPressed: () async {
                      final success = await formNotifier.submitListing(
                        ownerId: user?.id ?? 'user_1',
                        ownerName: user?.fullName ?? 'Local Neighbor',
                        ownerAvatar: user?.avatarUrl,
                        searchRadiusKm: (user?.searchRadiusKm ?? 5).toDouble(),
                      );

                      if (success && context.mounted) {
                        ref.invalidate(nearbyItemsProvider);
                        ref.invalidate(freeItemsProvider);
                        ref.invalidate(recentlyAddedItemsProvider);

                        BorrowlyToast.show(
                          context,
                          'Item successfully listed in your neighborhood!',
                          icon: Icons.check_circle_rounded,
                        );

                        context.go(AppRoutes.home);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

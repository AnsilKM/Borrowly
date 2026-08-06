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
import 'package:borrowly/core/widgets/borrowly_image_picker_bottom_sheet.dart';
import 'package:borrowly/core/widgets/borrowly_text_field.dart';
import 'package:borrowly/core/location/location_provider.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/home/presentation/widgets/location_search_bottom_sheet.dart';
import 'package:borrowly/features/item/domain/entities/item_category.dart';
import 'package:borrowly/features/item/domain/entities/item_entity.dart';
import 'package:borrowly/features/item/presentation/providers/add_item_provider.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';
import 'item_details_screen.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  final ItemEntity? editItem;

  const AddItemScreen({super.key, this.editItem});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _priceController = TextEditingController(text: '5');
  final _depositController = TextEditingController(text: '20');

  @override
  void initState() {
    super.initState();
    if (widget.editItem != null) {
      final item = widget.editItem!;
      _titleController.text = item.title;
      _descriptionController.text = item.description;
      _priceController.text = item.dailyPrice > 0 ? item.dailyPrice.toInt().toString() : '0';
      _depositController.text = item.depositAmount > 0 ? item.depositAmount.toInt().toString() : '0';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final notifier = ref.read(addItemProvider.notifier);
        notifier.setTitle(item.title);
        notifier.setDescription(item.description);
        notifier.setCategory(item.category);
        notifier.setIsFree(item.isFree);
        notifier.setDailyPrice(item.dailyPrice);
        notifier.setDepositAmount(item.depositAmount);
        for (final img in item.images) {
          notifier.addImagePath(img);
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  void _showImageSourceModal(BuildContext context) {
    BorrowlyImagePickerBottomSheet.show(
      context,
      title: 'Select Item Photo Source',
      subtitle: 'Add single or multiple high-quality photos of your item.',
      allowMultipleGallery: true,
      onSingleImagePicked: (path) {
        ref.read(addItemProvider.notifier).addImagePath(path);
      },
      onMultipleImagesPicked: (paths) {
        for (final p in paths) {
          ref.read(addItemProvider.notifier).addImagePath(p);
        }
      },
    );
  }

  void _showImagePreviewModal(BuildContext context, String imagePath, int index) {
    final isUrl = imagePath.startsWith('http');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Photo ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Image Container
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Image(
                      image: isUrl ? NetworkImage(imagePath) as ImageProvider : FileImage(File(imagePath)),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete Photo'),
                    onPressed: () {
                      ref.read(addItemProvider.notifier).removeImagePath(index);
                      Navigator.pop(dialogContext);
                      BorrowlyToast.show(context, 'Photo removed from listing');
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
        title: Text(
          widget.editItem != null ? 'Edit Listing' : 'Post an Item',
          style: AppTypography.headingMedium(isDark),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable Form Body
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
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
                  const SizedBox(height: AppSpacing.md),

                  // Item Handover Location Card
                  Consumer(
                    builder: (context, ref, _) {
                      final locationState = ref.watch(activeLocationProvider).valueOrNull;
                      final fix = locationState?.fix;
                      final activeLocalityName = fix?.localityName ?? 'Nearby Neighborhood';

                      return BorrowlyCard(
                        variant: BorrowlyCardVariant.flat,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Handover Location',
                                    style: AppTypography.bodySmall(isDark).copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    activeLocalityName,
                                    style: AppTypography.headingSmall(isDark).copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => LocationSearchBottomSheet.show(context),
                              child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Top Prominent Error Banner
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
                  const SizedBox(height: AppSpacing.sm),

                  // 1. FIRST: Item Photos Section
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
                    child: Text(
                      'Item Photos (${formState.imagePaths.length} added)',
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
                          onTap: () => _showImageSourceModal(context),
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
                                  'Add Photos',
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

                        // Photo Thumbnails with Full-Screen Preview on Tap
                        ...formState.imagePaths.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final path = entry.value;
                          final isUrl = path.startsWith('http');

                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: GestureDetector(
                              onTap: () => _showImagePreviewModal(context, path, idx),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: AppRadii.borderXl,
                                    child: Container(
                                      width: 110,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                        image: DecorationImage(
                                          image: isUrl
                                              ? NetworkImage(path) as ImageProvider
                                              : FileImage(File(path)),
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
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. SECOND: Title Field
                  BorrowlyTextField(
                    label: 'Item Title',
                    hintText: 'e.g. Bosch Drill Machine 18V',
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    onChanged: formNotifier.setTitle,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. THIRD: Description Field
                  BorrowlyTextField(
                    label: 'Description',
                    hintText: 'Condition, accessories included, usage instructions...',
                    maxLines: 3,
                    controller: _descriptionController,
                    textInputAction: TextInputAction.next,
                    onChanged: formNotifier.setDescription,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4. FOURTH: Category Picker (With 'Other' Option & Checkmark Removed)
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
                        showCheckmark: false,
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
                  
                  // Custom Category Input Box when 'Other' is selected
                  if (formState.category == ItemCategory.other) ...[
                    const SizedBox(height: AppSpacing.md),
                    BorrowlyTextField(
                      label: 'Specify Custom Category Name',
                      hintText: 'e.g. Musical Instruments, Party Games, Tech',
                      controller: _customCategoryController,
                    ),
                  ],
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
                      textInputAction: TextInputAction.next,
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
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                    onChanged: (val) {
                      final deposit = double.tryParse(val) ?? 0.0;
                      formNotifier.setDepositAmount(deposit);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Clean Publish / Save Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: Builder(
                      builder: (context) {
                        final isEditing = widget.editItem != null;
                        return BorrowlyButton(
                          label: isEditing ? 'Save Listing Changes' : 'Publish Listing to Neighborhood',
                          isFullWidth: true,
                          isLoading: formState.isLoading,
                          icon: Icon(isEditing ? Icons.save_rounded : Icons.check_circle_outline_rounded, size: 20),
                          onPressed: () async {
                            if (isEditing) {
                              final success = await formNotifier.updateExistingListing(widget.editItem!);
                              if (success && context.mounted) {
                                ref.invalidate(itemDetailsProvider(widget.editItem!.id));
                                ref.invalidateAllItemProviders();

                                BorrowlyToast.show(
                                  context,
                                  'Listing updated successfully!',
                                  icon: Icons.check_circle_rounded,
                                );

                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.go(AppRoutes.home);
                                }
                              }
                            } else {
                              final locationState = ref.read(activeLocationProvider).valueOrNull;
                              final fix = locationState?.fix;

                              final success = await formNotifier.submitListing(
                                ownerId: user?.id ?? '00000000-0000-0000-0000-000000000001',
                                ownerName: user?.fullName ?? 'Local Neighbor',
                                ownerAvatar: user?.avatarUrl,
                                searchRadiusKm: (user?.searchRadiusKm ?? 5).toDouble(),
                                locationName: fix?.localityName ?? 'Nearby Neighborhood',
                                lat: fix?.lat,
                                lng: fix?.lng,
                              );

                              if (success && context.mounted) {
                                ref.invalidateAllItemProviders();

                                BorrowlyToast.show(
                                  context,
                                  'Item successfully listed in your neighborhood!',
                                  icon: Icons.check_circle_rounded,
                                );

                                context.go(AppRoutes.home);
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

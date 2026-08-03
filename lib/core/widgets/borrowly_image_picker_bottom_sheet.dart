import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/utils/borrowly_logger.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';

class BorrowlyImagePickerBottomSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final bool allowMultipleGallery;
  final String? initialPreviewPath;
  final ValueChanged<String>? onSingleImagePicked;
  final ValueChanged<List<String>>? onMultipleImagesPicked;
  final Future<void> Function(String pickedPath)? onConfirmSave;

  const BorrowlyImagePickerBottomSheet({
    super.key,
    this.title = 'Select Photo Source',
    this.subtitle,
    this.allowMultipleGallery = false,
    this.initialPreviewPath,
    this.onSingleImagePicked,
    this.onMultipleImagesPicked,
    this.onConfirmSave,
  });

  static Future<void> show(
    BuildContext context, {
    String title = 'Select Photo Source',
    String? subtitle,
    bool allowMultipleGallery = false,
    String? initialPreviewPath,
    ValueChanged<String>? onSingleImagePicked,
    ValueChanged<List<String>>? onMultipleImagesPicked,
    Future<void> Function(String pickedPath)? onConfirmSave,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BorrowlyImagePickerBottomSheet(
        title: title,
        subtitle: subtitle,
        allowMultipleGallery: allowMultipleGallery,
        initialPreviewPath: initialPreviewPath,
        onSingleImagePicked: onSingleImagePicked,
        onMultipleImagesPicked: onMultipleImagesPicked,
        onConfirmSave: onConfirmSave,
      ),
    );
  }

  @override
  State<BorrowlyImagePickerBottomSheet> createState() => _BorrowlyImagePickerBottomSheetState();
}

class _BorrowlyImagePickerBottomSheetState extends State<BorrowlyImagePickerBottomSheet> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.initialPreviewPath;
  }

  Future<String?> _cropImage(String path) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );
      return cropped?.path;
    } catch (e) {
      return path;
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image != null) {
        final croppedPath = await _cropImage(image.path) ?? image.path;
        setState(() {
          _selectedImagePath = croppedPath;
        });
        widget.onSingleImagePicked?.call(croppedPath);
        BorrowlyLogger.info('Captured camera image: $croppedPath');
        if (widget.onConfirmSave == null) {
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (e, stack) {
      BorrowlyLogger.error('Camera image pick error', e, stack);
      if (mounted) {
        BorrowlyToast.show(context, 'Could not access camera', icon: Icons.error_outline);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      if (widget.allowMultipleGallery) {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1200,
        );
        if (images.isNotEmpty) {
          final paths = <String>[];
          for (final img in images) {
            final cropped = await _cropImage(img.path);
            paths.add(cropped ?? img.path);
          }
          setState(() {
            _selectedImagePath = paths.first;
          });
          if (widget.onMultipleImagesPicked != null) {
            widget.onMultipleImagesPicked!.call(paths);
          } else {
            widget.onSingleImagePicked?.call(paths.first);
          }
          BorrowlyLogger.info('Selected ${images.length} images from gallery.');
          if (widget.onConfirmSave == null) {
            if (mounted) Navigator.of(context).pop();
          }
        }
      } else {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200,
        );
        if (image != null) {
          final croppedPath = await _cropImage(image.path) ?? image.path;
          setState(() {
            _selectedImagePath = croppedPath;
          });
          widget.onSingleImagePicked?.call(croppedPath);
          BorrowlyLogger.info('Selected gallery image: $croppedPath');
          if (widget.onConfirmSave == null) {
            if (mounted) Navigator.of(context).pop();
          }
        }
      }
    } catch (e, stack) {
      BorrowlyLogger.error('Gallery image pick error', e, stack);
      if (mounted) {
        BorrowlyToast.show(context, 'Could not access gallery', icon: Icons.error_outline);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top handle pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.headingMedium(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: AppTypography.bodySmall(isDark),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // Optional Live Avatar/Image Preview
              if (_selectedImagePath != null && _selectedImagePath!.isNotEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 3),
                          boxShadow: AppShadows.medium,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.surfaceWarm,
                          backgroundImage: _selectedImagePath!.startsWith('http')
                              ? NetworkImage(_selectedImagePath!) as ImageProvider
                              : FileImage(File(_selectedImagePath!)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Live Photo Preview',
                        style: AppTypography.bodySmall(isDark).copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Camera Option
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: Text('Take Photo with Camera', style: AppTypography.headingSmall(isDark)),
                  subtitle: Text('Capture a new photo right now', style: AppTypography.bodySmall(isDark)),
                  onTap: _pickFromCamera,
                ),
              ),
              const Divider(height: 1),

              // Gallery Option
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                  ),
                  title: Text(
                    widget.allowMultipleGallery ? 'Choose Multiple from Gallery' : 'Choose from Gallery',
                    style: AppTypography.headingSmall(isDark),
                  ),
                  subtitle: Text(
                    widget.allowMultipleGallery
                        ? 'Select one or more photos from your device'
                        : 'Select a photo from your gallery',
                    style: AppTypography.bodySmall(isDark),
                  ),
                  onTap: _pickFromGallery,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Optional Save Confirmation Button
              if (widget.onConfirmSave != null) ...[
                BorrowlyButton(
                  label: 'Save Profile Picture',
                  isFullWidth: true,
                  isLoading: _isSaving,
                  onPressed: _selectedImagePath != null && _selectedImagePath != widget.initialPreviewPath
                      ? () async {
                          final nav = Navigator.of(context);
                          setState(() {
                            _isSaving = true;
                          });
                          await widget.onConfirmSave!(_selectedImagePath!);
                          if (mounted) {
                            nav.pop();
                          }
                        }
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

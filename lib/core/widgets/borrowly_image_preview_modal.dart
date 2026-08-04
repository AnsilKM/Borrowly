import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Reusable full-screen image preview modal for Borrowly.
/// Provides interactive zoom/pan (InteractiveViewer), dark glass card styling,
/// top navigation bar, and dot page indicators for single or multi-image previews.
class BorrowlyImagePreviewModal extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String? title;

  const BorrowlyImagePreviewModal({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.title,
  });

  /// Opens the full-screen image preview modal dialog.
  static void show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
    String? title,
  }) {
    if (images.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => BorrowlyImagePreviewModal(
        images: images,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }

  @override
  State<BorrowlyImagePreviewModal> createState() => _BorrowlyImagePreviewModalState();
}

class _BorrowlyImagePreviewModalState extends State<BorrowlyImagePreviewModal> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.darkBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title ?? 'Image Preview',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.images.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Main Framed Card Preview (Matching Borrowly Card Style)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.images.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentIndex = idx;
                        });
                      },
                      itemBuilder: (context, idx) {
                        final imgStr = widget.images[idx];
                        final isNetworkUrl = imgStr.startsWith('http://') || imgStr.startsWith('https://');

                        return InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Center(
                            child: isNetworkUrl
                                ? CachedNetworkImage(
                                    imageUrl: imgStr,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 60,
                                      color: Colors.white54,
                                    ),
                                  )
                                : Image.file(
                                    File(imgStr),
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 60,
                                      color: Colors.white54,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Dots Indicator
            if (widget.images.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.images.length,
                    (idx) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentIndex == idx ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _currentIndex == idx ? AppColors.primary : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
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

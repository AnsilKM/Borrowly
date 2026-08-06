import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../domain/entities/item_entity.dart';
import '../providers/wishlist_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ItemCard extends ConsumerWidget {
  final ItemEntity item;
  final VoidCallback? onTap;
  final bool isMyListing;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.isMyListing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authUser = ref.watch(authProvider).user;
    final isOwner = isMyListing ||
        (authUser != null &&
            !authUser.isGuest &&
            (item.ownerId == authUser.id ||
                item.ownerId == '00000000-0000-0000-0000-000000000001'));

    final imgStr = item.images.isNotEmpty
        ? item.images.first
        : 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600';
    final isNetworkUrl = imgStr.startsWith('http://') || imgStr.startsWith('https://');

    return Semantics(
      label: 'Item listing: ${item.title}, ${item.formattedPrice}, ${item.formattedDistance}',
      button: true,
      child: GestureDetector(
        onTap: onTap ??
            () {
              context.push('/item/${item.id}');
            },
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header Stack
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                        child: isNetworkUrl
                            ? CachedNetworkImage(
                                imageUrl: imgStr,
                                memCacheWidth: 400,
                                memCacheHeight: 300,
                                fit: BoxFit.cover,
                                fadeInDuration: const Duration(milliseconds: 200),
                                placeholder: (context, url) => Container(
                                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                  child: const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textMuted),
                                ),
                              )
                            : (File(imgStr).existsSync()
                                ? Image.file(
                                    File(imgStr),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                      child: const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textMuted),
                                    ),
                                  )
                                : Container(
                                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                                    child: const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textMuted),
                                  )),
                      ),
                    ),

                    // Hold / Paused Status Visual Identifier Overlay
                    if (!item.isAvailable) ...[
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.38),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(9999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pause_circle_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'ON HOLD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Distance Badge (Bottom Left - Translucent Dark Pill with Walking/Driving Estimate)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          DistanceFormatter.formatProximity(item.distanceKm),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Price Tag (Top Right - Warm Primary Camel Pill Tag)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: item.isFree ? AppColors.primaryLight : AppColors.primary,
                          borderRadius: BorderRadius.circular(9999),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          item.formattedPrice,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    // Favorite Love Icon Overlay (Bottom Right of Image)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final isWishlisted = ref.watch(isItemWishlistedProvider(item.id));
                          return GestureDetector(
                            onTap: () {
                              ref.read(wishlistIdsProvider.notifier).toggleWishlist(item.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: isWishlisted ? AppColors.danger : Colors.white,
                                size: 15,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Card Content Body
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.headingSmall(isDark).copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (!isOwner) ...[
                          CircleAvatar(
                            radius: 9,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                            backgroundImage: CachedNetworkImageProvider(
                              (item.ownerAvatar != null && item.ownerAvatar!.isNotEmpty)
                                  ? item.ownerAvatar!
                                  : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(item.ownerName.isNotEmpty ? item.ownerName : "Neighbor")}&background=0D9488&color=ffffff&bold=true&size=200',
                              maxHeight: 36,
                              maxWidth: 36,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.ownerName,
                              style: AppTypography.bodySmall(isDark).copyWith(
                                color: isDark ? AppColors.darkTextSecondary : AppColors.olive,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else
                          const Spacer(),
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(
                          '4.9',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

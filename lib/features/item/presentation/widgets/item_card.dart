import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/borrowly_badge.dart';
import '../../../../core/widgets/borrowly_card.dart';
import '../../domain/entities/item_entity.dart';

class ItemCard extends ConsumerWidget {
  final ItemEntity item;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Item listing: ${item.title}, ${item.formattedPrice}, ${item.formattedDistance}',
      button: true,
      child: BorrowlyCard(
        variant: BorrowlyCardVariant.elevated,
        padding: EdgeInsets.zero,
        borderRadius: AppRadii.borderXl,
        onTap: onTap ??
            () {
              context.push('/item/${item.id}');
            },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
                      child: CachedNetworkImage(
                        imageUrl: item.images.first,
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
                      ),
                    ),
                  ),

                  // Distance Badge (Top Left)
                  Positioned(
                    top: AppSpacing.xs + 2,
                    left: AppSpacing.xs + 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: AppRadii.borderPill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 10, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            item.formattedDistance,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Price Tag (Top Right)
                  Positioned(
                    top: AppSpacing.xs + 2,
                    right: AppSpacing.xs + 2,
                    child: BorrowlyBadge(
                      label: item.formattedPrice,
                      variant: item.isFree ? BorrowlyBadgeVariant.success : BorrowlyBadgeVariant.price,
                    ),
                  ),
                ],
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.headingSmall(isDark).copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: item.ownerAvatar != null
                            ? CachedNetworkImageProvider(
                                item.ownerAvatar!,
                                maxHeight: 36,
                                maxWidth: 36,
                              )
                            : null,
                        child: item.ownerAvatar == null
                            ? Text(
                                item.ownerName.isNotEmpty ? item.ownerName[0] : 'U',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.ownerName,
                          style: AppTypography.bodySmall(isDark).copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.olive,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
    );
  }
}

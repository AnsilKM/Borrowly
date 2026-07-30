import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_badge.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/widgets/borrowly_empty_state.dart';
import 'package:borrowly/features/borrow/domain/entities/borrow_request_entity.dart';
import 'package:borrowly/features/borrow/presentation/providers/borrow_provider.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  String _selectedFilter = 'Accepted'; // Filter pills: Pending, Accepted, Completed

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borrowedAsync = ref.watch(userBorrowRequestsProvider(false));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: "My requests"
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My requests',
                    style: AppTypography.displayLarge(isDark).copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surfaceWarm,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: isDark ? AppColors.primaryLight : AppColors.olive,
                    ),
                  ),
                ],
              ),
            ),

            // Status Filter Chips: Pending, Accepted, Completed (Horizontally Scrollable)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Row(
                children: ['Pending', 'Accepted', 'Completed'].map((status) {
                  final isSelected = _selectedFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs + 2),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = status;
                          });
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Borrow Flow Visual Steps Widget (Header timeline)
            const _BorrowFlowTimeline(),

            const SizedBox(height: AppSpacing.xs),

            // List of Request Cards
            Expanded(
              child: borrowedAsync.when(
                data: (requests) {
                  final filtered = requests.where((r) {
                    if (_selectedFilter == 'Pending') return r.status == BorrowRequestStatus.pending;
                    if (_selectedFilter == 'Accepted') return r.status == BorrowRequestStatus.accepted;
                    if (_selectedFilter == 'Completed') return r.status == BorrowRequestStatus.completed;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: BorrowlyEmptyState(
                        title: 'No $_selectedFilter Requests',
                        description: 'Your $_selectedFilter borrow requests will appear here with full status timeline.',
                        icon: Icons.history_rounded,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.xs,
                      bottom: 90, // Bottom padding to scroll above floating navbar
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final req = filtered[index];
                      return _RequestItemCard(req: req, isDark: isDark);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, _) => Center(
                  child: BorrowlyEmptyState(
                    title: 'Error loading requests',
                    description: err.toString(),
                    icon: Icons.error_outline,
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

/// Visual Step-by-Step Borrow Flow Timeline matching Master Design Reference
class _BorrowFlowTimeline extends StatelessWidget {
  const _BorrowFlowTimeline();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final steps = [
      {'icon': Icons.send_rounded, 'title': 'Request'},
      {'icon': Icons.check_circle_outline_rounded, 'title': 'Accept'},
      {'icon': Icons.chat_bubble_outline_rounded, 'title': 'Chat'},
      {'icon': Icons.people_outline_rounded, 'title': 'Meet'},
      {'icon': Icons.card_giftcard_rounded, 'title': 'Handover'},
      {'icon': Icons.check_rounded, 'title': 'Received'},
      {'icon': Icons.replay_rounded, 'title': 'Return'},
      {'icon': Icons.star_outline_rounded, 'title': 'Completed'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWarm,
        borderRadius: AppRadii.borderXl,
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BORROW FLOW',
            style: AppTypography.badgeText(isDark ? AppColors.primaryLight : AppColors.primaryDark).copyWith(
              letterSpacing: 1.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(steps.length, (index) {
                final isLast = index == steps.length - 1;
                final isDone = index < 3; // First 3 active demonstration steps
                return Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDone
                                ? AppColors.primary
                                : (isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            steps[index]['icon'] as IconData,
                            size: 16,
                            color: isDone ? Colors.white : (isDark ? AppColors.darkTextMuted : AppColors.olive),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[index]['title'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                            color: isDone
                                ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                                : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (!isLast)
                      Container(
                        width: 16,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
                        color: isDone ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestItemCard extends StatelessWidget {
  final BorrowRequestEntity req;
  final bool isDark;

  const _RequestItemCard({required this.req, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BorrowlyCard(
      variant: BorrowlyCardVariant.elevated,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: AppRadii.borderLg,
                child: Image.network(
                  req.itemImage,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 68,
                    height: 68,
                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.itemTitle,
                      style: AppTypography.headingSmall(isDark).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      req.totalPrice == 0 ? 'Free' : '₹${req.totalPrice.toStringAsFixed(0)}/day',
                      style: AppTypography.bodySmall(isDark).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.near_me_rounded, size: 12, color: AppColors.olive),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '2.1 km away',
                            style: AppTypography.bodySmall(isDark),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              BorrowlyBadge(
                label: req.status.label,
                variant: req.status == BorrowRequestStatus.accepted
                    ? BorrowlyBadgeVariant.success
                    : BorrowlyBadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Pickup and Return details card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
              borderRadius: AppRadii.borderMd,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup',
                        style: AppTypography.bodySmall(isDark).copyWith(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${req.startDate.day} May, 10:00 AM',
                        style: AppTypography.bodyMedium(isDark).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Return',
                        style: AppTypography.bodySmall(isDark).copyWith(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${req.endDate.day} May, 10:00 AM',
                        style: AppTypography.bodyMedium(isDark).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

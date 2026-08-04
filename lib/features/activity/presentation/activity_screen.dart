import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/borrowly_badge.dart';
import '../../../core/widgets/borrowly_card.dart';
import '../../../core/widgets/borrowly_empty_state.dart';
import '../../../core/widgets/borrowly_toast.dart';
import '../../borrow/domain/entities/borrow_request_entity.dart';
import '../../borrow/presentation/providers/borrow_provider.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  // Mode: 0 = Borrowing (Sent), 1 = Lending (Received)
  int _selectedTabMode = 0;
  String _selectedStatusFilter = 'Pending';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwnerMode = _selectedTabMode == 1;

    final requestsAsync = ref.watch(userBorrowRequestsProvider(isOwnerMode));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar Header
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
                    'Activity & Requests',
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
                      Icons.history_rounded,
                      size: 20,
                      color: isDark ? AppColors.primaryLight : AppColors.olive,
                    ),
                  ),
                ],
              ),
            ),

            // Segment Control Toggle (Borrowing vs Lending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabMode = 0;
                            _selectedStatusFilter = 'All';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabMode == 0 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_made_rounded,
                                size: 16,
                                color: _selectedTabMode == 0 ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Borrowing (Sent)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabMode == 0 ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabMode = 1;
                            _selectedStatusFilter = 'All';
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabMode == 1 ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call_received_rounded,
                                size: 16,
                                color: _selectedTabMode == 1 ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Lending (Received)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabMode == 1 ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status Filter Chips: All, Pending, Approved, Completed, Cancelled / Declined
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Row(
                children: (isOwnerMode
                        ? ['All', 'Pending', 'Approved', 'Completed', 'Declined']
                        : ['All', 'Pending', 'Approved', 'Completed', 'Cancelled'])
                    .map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs + 2),
                    child: ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatusFilter = status;
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

            // Requests List View
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(userBorrowRequestsProvider(isOwnerMode));
                },
                child: requestsAsync.when(
                  data: (requests) {
                    final filtered = requests.where((r) {
                      if (_selectedStatusFilter == 'Pending') return r.status == BorrowRequestStatus.pending;
                      if (_selectedStatusFilter == 'Approved') return r.status == BorrowRequestStatus.accepted;
                      if (_selectedStatusFilter == 'Completed') return r.status == BorrowRequestStatus.completed;
                      if (_selectedStatusFilter == 'Cancelled') return r.status == BorrowRequestStatus.cancelled;
                      if (_selectedStatusFilter == 'Declined') return r.status == BorrowRequestStatus.rejected;
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return ListView(
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: BorrowlyEmptyState(
                              title: isOwnerMode ? 'No Incoming Lending Requests' : 'No Borrowing Requests Found',
                              description: isOwnerMode
                                  ? 'Requests from neighbors looking to borrow your items will appear here.'
                                  : 'Explore nearby neighborhood items and request to borrow tools or gear.',
                              icon: isOwnerMode ? Icons.inbox_rounded : Icons.handshake_outlined,
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        top: AppSpacing.xs,
                        bottom: 90,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final req = filtered[index];
                        return _ActivityRequestCard(
                          req: req,
                          isOwnerMode: isOwnerMode,
                          isDark: isDark,
                          onUpdateStatus: (newStatus) async {
                            final success = await ref
                                .read(borrowControllerProvider.notifier)
                                .updateStatus(req.id, newStatus);
                            if (success) {
                              ref.invalidate(userBorrowRequestsProvider(isOwnerMode));
                              if (context.mounted) {
                                String targetTab;
                                switch (newStatus) {
                                  case BorrowRequestStatus.accepted:
                                    targetTab = 'Approved';
                                    break;
                                  case BorrowRequestStatus.rejected:
                                    targetTab = 'Declined';
                                    break;
                                  case BorrowRequestStatus.cancelled:
                                    targetTab = 'Cancelled';
                                    break;
                                  case BorrowRequestStatus.completed:
                                    targetTab = 'Completed';
                                    break;
                                  default:
                                    targetTab = 'Pending';
                                }

                                setState(() {
                                  _selectedStatusFilter = targetTab;
                                });

                                BorrowlyToast.show(
                                  context,
                                  'Request updated — moved to "$targetTab" tab',
                                  icon: Icons.check_circle_outline_rounded,
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Center(
                    child: BorrowlyEmptyState(
                      title: 'Error Loading Requests',
                      description: err.toString(),
                      icon: Icons.error_outline_rounded,
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

/// Rich Activity Card with Stage Indicator, Direct Actions, Partner Info, and Rental Details
class _ActivityRequestCard extends StatelessWidget {
  final BorrowRequestEntity req;
  final bool isOwnerMode;
  final bool isDark;
  final Function(BorrowRequestStatus) onUpdateStatus;

  const _ActivityRequestCard({
    required this.req,
    required this.isOwnerMode,
    required this.isDark,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final partnerName = isOwnerMode ? req.borrowerName : req.ownerName;
    final partnerRole = isOwnerMode ? 'Borrower' : 'Owner';
    final rentalDays = req.rentalDays;
    final totalPriceStr = req.totalPrice == 0 ? 'Free Loan' : '₹${req.totalPrice.toStringAsFixed(0)} total';
    final depositStr = req.depositAmount > 0 ? ' (₹${req.depositAmount.toStringAsFixed(0)} Deposit)' : '';

    return BorrowlyCard(
      variant: BorrowlyCardVariant.elevated,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partner Header & Chat Action Button
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'N',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$partnerRole: $partnerName',
                      style: AppTypography.headingSmall(isDark).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status Badge
              BorrowlyBadge(
                label: req.status == BorrowRequestStatus.pending
                    ? 'Pending'
                    : (req.status == BorrowRequestStatus.accepted ? 'Approved' : req.status.name.toUpperCase()),
                variant: req.status == BorrowRequestStatus.accepted
                    ? BorrowlyBadgeVariant.success
                    : (req.status == BorrowRequestStatus.pending ? BorrowlyBadgeVariant.warning : BorrowlyBadgeVariant.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
          const SizedBox(height: 10),

          // Main Item Details Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
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
                      '$totalPriceStr • $rentalDays day(s)$depositStr',
                      style: AppTypography.bodySmall(isDark).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.olive),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            req.handoverLocation.isNotEmpty ? req.handoverLocation : 'In-Person Handover',
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
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Per-Card Stage Indicator Steps
          _MiniStageStepBar(status: req.status, isDark: isDark),

          const SizedBox(height: AppSpacing.md),

          // Action Buttons Footer Row
          Row(
            children: [
              // Chat Button
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    context.push('/chat/${req.itemId}');
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primary),
                  label: const Text(
                    'Chat',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Lender Approve/Decline or Borrower Action Buttons
              if (isOwnerMode && req.status == BorrowRequestStatus.pending) ...[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => onUpdateStatus(BorrowRequestStatus.rejected),
                  child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => onUpdateStatus(BorrowRequestStatus.accepted),
                  child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ] else if (req.status == BorrowRequestStatus.accepted) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => onUpdateStatus(BorrowRequestStatus.completed),
                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                  label: const Text('Mark Complete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ] else if (!isOwnerMode && req.status == BorrowRequestStatus.pending) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => onUpdateStatus(BorrowRequestStatus.cancelled),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact Visual Step Indicator rendered directly on each Request Card
class _MiniStageStepBar extends StatelessWidget {
  final BorrowRequestStatus status;
  final bool isDark;

  const _MiniStageStepBar({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (status == BorrowRequestStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, size: 14, color: AppColors.textMuted),
            SizedBox(width: 6),
            Text(
              'Request Cancelled',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    if (status == BorrowRequestStatus.rejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.block_rounded, size: 14, color: AppColors.danger),
            SizedBox(width: 6),
            Text(
              'Request Declined by Owner',
              style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    int activeStepIndex = 0;
    if (status == BorrowRequestStatus.accepted) activeStepIndex = 1;
    if (status == BorrowRequestStatus.completed) activeStepIndex = 2;

    final steps = ['Requested', 'Approved', 'Completed'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: List.generate(steps.length, (index) {
            final isDone = index <= activeStepIndex;
            final isLast = index == steps.length - 1;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 4),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                    color: isDone ? (isDark ? AppColors.primaryLight : AppColors.primaryDark) : AppColors.textMuted,
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 2,
                    color: isDone ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

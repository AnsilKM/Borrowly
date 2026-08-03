import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/widgets/borrowly_button.dart';
import 'package:borrowly/core/widgets/borrowly_card.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/features/borrow/domain/entities/borrow_request_entity.dart';
import 'package:borrowly/features/borrow/presentation/providers/borrow_provider.dart';
import 'package:borrowly/features/item/domain/entities/item_entity.dart';

class RequestBorrowBottomSheet extends ConsumerStatefulWidget {
  final ItemEntity item;

  const RequestBorrowBottomSheet({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, {required ItemEntity item}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RequestBorrowBottomSheet(item: item),
    );
  }

  @override
  ConsumerState<RequestBorrowBottomSheet> createState() => _RequestBorrowBottomSheetState();
}

class _RequestBorrowBottomSheetState extends ConsumerState<RequestBorrowBottomSheet> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  int get _rentalDays => _endDate.difference(_startDate).inDays + 1;
  double get _totalPrice => widget.item.isFree ? 0.0 : (widget.item.dailyPrice * _rentalDays);

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: _startDate.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borrowState = ref.watch(borrowControllerProvider);
    final user = ref.watch(authProvider).user;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadii.xl),
            topRight: Radius.circular(AppRadii.xl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Request to Borrow', style: AppTypography.headingMedium(isDark)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),

                // Item Summary Card
                BorrowlyCard(
                  variant: BorrowlyCardVariant.flat,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadii.borderSm,
                        child: widget.item.images.first.startsWith('http')
                            ? Image.network(
                                widget.item.images.first,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(widget.item.images.first),
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.item.title, style: AppTypography.headingSmall(isDark)),
                            Text('Owner: ${widget.item.ownerName}', style: AppTypography.bodySmall(isDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Borrow Period & Custom Day Duration Selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Borrow Period', style: AppTypography.labelText(isDark)),
                    Text(
                      '$_rentalDays Custom Day${_rentalDays > 1 ? "s" : ""}',
                      style: AppTypography.headingSmall(isDark).copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Quick Preset Chips + Stepper Container
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceSubtle : AppColors.surfaceWarm,
                    borderRadius: AppRadii.borderLg,
                  ),
                  child: Column(
                    children: [
                      // Preset Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [1, 3, 7, 14].map((days) {
                          final isSelected = _rentalDays == days;
                          return ChoiceChip(
                            label: Text('$days ${days == 1 ? "Day" : "Days"}'),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _endDate = _startDate.add(Duration(days: days - 1));
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Custom Stepper (- / +)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _rentalDays > 1
                                ? () {
                                    setState(() {
                                      _endDate = _endDate.subtract(const Duration(days: 1));
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            color: AppColors.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkBackground : Colors.white,
                              borderRadius: AppRadii.borderMd,
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$_rentalDays Days',
                              style: AppTypography.headingSmall(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _endDate = _endDate.add(const Duration(days: 1));
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Specific Date Range Pickers
                Row(
                  children: [
                    Expanded(
                      child: BorrowlyCard(
                        variant: BorrowlyCardVariant.outlined,
                        onTap: _selectStartDate,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pickup Date', style: AppTypography.bodySmall(isDark)),
                            const SizedBox(height: 2),
                            Text(
                              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                              style: AppTypography.headingSmall(isDark).copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: BorrowlyCard(
                        variant: BorrowlyCardVariant.outlined,
                        onTap: _selectEndDate,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Return Date', style: AppTypography.bodySmall(isDark)),
                            const SizedBox(height: 2),
                            Text(
                              '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                              style: AppTypography.headingSmall(isDark).copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Pricing Calculation Card
                BorrowlyCard(
                  variant: BorrowlyCardVariant.outlined,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Duration:', style: AppTypography.bodyMedium(isDark)),
                          Text('$_rentalDays day${_rentalDays > 1 ? "s" : ""}', style: AppTypography.headingSmall(isDark)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Daily Rate:', style: AppTypography.bodyMedium(isDark)),
                          Text(widget.item.formattedPrice, style: AppTypography.headingSmall(isDark)),
                        ],
                      ),
                      if (widget.item.depositAmount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Refundable Deposit:', style: AppTypography.bodyMedium(isDark)),
                            Text('\$${widget.item.depositAmount.toStringAsFixed(0)}', style: AppTypography.headingSmall(isDark)),
                          ],
                        ),
                      ],
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount:', style: AppTypography.headingMedium(isDark)),
                          Text(
                            widget.item.isFree ? 'FREE' : '\$${_totalPrice.toStringAsFixed(0)}',
                            style: AppTypography.headingLarge(isDark).copyWith(
                              color: widget.item.isFree ? AppColors.success : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Physical Payment Notice Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: AppRadii.borderMd,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Expanded(
                        child: Text(
                          'In-Person Cash Settlement: Fees & deposits are paid physically to the owner during item pickup.',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.primaryDark,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Submit Button
                BorrowlyButton(
                  label: 'Confirm & Send Request',
                  isFullWidth: true,
                  isLoading: borrowState.isLoading,
                  onPressed: () async {
                    final newRequest = BorrowRequestEntity(
                      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
                      itemId: widget.item.id,
                      itemTitle: widget.item.title,
                      itemImage: widget.item.images.first,
                      borrowerId: user?.id ?? 'guest_user_id',
                      borrowerName: user?.fullName ?? 'Alex Morgan',
                      borrowerAvatar: user?.avatarUrl,
                      ownerId: widget.item.ownerId,
                      ownerName: widget.item.ownerName,
                      ownerAvatar: widget.item.ownerAvatar,
                      startDate: _startDate,
                      endDate: _endDate,
                      totalPrice: _totalPrice,
                      depositAmount: widget.item.depositAmount,
                      status: BorrowRequestStatus.pending,
                      handoverLocation: widget.item.locationName,
                      createdAt: DateTime.now(),
                    );

                    final success = await ref.read(borrowControllerProvider.notifier).submitRequest(newRequest);

                    if (success && context.mounted) {
                      ref.invalidate(userBorrowRequestsProvider(false));
                      ref.invalidate(userBorrowRequestsProvider(true));

                      Navigator.of(context).pop();

                      BorrowlyToast.show(
                        context,
                        'Borrow request sent to ${widget.item.ownerName}!',
                        icon: Icons.send_rounded,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

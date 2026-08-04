import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/borrowly_badge.dart';
import '../../../core/widgets/borrowly_button.dart';
import '../../../core/widgets/borrowly_card.dart';
import '../../../core/widgets/borrowly_empty_state.dart';
import '../../../core/widgets/borrowly_text_field.dart';

class DesignSystemScreen extends ConsumerWidget {
  const DesignSystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrowly Design System'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: Icon(
              Icons.wb_sunny_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            BorrowlyCard(
              variant: BorrowlyCardVariant.flat,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_outlined, color: AppColors.textPrimary, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sprint 0 — Foundation Showcase', style: AppTypography.headingSmall(isDark)),
                            Text('Hyper-local Peer-to-Peer Marketplace (Max Radius: 5 km)', style: AppTypography.bodySmall(isDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Color Swatches Section
            _SectionHeader(title: 'Color Palette Tokens', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            const Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _ColorSwatch(color: AppColors.primary, label: 'Primary\n#D4A017'),
                _ColorSwatch(color: AppColors.primaryDark, label: 'Dark\n#B8860B'),
                _ColorSwatch(color: AppColors.primaryLight, label: 'Light\n#F4D35E'),
                _ColorSwatch(color: AppColors.accent, label: 'Accent\n#FFD166'),
                _ColorSwatch(color: AppColors.background, label: 'Bg\n#FAF8F2', isLightText: false),
                _ColorSwatch(color: AppColors.darkBackground, label: 'Dark Bg\n#181818'),
                _ColorSwatch(color: AppColors.success, label: 'Success\n#2E7D32'),
                _ColorSwatch(color: AppColors.danger, label: 'Danger\n#D32F2F'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Distance Radius Badges Section
            _SectionHeader(title: 'Distance Radii & Status Badges', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            const Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                BorrowlyBadge(label: '1 km', icon: Icon(Icons.near_me, size: 12, color: AppColors.primaryDark)),
                BorrowlyBadge(label: '2 km', icon: Icon(Icons.near_me, size: 12, color: AppColors.primaryDark)),
                BorrowlyBadge(label: '3 km', icon: Icon(Icons.near_me, size: 12, color: AppColors.primaryDark)),
                BorrowlyBadge(label: '5 km (Max)', icon: Icon(Icons.near_me, size: 12, color: AppColors.primaryDark)),
                BorrowlyBadge(label: 'Available', variant: BorrowlyBadgeVariant.success),
                BorrowlyBadge(label: 'Free Item', variant: BorrowlyBadgeVariant.warning),
                BorrowlyBadge(label: 'Reserved', variant: BorrowlyBadgeVariant.neutral),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Reusable Buttons Section
            _SectionHeader(title: 'Reusable Buttons', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                BorrowlyButton(
                  label: 'Primary Action',
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18, color: AppColors.textPrimary),
                ),
                BorrowlyButton(
                  label: 'Secondary Action',
                  variant: BorrowlyButtonVariant.secondary,
                  onPressed: () {},
                ),
                BorrowlyButton(
                  label: 'Outline',
                  variant: BorrowlyButtonVariant.outline,
                  onPressed: () {},
                ),
                BorrowlyButton(
                  label: 'Loading State',
                  isLoading: true,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Form Components Section
            _SectionHeader(title: 'Form & Input Components', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            const BorrowlyTextField(
              label: 'Search Items Nearby',
              hintText: 'e.g. Lawn mower, Power drill, Camping tent...',
              prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            const BorrowlyTextField(
              label: 'Delivery Note (Physical Handover Only)',
              hintText: 'No delivery allowed. Physical meetup required.',
              prefixIcon: Icon(Icons.handshake_outlined, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Responsive Layout Demonstration
            _SectionHeader(title: 'Responsive Grid Adaptability', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            ResponsiveLayout(
              mobile: Column(
                children: [
                  _SampleItemCard(title: 'DeWalt Cordless Drill (Mobile View)', distance: '1 km', price: '₹5/day', isDark: isDark),
                  const SizedBox(height: AppSpacing.sm),
                  _SampleItemCard(title: 'Camping Tent 4-Person', distance: '2 km', price: 'Free', isDark: isDark),
                ],
              ),
              tablet: Row(
                children: [
                  Expanded(child: _SampleItemCard(title: 'DeWalt Cordless Drill (Tablet View)', distance: '1 km', price: '₹5/day', isDark: isDark)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SampleItemCard(title: 'Camping Tent 4-Person', distance: '2 km', price: 'Free', isDark: isDark)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Empty State Component Demo
            _SectionHeader(title: 'Standard Empty State Component', isDark: isDark),
            const SizedBox(height: AppSpacing.sm),
            BorrowlyCard(
              variant: BorrowlyCardVariant.outlined,
              child: BorrowlyEmptyState(
                title: 'No Borrow Requests Yet',
                description: 'Explore your local neighborhood within 5 km to borrow or share items.',
                actionLabel: 'Explore Neighborhood',
                onActionPressed: () {},
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.headingMedium(isDark),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLightText;

  const _ColorSwatch({
    required this.color,
    required this.label,
    this.isLightText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 70,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadii.borderSm,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isLightText ? Colors.white : Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SampleItemCard extends StatelessWidget {
  final String title;
  final String distance;
  final String price;
  final bool isDark;

  const _SampleItemCard({
    required this.title,
    required this.distance,
    required this.price,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return BorrowlyCard(
      variant: BorrowlyCardVariant.outlined,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: AppRadii.borderSm,
            ),
            child: const Icon(Icons.build_outlined, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headingSmall(isDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    BorrowlyBadge(label: distance),
                    const SizedBox(width: AppSpacing.xs),
                    Text(price, style: AppTypography.bodySmall(isDark).copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/location/location_provider.dart';
import '../../../core/utils/responsive_layout.dart';
import 'package:borrowly/core/utils/avatar_provider_util.dart';
import '../../../core/widgets/borrowly_badge.dart';
import '../../../core/widgets/borrowly_button.dart';
import '../../../core/widgets/borrowly_card.dart';
import '../../../core/widgets/borrowly_empty_state.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../item/presentation/providers/home_items_provider.dart';
import '../../item/presentation/providers/wishlist_provider.dart';
import '../../item/presentation/widgets/category_selection_bottom_sheet.dart';
import '../../item/presentation/widgets/category_selector.dart';
import '../../item/presentation/widgets/home_search_bar.dart';
import '../../item/presentation/widgets/item_card.dart';
import '../../item/presentation/widgets/item_card_skeleton.dart';
import 'widgets/location_search_bottom_sheet.dart';
import 'widgets/radius_step_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // After first frame, check if we need to show the permission dialog
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLocationPermission());
  }

  Future<void> _checkLocationPermission() async {
    final locationState = await ref.read(activeLocationProvider.future);
    if (!mounted) return;

    if (locationState.isPermanentlyDenied) {
      _showPermissionDialog(permanent: true);
    } else if (locationState.isDenied) {
      _showPermissionDialog(permanent: false);
    }
  }

  void _showPermissionDialog({required bool permanent}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? AppColors.darkSurface
            : AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Enable Location',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Text(
          permanent
              ? 'Location access is permanently disabled. Open Settings and enable it so Borrowly can show items near you.'
              : 'Allow Borrowly to access your location to show items from real neighbors nearby.',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (permanent) {
                await ref
                    .read(locationServiceProvider)
                    .openSettings();
              } else {
                await ref
                    .read(activeLocationProvider.notifier)
                    .refreshGps();
              }
            },
            icon: Icon(permanent ? Icons.settings_rounded : Icons.my_location_rounded,
                size: 16),
            label: Text(permanent ? 'Open Settings' : 'Enable Location'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final selectedRadius = ref.watch(selectedRadiusProvider);
    final topPadding = MediaQuery.of(context).viewPadding.top;

    final nearbyItemsAsync = ref.watch(nearbyItemsProvider);
    final freeItemsAsync = ref.watch(freeItemsProvider);
    final recentlyAddedAsync = ref.watch(recentlyAddedItemsProvider);

    final userName = (user != null && user.fullName.isNotEmpty && !user.isGuest)
        ? user.fullName.split(' ').first
        : 'Neighbor';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(nearbyItemsProvider);
            ref.invalidate(freeItemsProvider);
            ref.invalidate(recentlyAddedItemsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
            slivers: [
              // 1. Sleek Pinned Header & Search Bar (Greeting, Location, Wishlist, Avatar & Search Bar stay fixed!)
              SliverPersistentHeader(
                pinned: true,
                delegate: _HomeScreenPinnedHeaderDelegate(
                  topPadding: topPadding,
                  isDark: isDark,
                  userName: userName,
                  selectedRadius: selectedRadius,
                  authState: authState,
                  user: user,
                ),
              ),

              // 2. Location Status Banner (shown only when GPS is not yet set)
              Consumer(
                builder: (context, ref, _) {
                  final locationState = ref.watch(activeLocationProvider);
                  final locationValue = locationState.valueOrNull;
                  final needsBanner = locationValue == null ||
                      locationValue.status == LocationStatus.denied ||
                      !locationValue.hasLocation;

                  if (!needsBanner) return const SliverToBoxAdapter(child: SizedBox.shrink());

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => LocationSearchBottomSheet.show(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_off_rounded,
                                  color: AppColors.accent,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Set your location to see items near you',
                                    style: AppTypography.bodySmall(false).copyWith(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColors.accent,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 4. Categories Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.md,
                    bottom: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Categories',
                        style: AppTypography.headingMedium(isDark).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => CategorySelectionBottomSheet.show(context),
                        child: Text(
                          'View all',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Horizontal Category Selector Chips
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: CategorySelector(),
                ),
              ),

              // Community Needs section removed — will be implemented in a future release

              // 6. Section: Free Shares Carousel (Zero-Cost Neighbor Loans)
              freeItemsAsync.when(
                data: (freeItems) {
                  if (freeItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Row(
                            children: [
                              Text(
                                'Free Community Loans',
                                style: AppTypography.headingMedium(isDark).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const BorrowlyBadge(
                                label: 'FREE 🎁',
                                variant: BorrowlyBadgeVariant.success,
                               ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        SizedBox(
                          height: 245,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: freeItems.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 175,
                                child: ItemCard(item: freeItems[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // 7. Section: Nearby Available Items Grid Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    top: AppSpacing.lg,
                    bottom: AppSpacing.xs,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Nearby Items',
                            style: AppTypography.headingMedium(isDark).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          BorrowlyBadge(
                            label: '$selectedRadius km',
                            variant: BorrowlyBadgeVariant.distance,
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.productList),
                        child: Text(
                          'See All →',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 8. Nearby Items Grid View
              nearbyItemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: BorrowlyCard(
                          variant: BorrowlyCardVariant.warm,
                          child: Column(
                            children: [
                              BorrowlyEmptyState(
                                title: 'No Items Within $selectedRadius km',
                                description: 'Expand your neighborhood radius or post a request so nearby neighbors can lend it to you.',
                                icon: Icons.near_me_disabled_outlined,
                                actionLabel: 'Expand Radius to 5 km',
                                onActionPressed: () {
                                  ref.read(selectedRadiusProvider.notifier).state = 5;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final crossAxisCount = context.responsiveValue<int>(
                    mobile: 2,
                    tablet: 3,
                    desktop: 4,
                  );

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ItemCard(item: items[index]);
                        },
                        childCount: items.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ItemCardSkeleton(),
                      childCount: 4,
                    ),
                  ),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: BorrowlyCard(
                      variant: BorrowlyCardVariant.outlined,
                      child: BorrowlyEmptyState(
                        title: 'Unable to Load Items',
                        description: error.toString(),
                        icon: Icons.error_outline,
                        actionLabel: 'Retry',
                        onActionPressed: () => ref.invalidate(nearbyItemsProvider),
                      ),
                    ),
                  ),
                ),
              ),

              // 9. Section: Recently Added Items Carousel
              recentlyAddedAsync.when(
                data: (recentItems) {
                  if (recentItems.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recently Added',
                                style: AppTypography.headingMedium(isDark).copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.push(AppRoutes.search),
                                child: Text(
                                  'See all',
                                  style: AppTypography.bodySmall(isDark).copyWith(
                                    color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        SizedBox(
                          height: 245,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: recentItems.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 175,
                                child: ItemCard(item: recentItems[index]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl + 80)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScreenPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double topPadding;
  final bool isDark;
  final String userName;
  final int selectedRadius;
  final AuthState authState;
  final dynamic user;

  _HomeScreenPinnedHeaderDelegate({
    required this.topPadding,
    required this.isDark,
    required this.userName,
    required this.selectedRadius,
    required this.authState,
    required this.user,
  });

  static const double _kmBarHeight = 44.0;

  @override
  double get minExtent => (topPadding > 0 ? topPadding : 16.0) + 168.0;

  @override
  double get maxExtent => (topPadding > 0 ? topPadding : 16.0) + 168.0 + _kmBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / _kmBarHeight).clamp(0.0, 1.0);
    final kmOpacity = (1.0 - progress).clamp(0.0, 1.0);
    final currentKmHeight = _kmBarHeight * (1.0 - progress);
    final currentExtent = math.max(minExtent, maxExtent - shrinkOffset);

    return SizedBox(
      height: currentExtent,
      child: Container(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: topPadding > 0 ? topPadding + 10.0 : 16.0,
          bottom: 8.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Greeting & User Profile Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Greeting Title
                Row(
                  children: [
                    Text(
                      'Hello, $userName',
                      style: AppTypography.displayLarge(isDark).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 18)),
                  ],
                ),

                // Actions: Wishlist Heart & User Avatar / Sign In
                Row(
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final wishlistedCount =
                            ref.watch(wishlistIdsProvider).length;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.surfaceWarm,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: wishlistedCount > 0
                                      ? AppColors.danger.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  wishlistedCount > 0
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: wishlistedCount > 0
                                      ? AppColors.danger
                                      : (isDark
                                          ? Colors.white70
                                          : AppColors.textSecondary),
                                  size: 18,
                                ),
                                onPressed: () =>
                                    context.push(AppRoutes.wishlist),
                              ),
                            ),
                            if (wishlistedCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$wishlistedCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (authState.isGuest)
                      BorrowlyButton(
                        label: 'Sign In',
                        size: BorrowlyButtonSize.small,
                        variant: BorrowlyButtonVariant.outline,
                        onPressed: () => context.push(AppRoutes.login),
                      )
                    else
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.profile),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: AppColors.primary, width: 2),
                            boxShadow: AppShadows.subtle,
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.surfaceWarm,
                            backgroundImage: getAvatarImageProvider(user?.displayAvatarUrl),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Row 2: Location Chip & Neighbor Count Badge
            Consumer(
              builder: (context, ref, _) {
                final locationState =
                    ref.watch(activeLocationProvider).valueOrNull;
                final fix = locationState?.fix;
                final neighborCount =
                    ref.watch(uniqueNearbyNeighborsProvider);

                final locationLabel = fix != null
                    ? '📍 ${fix.localityName} • $selectedRadius km'
                    : '📍 Set Location • $selectedRadius km';

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            LocationSearchBottomSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: AppRadii.borderPill,
                            border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall(isDark)
                                    .copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (neighborCount > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        BorrowlyBadge(
                          label:
                              '👥 $neighborCount Neighbor${neighborCount == 1 ? "" : "s"}',
                          variant: BorrowlyBadgeVariant.primary,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Collapsible KM Radius Section (Fades & collapses smoothly as user scrolls)
            if (currentKmHeight > 0.5)
              ClipRect(
                child: SizedBox(
                  height: currentKmHeight,
                  child: Opacity(
                    opacity: kmOpacity,
                    child: const Center(
                      child: RadiusStepBar(),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 6),
            const HomeSearchBar(),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HomeScreenPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.topPadding != topPadding ||
        oldDelegate.isDark != isDark ||
        oldDelegate.userName != userName ||
        oldDelegate.selectedRadius != selectedRadius ||
        oldDelegate.authState != authState ||
        oldDelegate.user != user;
  }
}

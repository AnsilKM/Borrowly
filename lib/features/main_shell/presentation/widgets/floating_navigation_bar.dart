import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class FloatingNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final bool isNavVisible;
  final double bottomInset;
  final int unreadNotifs;
  final ValueChanged<int> onItemTapped;
  final VoidCallback onAddPressed;

  const FloatingNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.isNavVisible,
    required this.bottomInset,
    required this.unreadNotifs,
    required this.onItemTapped,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: bottomInset > 0 ? bottomInset + AppSpacing.xs : AppSpacing.md,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
        offset: isNavVisible ? Offset.zero : const Offset(0, 2.2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          opacity: isNavVisible ? 1.0 : 0.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: AppShadows.floatingNav,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FloatingNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                      isSelected: selectedIndex == 0,
                      onTap: () => onItemTapped(0),
                    ),
                    _FloatingNavItem(
                      icon: Icons.sync_alt_rounded,
                      activeIcon: Icons.sync_alt_rounded,
                      label: 'Activity',
                      isSelected: selectedIndex == 1,
                      onTap: () => onItemTapped(1),
                    ),

                    // Center Floating Add Button (+ Action)
                    GestureDetector(
                      onTap: onAddPressed,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    _FloatingNavItem(
                      icon: unreadNotifs > 0 ? Icons.mark_chat_unread_outlined : Icons.chat_bubble_outline_rounded,
                      activeIcon: unreadNotifs > 0 ? Icons.mark_chat_unread_rounded : Icons.chat_bubble_rounded,
                      label: 'Messages',
                      isSelected: selectedIndex == 2,
                      badgeCount: unreadNotifs,
                      onTap: () => onItemTapped(2),
                    ),
                    _FloatingNavItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'Profile',
                      isSelected: selectedIndex == 3,
                      onTap: () => onItemTapped(3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = AppColors.primary;
    final inactiveColor = isDark ? AppColors.darkTextMuted : AppColors.olive;

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? activeColor.withValues(alpha: 0.22)
                    : activeColor.withValues(alpha: 0.15))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      color: isSelected
                          ? (isDark ? AppColors.primaryLight : AppColors.primaryDark)
                          : inactiveColor,
                      size: 22,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 12 : 0,
                height: isSelected ? 3 : 0,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

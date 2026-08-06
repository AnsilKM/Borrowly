import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:borrowly/app/router/app_router.dart';
import 'package:borrowly/app/router/routes.dart';
import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_spacing.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/core/utils/borrowly_logger.dart';
import 'package:borrowly/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  void _navigateAfterAuth() {
    if (!mounted || _navigationScheduled) return;
    final authState = ref.read(authProvider);
    // Only navigate when auth has resolved (not initial or loading)
    if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) return;

    _navigationScheduled = true;
    final pendingLink = ref.read(pendingDeepLinkProvider);

    if (pendingLink != null && pendingLink.isNotEmpty) {
      // Clear the pending link before navigating
      ref.read(pendingDeepLinkProvider.notifier).state = null;
      BorrowlyLogger.info('🚀 SplashScreen: Navigating to home + pushing deep link: $pendingLink');
      // Go to home first (puts home in back stack), then push the deep link target
      final router = ref.read(routerProvider);
      router.go(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.push(pendingLink);
      });
    } else {
      BorrowlyLogger.info('🏠 SplashScreen: Navigating to home (no pending deep link)');
      ref.read(routerProvider).go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch auth state - triggers rebuild when auth resolves.
    // _navigateAfterAuth will skip if loading/initial, fire when ready.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status != AuthStatus.initial && next.status != AuthStatus.loading) {
        Future.delayed(const Duration(milliseconds: 1000), _navigateAfterAuth);
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkSurface,
                    AppColors.darkBackground,
                  ]
                : [
                    AppColors.background,
                    AppColors.surfaceSubtle,
                    AppColors.background,
                  ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Premium App Icon Badge Component
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 36,
                        spreadRadius: 4,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Animated Brand Title & Subtitle
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Borrowly',
                        style: AppTypography.displayLarge(isDark).copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Hyper-Local Neighborhood Sharing',
                        style: AppTypography.headingSmall(isDark).copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: AppRadii.borderFull,
                        ),
                        child: Text(
                          '1–5 km Radius • Zero Fees',
                          style: AppTypography.bodySmall(isDark).copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 3. Loading Ring
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

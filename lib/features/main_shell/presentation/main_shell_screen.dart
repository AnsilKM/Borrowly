import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:borrowly/app/router/routes.dart';
import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/core/utils/borrowly_logger.dart';
import 'package:borrowly/core/widgets/borrowly_toast.dart';
import 'package:borrowly/features/main_shell/presentation/widgets/floating_navigation_bar.dart';
import 'package:borrowly/features/notification/presentation/providers/notification_provider.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late final ValueNotifier<bool> _isNavVisibleNotifier;
  late final ValueNotifier<bool> _isScrolledNotifier;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _isNavVisibleNotifier = ValueNotifier<bool>(true);
    _isScrolledNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isNavVisibleNotifier.dispose();
    _isScrolledNotifier.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onAddPressed() {
    context.push(AppRoutes.addItem);
  }

  Future<bool> _onBackInvoked() async {
    final location = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final routerCanPop = GoRouter.of(context).canPop();
    final shellIndex = widget.navigationShell.currentIndex;

    BorrowlyLogger.info(
      'Shell: _onBackInvoked | location=$location | '
      'routerCanPop=$routerCanPop | shellIndex=$shellIndex',
    );

    // 0. If the current route is an external screen opened via deep link
    //    (e.g. /item/:id or /owner/:id navigated via go(), not push()),
    //    go back to Home instead of triggering the shell exit logic.
    if (location.startsWith('/item/') || location.startsWith('/owner/')) {
      BorrowlyLogger.info('Shell: Deep link route detected → going to home');
      context.go(AppRoutes.home);
      return true;
    }

    // 1. If top route can pop (e.g. detail screen open via push), pop top route
    if (routerCanPop) {
      BorrowlyLogger.info('Shell: routerCanPop=true → popping top route');
      context.pop();
      return true;
    }

    // 2. If on any non-Home tab (Activity, Messages, Profile), return to Home tab (index 0)
    if (shellIndex != 0) {
      BorrowlyLogger.info('Shell: Non-home tab (index=$shellIndex) → going to home branch');
      widget.navigationShell.goBranch(0);
      return true;
    }

    // 3. On Home tab (index 0), double-tap back to exit app
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      BorrowlyLogger.info('Shell: Home tab, first back press → showing exit toast');
      if (mounted) {
        BorrowlyToast.show(
          context,
          'Press back again to exit Borrowly',
          icon: Icons.exit_to_app_rounded,
        );
      }
      return true;
    }

    BorrowlyLogger.info('Shell: Home tab, second back press → allowing app exit');
    return false; // Second press on Home -> allow exit
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = widget.navigationShell.currentIndex;
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final topInset = MediaQuery.of(context).viewPadding.top;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final imeBottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isImeOpen = imeBottomInset > 0;

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );

    return BackButtonListener(
      onBackButtonPressed: () {
        BorrowlyLogger.info('Shell: BackButtonListener fired');
        return _onBackInvoked();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          BorrowlyLogger.info('Shell: PopScope.onPopInvokedWithResult | didPop=$didPop');
          if (!didPop) {
            _onBackInvoked();
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemOverlayStyle,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
            body: Stack(
              children: [
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis != Axis.vertical) return false;

                      final pixels = notification.metrics.pixels;
                      final isScrolledNow = pixels > 15;

                      if (isScrolledNow != _isScrolledNotifier.value) {
                        _isScrolledNotifier.value = isScrolledNow;
                      }

                      if (pixels <= 20) {
                        if (!_isNavVisibleNotifier.value) {
                          _isNavVisibleNotifier.value = true;
                        }
                        return false;
                      }

                      if (notification is ScrollUpdateNotification) {
                        final delta = notification.scrollDelta ?? 0;
                        if (delta > 6.0 && _isNavVisibleNotifier.value) {
                          _isNavVisibleNotifier.value = false;
                        } else if (delta < -6.0 && !_isNavVisibleNotifier.value) {
                          _isNavVisibleNotifier.value = true;
                        }
                      }
                      return false;
                    },
                    child: widget.navigationShell,
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isScrolledNotifier,
                    builder: (context, isScrolled, _) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: topInset,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                      );
                    },
                  ),
                ),

                ValueListenableBuilder<bool>(
                  valueListenable: _isNavVisibleNotifier,
                  builder: (context, isNavVisible, _) {
                    final effectiveVisible = isNavVisible && !isImeOpen;
                    return FloatingNavigationBar(
                      selectedIndex: selectedIndex,
                      isNavVisible: effectiveVisible,
                      bottomInset: bottomInset,
                      unreadNotifs: unreadNotifs,
                      onItemTapped: _onItemTapped,
                      onAddPressed: _onAddPressed,
                    );
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

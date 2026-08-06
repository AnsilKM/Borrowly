import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class BorrowlyScrollBehavior extends MaterialScrollBehavior {
  const BorrowlyScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Disables overscroll stretching & bouncing UI shift globally
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}

class BorrowlyApp extends ConsumerWidget {
  const BorrowlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return MaterialApp.router(
      title: 'Borrowly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      scrollBehavior: const BorrowlyScrollBehavior(),
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(0.94),
          ),
          child: child!,
        );
      },
    );
  }
}

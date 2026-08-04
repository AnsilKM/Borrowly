import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:borrowly/core/utils/borrowly_logger.dart';
import 'package:borrowly/app/theme/app_colors.dart';
import 'package:borrowly/app/theme/app_typography.dart';
import 'package:borrowly/features/activity/presentation/activity_screen.dart';
import 'package:borrowly/features/auth/presentation/screens/login_screen.dart';
import 'package:borrowly/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:borrowly/features/chat/presentation/screens/chat_screen.dart';
import 'package:borrowly/features/chat/presentation/screens/conversation_list_screen.dart';
import 'package:borrowly/features/design_system/presentation/design_system_screen.dart';
import 'package:borrowly/features/home/presentation/home_screen.dart';
import 'package:borrowly/features/item/presentation/screens/add_item_screen.dart';
import 'package:borrowly/features/item/presentation/screens/item_details_screen.dart';
import 'package:borrowly/features/main_shell/presentation/main_shell_screen.dart';
import 'package:borrowly/features/notification/presentation/screens/notification_screen.dart';
import 'package:borrowly/features/profile/presentation/owner_profile_screen.dart';
import 'package:borrowly/features/profile/presentation/profile_screen.dart';
import 'package:borrowly/features/search/presentation/search_screen.dart';
import 'package:borrowly/features/splash/presentation/splash_screen.dart';
import 'package:borrowly/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:borrowly/core/widgets/legal_webview_screen.dart';
import 'package:borrowly/features/item/presentation/screens/product_list_screen.dart';
import 'routes.dart';


/// Helper builder for sleek horizontal slide & fade page transitions
CustomTransitionPage<void> _buildSlideTransitionPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  Offset beginOffset = const Offset(1.0, 0.0),
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curveAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn,
      );

      final slideAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(curveAnimation);

      final fadeAnimation = Tween<double>(
        begin: 0.85,
        end: 1.0,
      ).animate(curveAnimation);

      return SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: child,
        ),
      );
    },
  );
}

/// Stores a deep link path that arrived while the app was cold-starting.
/// The SplashScreen reads this and resolves navigation after auth is ready.
final pendingDeepLinkProvider = StateProvider<String?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final uri = state.uri;
      final scheme = uri.scheme;
      final host = uri.host;
      final path = uri.path;

      // Known internal app routes that should NEVER be treated as deep links.
      // The redirect must not intercept internal context.push/go calls.
      final isInternalRoute =
          path.startsWith('/chat/') ||
          path.startsWith('/item/') ||
          path.startsWith('/owner/') ||
          path.startsWith('/activity') ||
          path.startsWith('/profile') ||
          path.startsWith('/search') ||
          path.startsWith('/wishlist') ||
          path.startsWith('/notifications') ||
          path.startsWith('/add-item') ||
          path.startsWith('/chat-list') ||
          path == AppRoutes.home;

      // Log incoming link only if it carries external info worth tracing.
      if (scheme == 'borrowly' || (!isInternalRoute && uri.queryParameters.isNotEmpty)) {
        BorrowlyLogger.event('DeepLink: Received Link', parameters: {
          'fullUri': uri.toString(),
          'scheme': scheme,
          'host': host,
          'path': path,
          'queryParams': uri.queryParameters,
          'isInternalRoute': isInternalRoute,
        });
      }

      // Resolve the deep link target path.
      String? resolvedTarget;

      // 1. Handle custom scheme: borrowly://item/<id> or borrowly://owner/<id>
      //    Custom scheme links always come from Android OS, never from internal navigation.
      if (scheme == 'borrowly') {
        if (host == 'item') {
          final id = path.replaceAll('/', '');
          if (id.isNotEmpty) {
            resolvedTarget = '/item/$id';
            BorrowlyLogger.info('🔗 DeepLink Parsed (Custom Scheme Item): $resolvedTarget');
          }
        } else if (host == 'owner') {
          final id = path.replaceAll('/', '');
          if (id.isNotEmpty) {
            resolvedTarget = '/owner/$id';
            BorrowlyLogger.info('🔗 DeepLink Parsed (Custom Scheme Owner): $resolvedTarget');
          }
        }
      }

      // 2. Handle HTTPS query parameters: ?item=<uuid> or ?owner=<uuid>
      //    ONLY on non-internal routes (i.e. links arriving from GitHub Pages web app).
      //    This prevents intercepting internal routes like /chat/:id?item=Title.
      if (resolvedTarget == null && !isInternalRoute) {
        final itemParam = uri.queryParameters['item'];
        if (itemParam != null && itemParam.isNotEmpty) {
          resolvedTarget = '/item/$itemParam';
          BorrowlyLogger.info('🔗 DeepLink Parsed (Web Query Item): $resolvedTarget');
        }
      }

      if (resolvedTarget == null && !isInternalRoute) {
        final ownerParam = uri.queryParameters['owner'];
        if (ownerParam != null && ownerParam.isNotEmpty) {
          resolvedTarget = '/owner/$ownerParam';
          BorrowlyLogger.info('🔗 DeepLink Parsed (Web Query Owner): $resolvedTarget');
        }
      }

      // 3. If we have a deep link target, decide how to handle it:
      if (resolvedTarget != null) {
        // If app is on splash (cold start), store the link and let splash
        // handle navigation after auth is resolved. This ensures:
        //   a) Auth state is ready before item screen renders.
        //   b) Home is in the back stack so back button works correctly.
        if (path == AppRoutes.splash) {
          ref.read(pendingDeepLinkProvider.notifier).state = resolvedTarget;
          BorrowlyLogger.info('📌 DeepLink stored for post-auth navigation: $resolvedTarget');
          return null; // Stay on splash, let SplashScreen handle it
        }

        // If app is already running (warm open), push the target on top of current stack
        // so Home (or current route) remains in the back stack for system back navigation.
        if (path != resolvedTarget) {
          BorrowlyLogger.info('🚀 DeepLink Resolved (Warm Open Push): $resolvedTarget');
          final target = resolvedTarget;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GoRouter.of(context).push(target);
          });
          return null;
        }
      }

      // 4. Handle /Borrowly root path redirect (GitHub Pages)
      if (path == '/Borrowly' || path == '/Borrowly/') {
        return AppRoutes.home;
      }

      return null;
    },
    errorBuilder: (context, state) {
      BorrowlyLogger.warning('⚠️ Unmapped Route Triggered ErrorBuilder: ${state.uri}');
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Borrowly'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_outlined, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: AppTypography.headingLarge(isDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Requested URL: ${state.uri}',
                style: AppTypography.bodySmall(isDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Return to Home'),
              ),
            ],
          ),
        ),
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const LoginScreen(),
          beginOffset: const Offset(0.0, 1.0),
        ),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const ProfileSetupScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.addItem,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const AddItemScreen(),
          beginOffset: const Offset(0.0, 1.0),
        ),
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const SearchScreen(),
          beginOffset: const Offset(0.0, 1.0),
        ),
      ),
      GoRoute(
        path: '/item/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildSlideTransitionPage(
            context: context,
            state: state,
            child: ItemDetailsScreen(itemId: id),
          );
        },
      ),
      GoRoute(
        path: '/chat/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Neighbor Chat';
          final item = state.uri.queryParameters['item'] ?? '';
          return _buildSlideTransitionPage(
            context: context,
            state: state,
            child: ChatScreen(conversationId: id, participantName: title, itemTitle: item),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.wishlist,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const WishlistScreen(),
        ),
      ),
      GoRoute(
        path: '/owner/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final name = state.uri.queryParameters['name'] ?? 'Neighbor Owner';
          final avatar = state.uri.queryParameters['avatar'];
          final item = state.uri.queryParameters['item'];
          return _buildSlideTransitionPage(
            context: context,
            state: state,
            child: OwnerProfileScreen(
              ownerId: id,
              ownerName: name,
              ownerAvatar: avatar,
              itemTitle: item,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const NotificationScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.terms,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const LegalWebViewScreen(
            title: 'Terms & Conditions',
            url: 'https://ansilkm.github.io/Borrowly/terms.html',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const LegalWebViewScreen(
            title: 'Privacy Policy',
            url: 'https://ansilkm.github.io/Borrowly/privacy.html',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.myListings,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const ProductListScreen(
            title: 'My Listings',
            isMyListings: true,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.productList,
        pageBuilder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Nearby Items';
          final isMyListings = state.uri.queryParameters['my'] == 'true';
          return _buildSlideTransitionPage(
            context: context,
            state: state,
            child: ProductListScreen(
              title: title,
              isMyListings: isMyListings,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.designSystem,
        pageBuilder: (context, state) => _buildSlideTransitionPage(
          context: context,
          state: state,
          child: const DesignSystemScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.activity,
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chatList,
                builder: (context, state) => const ConversationListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

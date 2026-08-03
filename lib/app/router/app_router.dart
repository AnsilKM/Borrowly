import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
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

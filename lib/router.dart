import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/auth_controller.dart';
import 'core/models/user_model.dart';
import 'features/ride/ride_screen.dart';
import 'features/market/market_screen.dart';
import 'features/social/social_feed_screen.dart';
import 'features/social/create_post_screen.dart';
import 'features/activity/activity_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/shop_application_screen.dart';
import 'features/admin/admin_panel_screen.dart';
import 'features/ops_center/ops_center_screen.dart';
import 'features/shop/screens/shop_dashboard_screen.dart';
import 'features/shop/screens/shop_settings_screen.dart';
import 'features/shop/screens/add_product_screen.dart';
import 'features/ride/ride_chat_screen.dart';
import 'features/ride/shared_ride_screen.dart';
import 'features/market/food_groceries_screen.dart';
import 'core/layout/scaffold_with_navbar.dart';
import 'features/designer/screens/designer_panel_screen.dart';
import 'features/social/shared_post_screen.dart';

/// Router provider for GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  // Create keys for navigation to allow contextless navigation if needed
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/ride',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // Allow unauthenticated access to shared content routes
      final isSharedRoute = state.matchedLocation.startsWith('/shared/');

      // If not authenticated and not on login page or shared route, redirect to login
      if (!isAuthenticated && !isLoggingIn && !isSharedRoute) {
        return '/login';
      }

      // If authenticated
      if (isAuthenticated) {
        final user = authState.user;

        // If on login page, redirect based on role
        if (isLoggingIn) {
          if (user.role == UserRole.admin) return '/admin';
          if (user.role == UserRole.shop) return '/shop-dashboard';
          // Designers use normal app flow (access designer panel from profile)
          return '/ride';
        }

        // Force Designers to Designer Panel
        if (user.role == UserRole.designer &&
            !state.matchedLocation.startsWith('/designer')) {
          return '/designer';
        }
      }

      return null;
    },
    routes: [
      // Login Route
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Main App Shell (Bottom Navigation)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Ride Branch (Home)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ride',
                name: 'ride',
                builder: (context, state) => const RideScreen(),
              ),
            ],
          ),

          // Market Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/market',
                name: 'market',
                builder: (context, state) => const MarketScreen(),
                routes: [
                  GoRoute(
                    path: 'food-groceries',
                    name: 'food-groceries',
                    builder: (context, state) => const FoodGroceriesScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Social Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                name: 'social',
                builder: (context, state) => const SocialFeedScreen(),
              ),
            ],
          ),

          // Profile Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  // Nested routes can go here
                ],
              ),
            ],
          ),
        ],
      ),

      // Independent Routes (Full Screen)
      GoRoute(
        path: '/activity',
        name: 'activity',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ActivityScreen(),
      ),
      GoRoute(
        path: '/shop-apply',
        name: 'shop-apply',
        parentNavigatorKey: rootNavigatorKey, // Hide bottom nav
        builder: (context, state) => const ShopApplicationScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        parentNavigatorKey: rootNavigatorKey, // Hide bottom nav
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/designer',
        name: 'designer',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DesignerPanelScreen(),
      ),
      GoRoute(
        path: '/ops',
        name: 'ops',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OpsCenterScreen(),
      ),
      GoRoute(
        path: '/shop-dashboard',
        name: 'shop-dashboard',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShopDashboardScreen(),
      ),
      GoRoute(
        path: '/shop-settings',
        name: 'shop-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShopSettingsScreen(),
      ),
      GoRoute(
        path: '/shop/add-product',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/social/create',
        name: 'create-post',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/ride/:rideId/chat',
        name: 'ride-chat',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final rideId = state.pathParameters['rideId']!;
          return RideChatScreen(rideId: rideId);
        },
      ),
      // Shared content routes (accessible without auth for preview)
      GoRoute(
        path: '/shared/ride/:rideId',
        name: 'shared-ride',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final rideId = state.pathParameters['rideId']!;
          return SharedRideScreen(rideId: rideId);
        },
      ),
      GoRoute(
        path: '/shared/post/:postId',
        name: 'shared-post',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return SharedPostScreen(postId: postId);
        },
      ),
    ],

    // Error page
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});

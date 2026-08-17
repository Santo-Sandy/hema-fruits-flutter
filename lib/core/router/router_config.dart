import 'package:hema_fruits/features/auth/login.dart';
import 'package:hema_fruits/features/layouts/main_layout.dart';
import 'package:hema_fruits/features/screens/profile/menu.dart';
import 'package:hema_fruits/features/screens/profile/profile_screen.dart';
import 'package:hema_fruits/features/screens/profile/settings_screen.dart';
import 'package:hema_fruits/features/screens/splash_screen/splash_screen.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/features/screens/ecommerce/cart/cart_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/cart/checkout_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/home/ecomm_home_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/orders/order_tracking_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/product/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/login',
      builder: (_, state) {
        final extra = state.extra as bool? ?? false;
        return LoginScreen(isPwdLogin: extra);
      },
    ),

    // Sub-screens pushed over shell
    GoRoute(
      path: '/ecommerce/product/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ProductDetailScreen(productId: id);
      },
    ),
    GoRoute(
      path: '/ecommerce/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/ecommerce/order-tracking/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return OrderTrackingScreen(orderId: id);
      },
    ),

    // Primary ShellRoute providing AppHeader & AppFooter navigation
    ShellRoute(
      builder: (ctx, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: RoutePath.home,
          name: RouteName.home,
          builder: (_, _) => const EcommHomeScreen(),
        ),
        GoRoute(
          path: '/ecommerce/cart',
          builder: (_, _) => const CartScreen(),
        ),
        GoRoute(
          path: '/ecommerce/orders/my-orders',
          builder: (_, _) => const OrderTrackingScreen(orderId: 'latest'),
        ),
        GoRoute(
          path: RoutePath.profile,
          name: RouteName.profile,
          builder: (_, _) => const AccountScreen(),
        ),
        GoRoute(
          path: RoutePath.settings,
          name: RouteName.settings,
          builder: (_, _) => const SettingsScreen(),
        ),
        GoRoute(
          path: RoutePath.menu,
          name: RouteName.menu,
          builder: (_, _) => const Menu(),
        ),
      ],
    ),
  ],
);

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/features/auth/company.dart';
import 'package:hema_fruits/features/auth/login.dart';
import 'package:hema_fruits/features/auth/profile.dart';
import 'package:hema_fruits/features/auth/profile_helpers.dart';
import 'package:hema_fruits/features/layouts/main_layout.dart';

import 'package:hema_fruits/features/screens/activity/my_activity_screen.dart';
import 'package:hema_fruits/features/screens/bidding/sales_buy_bidding.dart';
import 'package:hema_fruits/features/screens/creditPoint/credit_payment_screen.dart';
import 'package:hema_fruits/features/screens/creditPoint/creditpoint_screen.dart';
import 'package:hema_fruits/features/screens/dashboard/dashboard_screen.dart';
import 'package:hema_fruits/features/screens/dashboard/queue_list_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/cart/cart_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/cart/checkout_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/home/ecomm_home_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/orders/order_tracking_screen.dart';
import 'package:hema_fruits/features/screens/ecommerce/product/product_detail_screen.dart';
import 'package:hema_fruits/features/screens/home/home_screen.dart';
import 'package:hema_fruits/features/screens/notification/notification_history.dart';
import 'package:hema_fruits/features/screens/profile/blocked_screen.dart';
import 'package:hema_fruits/features/screens/profile/menu.dart';
import 'package:hema_fruits/features/screens/profile/profile_screen.dart';
import 'package:hema_fruits/features/screens/profile/settings_screen.dart';
import 'package:hema_fruits/features/screens/splash_screen/splash_screen.dart';
import 'package:hema_fruits/features/screens/user_profile/user_profile.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: navigatorKey,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, state) {
        final extra = state.extra as bool? ?? false;
        return LoginScreen(isPwdLogin: extra);
      },
    ),
    GoRoute(
      path: RoutePath.personalInfo,
      builder: (_, _) => ProfileScreen(
        config: ProfileScreenConfig.createMode(),
      ),
    ),
    GoRoute(
      path: RoutePath.businessInfo,
      builder: (_, _) => const BusinessInfoForm(mode: BusinessInfoMode.create),
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
          path: '/marketplace',
          builder: (_, state) {
            final tabStr = state.uri.queryParameters['tab'] ?? '0';
            final tab = int.tryParse(tabStr) ?? 0;
            return HomeScreen(initialTab: tab);
          },
        ),
        GoRoute(
          path: RoutePath.dashboard,
          name: RouteName.dashboard,
          builder: (_, _) => const DashboardScreen(),
        ),
        GoRoute(
          path: RoutePath.myActivity,
          name: RouteName.myActivity,
          builder: (_, state) {
            final tabStr = state.uri.queryParameters['tab'] ?? '0';
            final tab = int.tryParse(tabStr) ?? 0;
            return MyActivityScreen(initialTab: tab);
          },
        ),
        GoRoute(
          path: RoutePath.salesBuyBidding,
          name: RouteName.salesBuyBidding,
          builder: (_, _) => const SalesBuyBidding(),
        ),
        GoRoute(
          path: RoutePath.creditpoint,
          name: RouteName.creditpoint,
          builder: (_, _) => const CreditpointScreen(),
        ),
        GoRoute(
          path: RoutePath.creditpayment,
          name: RouteName.creditPayment,
          builder: (_, _) => const CreditRechargePage(),
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
          path: RoutePath.userProfile,
          name: RouteName.userProfile,
          builder: (_, state) {
            final id = state.uri.queryParameters['id'];
            return UserProfilePage(id: id);
          },
        ),
        GoRoute(
          path: RoutePath.notificationshistory,
          name: RouteName.notificationsHistory,
          builder: (_, _) => const NotificationHistoryPage(),
        ),
        GoRoute(
          path: RoutePath.offlineQueue,
          name: RouteName.offlineQueue,
          builder: (_, _) => const QueueListScreen(),
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
        GoRoute(
          path: RoutePath.blocked,
          name: RouteName.blocked,
          builder: (_, _) => const BlockedUsersPage(),
        ),
      ],
    ),
  ],
);

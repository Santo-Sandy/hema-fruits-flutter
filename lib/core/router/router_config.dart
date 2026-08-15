import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/features/auth/company.dart';
import 'package:hema_fruits/features/auth/profile.dart';
import 'package:hema_fruits/features/auth/profile_helpers.dart';
import 'package:hema_fruits/features/screens/activity/post_requiremment/my_post_screen.dart';
import 'package:hema_fruits/features/screens/activity/post_requiremment/newPost/newPost.dart';
import 'package:hema_fruits/features/screens/activity/response/response_screen.dart';
import 'package:hema_fruits/features/screens/bidding/sales_buy_bidding.dart';
import 'package:hema_fruits/features/screens/creditPoint/credit_payment_screen.dart';
import 'package:hema_fruits/features/screens/creditPoint/creditpoint_screen.dart';
import 'package:hema_fruits/features/screens/dashboard/dashboard_screen.dart';
import 'package:hema_fruits/features/screens/dashboard/queue_list_screen.dart';
import 'package:hema_fruits/features/screens/activity/enquiry/enquiry_viewscreen.dart';
import 'package:hema_fruits/features/screens/activity/enquiry/my_enquiry_screen.dart';
import 'package:hema_fruits/features/screens/home/home_screen.dart';
import 'package:hema_fruits/features/auth/login.dart';
import 'package:hema_fruits/features/screens/activity/my_activity_screen.dart';
import 'package:hema_fruits/features/layouts/main_layout.dart';
import 'package:hema_fruits/features/screens/notification/notification_history.dart';
import 'package:hema_fruits/features/screens/profile/blocked_screen.dart';
import 'package:hema_fruits/features/screens/profile/menu.dart';
import 'package:hema_fruits/features/screens/profile/profile_screen.dart';
import 'package:hema_fruits/features/screens/profile/settings_screen.dart';
import 'package:hema_fruits/features/screens/splash_screen/splash_screen.dart';
import 'package:hema_fruits/features/screens/user_profile/user_profile.dart';
import 'package:hema_fruits/features/screens/view_screen/marketplace_view_screen/buyer_response_viiew_screen.dart';
import 'package:hema_fruits/features/screens/view_screen/marketplace_view_screen/seller_response_view_screen.dart';
import 'package:hema_fruits/features/screens/view_screen/my_post_view_screen/mypost_buyerview.dart';
import 'package:hema_fruits/features/screens/view_screen/my_post_view_screen/mypost_sellerview.dart';
import 'package:hema_fruits/features/screens/view_screen/my_post_view_screen/seller_post_view.dart';
import 'package:hema_fruits/features/screens/view_screen/my_post_view_screen/buyer_post_view.dart';
import 'package:hema_fruits/features/screens/view_screen/marketplace_view_screen/sellerviewscreen.dart';
import 'package:hema_fruits/features/screens/view_screen/marketplace_view_screen/viewscreen.dart';
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
    // GoRoute(
    //   path: '/profilesetup',
    //   builder: (context, state) => ProfileSetupScreen(),
    // ),
    GoRoute(
      path: '/profilesetup',
      builder: (context, state) =>
          ProfileScreen(config: ProfileScreenConfig.createMode()),
    ),
    GoRoute(
      path: '/companysetup',
      builder: (context, state) => const BusinessInfoForm(
        mode: BusinessInfoMode.create,
        showReward: true,
        currentStep: 2,
        totalSteps: 2,
      ),
    ),
    GoRoute(
      path: RoutePath.creditpayment,
      name: RouteName.creditPayment,
      builder: (_, _) => const CreditRechargePage(),
    ),

    ShellRoute(
      builder: (ctx, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: RoutePath.home,
          name: RouteName.home,
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};

            // ── FIX: Read the URI query parameters directly from the URL state ──
            final tabParam = state.uri.queryParameters['tab'];
            final computedTab =
                int.tryParse(tabParam ?? '') ??
                (extra['initialTab'] as int? ?? 0);

            return HomeScreen(
              initialTab:
                  computedTab, // <-- Passes the accurate tab index on first load!
              type: extra['type'] as String?,
            );
          },
          // You can keep or delete the sub-routes below, but query parameters are much cleaner
          routes: [
            GoRoute(
              path: RoutePath.homenew,
              name: RouteName.homeNew,
              builder: (context, state) => const HomeScreen(initialTab: 0),
            ),
            GoRoute(
              path: RoutePath.homeview,
              name: RouteName.homeView,
              builder: (context, state) => const HomeScreen(initialTab: 1),
            ),
            GoRoute(
              path: RoutePath.homefav,
              name: RouteName.homeFav,
              builder: (context, state) => const HomeScreen(initialTab: 2),
            ),
          ],
        ),
        GoRoute(
          path: RoutePath.userProfile,
          name: RouteName.userProfile,
          builder: (context, state) {
            final index = state.extra as List<dynamic>;
            final id = index[0] as String?;
            final userData = index[1] as Map<String, dynamic>?;
            return UserProfilePage(id: id, userData: userData);
          },
        ),
        GoRoute(
          path: RoutePath.dashboard,
          name: RouteName.dashboard,
          builder: (_, _) => const DashboardScreen(),
        ),
        GoRoute(
          path: RoutePath.offlineQueue,
          name: RouteName.offlineQueue,
          builder: (_, __) => const QueueListScreen(),
        ),
        GoRoute(
          path: RoutePath.myActivity,
          name: RouteName.myActivity,
          builder: (_, state) {
            final tab =
                int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
            final type = state.uri.queryParameters['type'] ?? "";
            return MyActivityScreen(initialTab: tab, type: type);
          },
          routes: [],
        ),
        GoRoute(
          path: RoutePath.myActivityPost,
          name: RouteName.myActivityPost,
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return MyActivityScreen(
              initialTab: extra['initialTab'] ?? 0,
              type: extra['type'] as String?,
            );
          },
        ),
        GoRoute(
          path: RoutePath.myEnquiry,
          name: RouteName.myEnquiry,
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return MyActivityScreen(
              initialTab: extra['initialTab'] ?? 1,
              type: extra['type'] as String?,
            );
          },
        ),
        GoRoute(
          path: RoutePath.myActivityResponses,
          name: RouteName.myActivityResponses,
          builder: (_, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};

            final type = extra['type'] as String?;
            return RequirementResponsesPage(type: type);
          },
        ),
        // GoRoute(
        //   path: RoutePath.myEnquiry,
        //   name: RouteName.myEnquiry,
        //   builder: (_, state) {
        //     final extra = state.extra as Map<String, dynamic>? ?? {};

        //     final type = extra['type'] as String?;
        //     return MyEnquiryScreen(type: type);
        //   },
        // ),
        GoRoute(
          path: RoutePath.myEnquiryView,
          name: RouteName.myEnquiryView,
          builder: (context, state) {
            final index = state.extra as EnquiryItem;
            return EnquiryViewscreen(item: index);
          },
        ),
        // Profile
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
        GoRoute(
          path: RoutePath.salesBuyBidding,
          name: RouteName.salesBuyBidding,
          builder: (_, _) => const SalesBuyBidding(),
        ),
        GoRoute(
          path: RoutePath.personalInfo,
          name: RouteName.personalInfo,
          builder: (_, _) =>
              ProfileScreen(config: ProfileScreenConfig.editMode()),
        ),
        GoRoute(
          path: RoutePath.businessInfo,
          name: RouteName.businessInfo,
          builder: (_, _) => const BusinessInfoForm(
            mode: BusinessInfoMode.update,
            showReward: false,
          ),
        ),
        GoRoute(
          path: RoutePath.notificationshistory,
          name: RouteName.notificationsHistory,
          builder: (_, _) => const NotificationHistoryPage(),
        ),
        GoRoute(
          path: RoutePath.newPost,
          name: RoutePath.newPost,
          builder: (context, state) {
            final index = state.extra as List<String>;
            final role = index[0];
            final type = index[1];
            final queryType = index[2];
            final collectionName = index[3];
            return NewPostScreen(
              role: role,
              type: type,
              queryType: queryType,
              collectionName: collectionName,
            );
          },
        ),
        GoRoute(
          path: RoutePath.creditpoint,
          name: RouteName.creditpoint,
          builder: (_, _) => const CreditpointScreen(),
        ),
        // Posts
        GoRoute(
          path: RoutePath.posts,
          name: RouteName.postList,
          builder: (_, _) => const MyPostAndResponse(),
        ),

        GoRoute(
          path: RoutePath.postBuyer,
          name: RouteName.postBuyer,
          builder: (context, state) {
            final index = state.extra as String;

            return BuyerPostView(index: index);
          },
        ),
        GoRoute(
          path: RoutePath.postSeller,
          name: RouteName.postSeller,
          builder: (context, state) {
            final index = state.extra as String;
            return SellerPostView(index: index);
          },
        ),

        GoRoute(
          path: RoutePath.postofflineBuyer,
          name: RouteName.postofflineBuyer,
          builder: (context, state) {
            final index = state.extra as List<dynamic>;

            return BuyerPostView(index: index[0], postList: index[1]);
          },
        ),
        GoRoute(
          path: RoutePath.postofflineSeller,
          name: RouteName.postofflineSeller,
          builder: (context, state) {
            final index = state.extra as List<dynamic>;
            return SellerPostView(index: index[0], postList: index[1]);
          },
        ),
        // GoRoute(
        //   path: RoutePath.ResponseSellerpost,
        //   name: RouteName.ResponseSellerpost,
        //   builder: (context, state) {
        //     final index = state.extra as List<String>;
        //     return Sellerview(index: index);
        //   },
        // ),
        // GoRoute(
        //   path: RoutePath.ResponseBuyerpost,
        //   name: RouteName.ResponseBuyerpost,
        //   builder: (context, state) {
        //     final index = state.extra as List<String>;
        //     return BuyerviewScreen(index: index);
        //   },
        // ),
        GoRoute(
          path: RoutePath.myResponseBuyerpost,
          name: RouteName.myResponseBuyerpost,
          builder: (context, state) {
            final index = state.extra as List<String>;
            return MypostBuyerview(index: index);
          },
        ),
        GoRoute(
          path: RoutePath.myResponseSellerpost,
          name: RouteName.myResponseSellerpost,
          builder: (context, state) {
            final index = state.extra as List<String>;
            return MypostSellerview(index: index);
          },
        ),
        GoRoute(
          path: RoutePath.viewscreen,
          name: RouteName.viewScreen,
          builder: (context, state) {
            final index = state.extra as String;
            return ViewScreen(index: index);
          },
        ),
        GoRoute(
          path: RoutePath.sellerviewscreen,
          name: RouteName.sellerViewScreen,
          builder: (context, state) {
            final index = state.extra as String;
            return SellerViewScreen(index: index);
          },
        ),

        GoRoute(
          path: RoutePath.buyerResponseviewscreen,
          name: RouteName.buyerResponseviewScreen,
          builder: (context, state) {
            final index = state.extra as List<String>;
            return BuyerResponseViiewScreen(index: index);
          },
        ),
        GoRoute(
          path: RoutePath.sellerResponseviewscreen,
          name: RouteName.sellerResponseviewScreen,
          builder: (context, state) {
            final index = state.extra as List<String>;
            return SellerResponseViewScreen(index: index);
          },
        ),
      ],
    ),
  ],
);

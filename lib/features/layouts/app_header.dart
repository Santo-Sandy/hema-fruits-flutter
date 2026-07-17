import 'package:cashew_marketplace/core/providers/notification_provider.dart';
import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
import 'package:cashew_marketplace/core/providers/user_provider.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/Responsive/responsivea_context.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/features/screens/creditPoint/firstReward_credit.dart';
import 'package:cashew_marketplace/features/screens/notification/notification_history.dart';
import 'package:cashew_marketplace/features/screens/profile/menu.dart';
import 'package:cashew_marketplace/features/screens/user_profile/user_profile.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/widgets/toast_notification.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/widgets/widgets.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  Map<String, dynamic> userData = {};
  List<dynamic> notificationData = [];
  Map<String, dynamic> user = {};
  String userId = "";
  String header = "Welcome";
  String? _previousRole;
  String currentRole = "buyer";

  @override
  void initState() {
    super.initState();
    getuser();
    fetchnotification();
  }

  Future<void> fetchnotification() async {
    if (!mounted) return;

    try {
      final userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];

      final request = FilterRequest(userId: userId);
      final payload = request.getNotification();

      final provider = context.read<NotificationProvider>();

      await provider.fetch(
        endpoint: "dataset/data/notifications",
        filterPayload: payload,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> getuser() async {
    userData = await SecureStorageService.getUserData();
    final userId = userData['_id'];
    FilterRequest request = FilterRequest(userId: userId);
    context.read<ProfileProvider>().userprofilefetch(
      endpoint: "entities/filter/users",
      filterPayload: request.getuserprofile(),
    );
  }

  String getHeaderFromPath(String path) {
    // Activity
    if (path.startsWith('/activity/post')) {
      return Translate.t("header.my_posts");
    }
    if (path.startsWith('/activity/responses')) {
      return Translate.t("header.responses");
    }
    if (path.startsWith('/activity')) return Translate.t("header.my_activity");

    // Enquiry
    if (path.startsWith('/enquiry/post')) {
      return Translate.t("header.post_enquiries");
    }
    if (path.startsWith('/enquiry/requirement')) {
      return Translate.t("header.requirement_enquiries");
    }
    if (path.startsWith('/enquiry')) return Translate.t("header.enquiries");

    // Posts
    if (path.contains('/posts/') && path.endsWith('/edit')) {
      return Translate.t("header.edit_post");
    }
    if (path.contains('/posts/') && !path.endsWith('/edit')) {
      return Translate.t("header.post_details");
    }
    if (path.startsWith('/newposts')) {
      return Translate.t("header.create_post");
    }

    if (path.startsWith('/posts') ||
        path.startsWith('/sellerposts') ||
        path.startsWith('/mysellerpostview') ||
        path.startsWith('/mybuyerpostview')) {
      return Translate.t("header.posts");
    }
    if (path.startsWith('/viewscreen') ||
        path.startsWith('/sellerviewscreen') ||
        path.startsWith('/buyerresponseviewscreen') ||
        path.startsWith('/sellerresponseviewscreen')) {
      return Translate.t("header.posts");
    }
    // Requirements
    if (path.contains('/requirements/') && path.endsWith('/edit')) {
      return Translate.t("header.edit_requirement");
    }
    if (path.contains('/requirements/') && !path.endsWith('/edit')) {
      return Translate.t("header.requirement_details");
    }
    if (path.startsWith('/requirements/create')) {
      return Translate.t("header.create_requirement");
    }
    if (path.startsWith('/requirements')) {
      return Translate.t("header.requirements");
    }

    if (path.startsWith('/newRequirement')) {
      return Translate.t("header.new_requirement");
    }

    // Profile
    if (path.startsWith('/personal-info')) {
      return Translate.t("header.Settings");
    }
    if (path.startsWith('/business-info')) {
      return Translate.t("header.Settings");
    }
    if (path.startsWith('/subscription')) {
      return Translate.t("header.subscription");
    }
    if (path.startsWith('/notifications')) {
      return Translate.t("header.notifications");
    }
    if (path.startsWith('/userprofile')) {
      return Translate.t("header.userprofile");
    }
    if (path.startsWith('/profile')) return Translate.t("header.profile");
    if (path.startsWith('/salesbuybidding')) {
      return Translate.t("header.salesbidding");
    }
    // Main
    if (path.startsWith('/dashboard')) return Translate.t("header.dashboard");
    if (path.startsWith('/home')) return Translate.t("header.marketplace");
    if (path.startsWith('/settings') || path.startsWith("/menu")) {
      return Translate.t("header.Settings");
    }
    if (path.startsWith('/blocked')) return Translate.t("header.Settings");
    if (path.startsWith('/creditpoint')) {
      return Translate.t("header.CreditPoints");
    }

    return Translate.t("header.marketplace");
  }

  void _openNotificationDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 767) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              child: SizedBox(
                width: screenWidth < 1200
                    ? screenWidth * 0.75
                    : screenWidth * 0.50,
                height: MediaQuery.of(context).size.height,
                child: NotificationHistoryPage(),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      );
    } else {
      final currentLocation = GoRouterState.of(context).uri.toString();
      if (currentLocation == RoutePath.notificationshistory) {
        context.pop();
      } else {
        context.push(RoutePath.notificationshistory);
      }
    }
  }

  void _openProfileDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    // if (screenWidth > 767) {
    //   showGeneralDialog(
    //     context: context,
    //     barrierDismissible: true,
    //     barrierLabel: MaterialLocalizations.of(
    //       context,
    //     ).modalBarrierDismissLabel,
    //     barrierColor: Colors.black54,
    //     transitionDuration: const Duration(milliseconds: 300),
    //     pageBuilder: (context, animation, secondaryAnimation) {
    //       return Align(
    //         alignment: Alignment.centerRight,
    //         child: Material(
    //           child: SizedBox(
    //             width: screenWidth < 1200
    //                 ? screenWidth * 0.75
    //                 : screenWidth * 0.50,
    //             height: MediaQuery.of(context).size.height,
    //             child: AccountScreen(),
    //           ),
    //         ),
    //       );
    //     },
    //     transitionBuilder: (context, animation, secondaryAnimation, child) {
    //       return SlideTransition(
    //         position: Tween<Offset>(
    //           begin: const Offset(1, 0),
    //           end: Offset.zero,
    //         ).animate(animation),
    //         child: child,
    //       );
    //     },
    //   );
    // } else {
    final currentLocation = GoRouterState.of(context).uri.toString();
    if (currentLocation == RoutePath.profile) {
      context.pop();
    } else {
      context.pushNamed(RouteName.profile);
    }
    // }
  }

  void _openMenuDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 767) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              child: SizedBox(
                width: screenWidth < 1200
                    ? screenWidth * 0.75
                    : screenWidth * 0.50,
                height: MediaQuery.of(context).size.height,
                child: Menu(),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      );
    } else {
      final currentLocation = GoRouterState.of(context).uri.toString();
      if (currentLocation == RoutePath.menu) {
        context.pop();
      } else {
        context.pushNamed(RouteName.menu);
      }
    }
  }

  void showAnimatedToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    Color? color,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;
    final resolvedColor = color ?? AppColors.primary;
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedToastWidget(
          message: message,
          icon: icon,
          color: resolvedColor,
          onDismiss: () => overlayEntry.remove(),
        );
      },
    );

    overlay.insert(overlayEntry);
  }

  Future<void> onSwap() async {
    final role = currentRole;
    final currentcontext = ContextManager().currentContext;
    // navigatorKey.currentContext;
    if (role == 'processor') {
      showAnimatedToast(
        currentcontext!,
        message: Translate.t("common.buyer"),
        icon: Icons.shopping_cart_rounded,
        color: Colors.black,
      );
    } else {
      showAnimatedToast(
        currentcontext!,
        message: Translate.t("common.seller"),
        icon: Icons.store_rounded,
        color: Colors.white,
      );
    }
  }

  void _navigateToReward(int points) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FirstLoginRewardScreen(
          rewardPoints: points,
          onAutoDismiss: () {
            Navigator.pop(context);
            context.go(RoutePath.home);
          },
          onSubscribe: () {
            Navigator.pop(context);
            context.go(RoutePath.home);
            context.push(RoutePath.creditpayment);
          },
          onSkip: () {
            Navigator.pop(context);
            context.go(RoutePath.home);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Header rebuilt');
    return Consumer2<ProfileProvider, NotificationProvider>(
      builder: (context, provider, notificationprovider, child) {
        userData = provider.userprofile;
        notificationData = notificationprovider.notifications;
        return AppBar(
          backgroundColor: AppColors.appheader,
          elevation: 0,
          leading: GestureDetector(
            onTap: _openProfileDrawer,
            child: Padding(
              padding: const EdgeInsets.only(right: 8, left: 8),
              child: Container(
                padding: const EdgeInsets.all(
                  2,
                ), // Space between avatar and border
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white, // Border color
                    width: 2,
                  ),
                ),
                child: AppAvatar(
                  imageUrl: userData["profilePicture"],
                  name: userData['name'] ?? 'S',
                  radius: 18,
                  backgroundColor: AppColors.primary, // 20% opacity
                ),
              ),
            ),
          ),
          title: Column(
            children: [
              GestureDetector(
                // onTap: () =>
                //     Navigator.push(
                //       context,
                //       PageRouteBuilder(
                //         pageBuilder: (context, animation, secondaryAnimation) =>
                //             PaymentSuccessSplashScreen(
                //               amount: 1000,
                //               points: 500,
                //               currency: "\$",
                //             ),
                //         transitionsBuilder:
                //             (context, animation, secondaryAnimation, child) {
                //               return FadeTransition(
                //                 opacity: animation,
                //                 child: child,
                //               );
                //             },
                //         transitionDuration: const Duration(milliseconds: 300),
                //       ),
                //     ).then((_) {
                //       if (mounted) {
                //         context.pop();
                //       }
                //     }),
                // onTap: () {
                //   Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => FirstLoginRewardScreen(
                //         rewardPoints: userData['points'],
                //         onAutoDismiss: () {
                //           Navigator.pop(context);
                //           context.go(RoutePath.home);
                //         },
                //         onSubscribe: () {
                //           Navigator.pop(context);
                //           context.go(RoutePath.home);
                //           context.push(RoutePath.creditpayment);
                //         },
                //         onSkip: () {
                //           Navigator.pop(context);
                //           context.go(RoutePath.home);
                //         },
                //       ),
                //     ),
                //   );
                // },
                child: Text(
                  getHeaderFromPath(GoRouterState.of(context).uri.toString()),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: context.fontSizeMedium,
                    color: AppColors.appheadertext,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.appheadertext,
                  ),
                  onPressed: _openNotificationDrawer,
                ),
                if (notificationData.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 20,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.error, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          notificationData.length > 9
                              ? '9+'
                              : '${notificationData.length}',
                          style: TextStyle(
                            fontSize: context.fontSizeXSmall,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Consumer2<SwapUserProvider, ProfileProvider>(
              builder: (context, swapProvider, profile, _) {
                if (!swapProvider.showSwap) {
                  return const SizedBox.shrink();
                }
                if (!swapProvider.showSwap) {
                  return const SizedBox();
                }
                currentRole = swapProvider.swapedUser;

                /// Update previous role safely
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _previousRole != currentRole) {
                    setState(() {
                      _previousRole = currentRole;
                    });
                  }
                });

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: ProfileIconTabSwitcher(
                    backgroundColor: AppColors.textHint,
                    selectedIndex: currentRole == 'buyer' ? 0 : 1,
                    onChanged: (index) async {
                      try {
                        currentRole = index == 1 ? 'buyer' : 'processor';
                        final initialPage =
                            profile.userprofile['initializer_screen'] ??
                            "Marketplace";
                        if (initialPage == "Dashboard") {
                          context.go(RoutePath.dashboard);
                        } else if (initialPage == "BiddingScreen") {
                          context.go(RoutePath.home);
                          context.push(RoutePath.salesBuyBidding);
                        } else {
                          context.go(RoutePath.home);
                        }
                        // swapProvider.toggleUser();
                        await onSwap();
                      } catch (e) {
                        debugPrint("Swap failed: $e");
                      }
                    },
                    icons: const [Icons.shopping_cart_outlined, Icons.store],
                    labels: const ['Buyer', 'Merchant'],
                  ),
                  // ProfileTabSwitcher(
                  //   backgroundColor:
                  //       AppColors.textHint,
                  //   tabs: const ['Buyer', 'Merchant'],
                  //   selectedIndex:
                  //       currentRole == 'buyer'
                  //       ? 0
                  //       : 1,
                  //   onTabChanged: (index) async {
                  //     try {
                  //       currentRole = index == 1
                  //           ? 'buyer'
                  //           : 'processor';
                  //       swapProvider.toggleUser();
                  //       await onSwap();
                  //     } catch (e) {
                  //       debugPrint("Swap failed: $e");
                  //     }
                  //   },
                  // ),
                );
              },
            ),

            // context.isMobile
            //     ? GestureDetector(
            //         onTap: () {
            //           final currentLocation = GoRouterState.of(
            //             context,
            //           ).uri.toString();
            //           if (currentLocation == RoutePath.salesBuyBidding) {
            //             context.pop();
            //           } else {
            //             context.pushNamed(RouteName.salesBuyBidding);
            //           }
            //         },
            //         child: Padding(
            //           padding: const EdgeInsets.only(right: 14, left: 4),
            //           child: Icon(
            //             Icons.crisis_alert_rounded,
            //             color: AppColors.accent,
            //           ),
            //         ),
            //       )
            //     :
            // context.isMobile
            //     ? SizedBox()
            //     : GestureDetector(
            //         onTap: _openProfileDrawer,
            //         child: Padding(
            //           padding: const EdgeInsets.only(right: 8, left: 8),
            //           child: AppAvatar(
            //             imageUrl: userData["profilePicture"],
            //             name: userData['name'] ?? 'S',
            //             radius: 18,
            //             backgroundColor: Colors.white.withAlpha(
            //               51,
            //             ), // 20% opacity
            //           ),
            //         ),
            //       ),
            IconButton(
              onPressed: _openMenuDrawer,
              icon: Icon(Icons.menu, color: AppColors.appheadertext),
            ),
            // Avatar
            // GestureDetector(
            //   onTap: _openProfileDrawer,
            //   child: Padding(
            //     padding: const EdgeInsets.only(right: 14, left: 4),
            //     child: AppAvatar(
            //       imageUrl: userData["profilePicture"],
            //       name: userData['name'] ?? 'S',
            //       radius: 18,
            //       backgroundColor: Colors.white.withAlpha(51), // 20% opacity
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }
}

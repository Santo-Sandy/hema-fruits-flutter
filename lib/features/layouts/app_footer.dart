import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/toast_notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppFooter extends StatefulWidget {
  final int currentIndex;
  final void Function(int index, {int? homeTabIndex, int? activityTabIndex})
  onTap;

  const AppFooter({super.key, required this.currentIndex, required this.onTap});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  String? _previousRole;

  List<_NavItem> get _items => [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: "Home",
    ),
    _NavItem(
      icon: Icons.shopping_basket_outlined,
      activeIcon: Icons.shopping_basket,
      label: "Basket",
    ),
    _NavItem(
      icon: Icons.local_shipping_outlined,
      activeIcon: Icons.local_shipping,
      label: "Orders",
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: "Account",
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.footerBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected =
                  widget.currentIndex >= 0 && i == widget.currentIndex;

              Widget navItemContent = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.activebottom.withAlpha(80)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      selected ? item.activeIcon : item.icon,
                      color: selected
                          ? AppColors.activebottom
                          : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? AppColors.activebottom
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              );

              // ── HOME BUTTON DROPDOWN CONFIGURATION ──
              // if (i == 0) {
              //   return Expanded(
              //     child: PopupMenuButton<int>(
              //       offset: const Offset(
              //         0,
              //         -150,
              //       ), // Spawns menu above footer bar
              //       color: AppColors.surfaceLight,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       onSelected: (subTabIndex) {
              //         // Fires routing context payload update to MainLayout -> HomeScreen
              //         widget.onTap(0, homeTabIndex: subTabIndex);
              //       },
              //       itemBuilder: (BuildContext context) => [
              //         PopupMenuItem<int>(
              //           value: 0, // Targets Tab 0 (New)
              //           child: Row(
              //             children: [
              //               const Icon(Icons.fiber_new_rounded, size: 18),
              //               const SizedBox(width: 8),
              //               // Safe fallback string displays if translation dictionary fails
              //               Text(Translate.t("homeScreen.new") ?? "New View"),
              //             ],
              //           ),
              //         ),
              //         PopupMenuItem<int>(
              //           value: 1, // Targets Tab 1 (Viewed)
              //           child: Row(
              //             children: [
              //               const Icon(Icons.visibility_outlined, size: 18),
              //               const SizedBox(width: 8),
              //               Text(Translate.t("homeScreen.viewed") ?? "Viewed"),
              //             ],
              //           ),
              //         ),
              //         PopupMenuItem<int>(
              //           value: 2, // Targets Tab 2 (Favorite)
              //           child: Row(
              //             children: [
              //               const Icon(Icons.favorite_border_rounded, size: 18),
              //               const SizedBox(width: 8),
              //               Text(
              //                 Translate.t("homeScreen.favorite") ?? "Favorite",
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //       child: navItemContent,
              //     ),
              //   );
              // }

              // if (i == 2) {
              //   return Expanded(
              //     child: PopupMenuButton<int>(
              //       offset: const Offset(0, -112),
              //       color: AppColors.surfaceLight,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       onSelected: (subTabIndex) {
              //         widget.onTap(2, activityTabIndex: subTabIndex);
              //       },
              //       itemBuilder: (BuildContext context) => [
              //         PopupMenuItem<int>(
              //           value: 0,
              //           child: Row(
              //             children: [
              //               const Icon(Icons.campaign_outlined, size: 18),
              //               const SizedBox(width: 8),
              //               Text(Translate.t("tabs.my_post")),
              //             ],
              //           ),
              //         ),
              //         PopupMenuItem<int>(
              //           value: 1,
              //           child: Row(
              //             children: [
              //               const Icon(Icons.chat_bubble_outline, size: 18),
              //               const SizedBox(width: 8),
              //               Text(Translate.t("tabs.enquiries")),
              //             ],
              //           ),
              //         ),
              //       ],
              //       child: navItemContent,
              //     ),
              //   );
              // }

              return Expanded(
                child: InkWell(
                  onTap: () => widget.onTap(i),
                  child: navItemContent,
                ),
              );
            }),

            // Consumer2<SwapUserProvider, ProfileProvider>(
            //   builder: (context, swapProvider, profile, _) {
            //     if (!swapProvider.showSwap) return const SizedBox();
            //     final currentRole = swapProvider.swapedUser;
            //     final goingToBuyer = currentRole == 'buyer';
            //     // Update previous role after reading direction
            //     WidgetsBinding.instance.addPostFrameCallback((_) {
            //       if (mounted && _previousRole != currentRole) {
            //         setState(() => _previousRole = currentRole);
            //       }
            //     });

            //     return Positioned(
            //       top: -20,
            //       left: MediaQuery.of(context).size.width / 2 - 28,
            //       child: GestureDetector(
            //         onTap: () {
            //           try {
            //             final initialPage =
            //                 profile.userprofile['initializer_screen'] ??
            //                 "Marketplace";
            //             if (initialPage == "Dashboard") {
            //               context.go(RoutePath.dashboard);
            //             } else if (initialPage == "BiddingScreen") {
            //               context.go(RoutePath.home);
            //               context.push(RoutePath.salesBuyBidding);
            //             } else {
            //               context.go(RoutePath.home);
            //             }
            //             swapProvider.toggleUser();
            //             final role = currentRole;
            //             final currentcontext =
            //                 ContextManager().currentContext;
            //             // navigatorKey.currentContext;
            //             if (role == 'processor') {
            //               showAnimatedToast(
            //                 currentcontext!,
            //                 message: Translate.t("common.buyer"),
            //                 icon: Icons.shopping_cart_rounded,
            //                 color: Colors.black,
            //               );
            //             } else {
            //               showAnimatedToast(
            //                 currentcontext!,
            //                 message: Translate.t("common.seller"),
            //                 icon: Icons.store_rounded,
            //                 color: Colors.white,
            //               );
            //             }
            //           } catch (e) {
            //             print(e);
            //           }
            //         },
            //         child: AnimatedSwitcher(
            //           duration: const Duration(milliseconds: 500),
            //           switchInCurve: Curves.easeInOutCubicEmphasized,
            //           switchOutCurve: Curves.easeInOutCubicEmphasized,
            //           transitionBuilder: (child, animation) {
            //             final isIncoming = child.key == ValueKey(currentRole);

            //             final rotate =
            //                 Tween<double>(
            //                   begin: isIncoming
            //                       ? (goingToBuyer ? -pi / 2 : pi / 2)
            //                       : 0.0,
            //                   end: isIncoming
            //                       ? 0.0
            //                       : (goingToBuyer ? pi / 2 : -pi / 2),
            //                 ).animate(
            //                   CurvedAnimation(
            //                     parent: animation,
            //                     curve: Curves.easeInOutSine,
            //                   ),
            //                 );

            //             return AnimatedBuilder(
            //               animation: rotate,
            //               child: child,
            //               builder: (context, child) {
            //                 // Back-face culling: hide when rotated past 90°
            //                 final isVisible = rotate.value.abs() < pi / 2;
            //                 return Transform(
            //                   transform: Matrix4.identity()
            //                     ..setEntry(3, 2, 0.0025)
            //                     ..rotateY(rotate.value),
            //                   alignment: Alignment.center,
            //                   child: isVisible
            //                       ? child
            //                       : const SizedBox(width: 50, height: 50),
            //                 );
            //               },
            //             );
            //           },
            //           child: Container(
            //             key: ValueKey(currentRole),
            //             height: 50,
            //             width: 50,
            //             decoration: BoxDecoration(
            //               shape: BoxShape.circle,
            //               color: goingToBuyer ? Colors.black : Colors.white,
            //               boxShadow: [
            //                 BoxShadow(
            //                   color: Colors.black.withValues(alpha: 0.2),
            //                   blurRadius: 8,
            //                 ),
            //               ],
            //             ),
            //             child: Center(
            //               child: Icon(
            //                 goingToBuyer
            //                     ? Icons.shopping_cart_outlined
            //                     : Icons.storefront_outlined,
            //                 color: AppColors.primary,
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     );
            //   },
            // ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

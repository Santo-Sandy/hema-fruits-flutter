import 'package:hema_fruits/core/providers/swap_user_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/features/layouts/profile_percent.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TabletSidebar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Function(bool isOpen)? onDrawerToggle;

  const TabletSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onDrawerToggle,
  });

  @override
  State<TabletSidebar> createState() => _TabletSidebarState();
}

class _TabletSidebarState extends State<TabletSidebar> {
  final items = [
    _NavItem(Icons.home_outlined, Icons.home, Translate.t("navBar.home")),
    _NavItem(
      Icons.dashboard_outlined,
      Icons.dashboard,
      Translate.t("navBar.Dashboard"),
    ),
    _NavItem(
      Icons.timeline_outlined,
      Icons.timeline,
      Translate.t("navBar.MyActivity"),
    ),
    // _NavItem(
    //   Icons.chat_bubble_outline,
    //   Icons.chat_bubble,
    //   Translate.t("navBar.MyEnquiry"),
    // ),
    _NavItem(
      Icons.crisis_alert_rounded,
      Icons.crisis_alert_outlined,
      Translate.t("navBar.Bidding"),
    ),
  ];
  double percent = 0.0;
  void getProfilePercentage(Map<String, dynamic> userData) {
    // These are the best signals available in current app storage.
    final dynamic country = userData['natureOfBusiness'] ?? userData['country'] ?? userData['countryName'];
    final bool hasCountry =
        country != null && country.toString().trim().isNotEmpty;

    final bool isProfileComplete =
        (userData['natureOfBusiness'] == '' || userData['natureOfBusiness'] == null) == false;
    final bool isCompanyComplete =
        (userData['companyName'] == '' || userData['companyName'] == null) ==
        false;

    // Start from initial.
    percent = 25;

    // Address + country contributes toward second step only for non-agent.
    // If agent, request says completion becomes 100%.

    // Second step (address + country) -> reach 50%
    if (hasCountry) {
      percent = 50;
    }

    // Business profile completes -> 100%
    // For non-agent: when profile/company complete.
    if (isProfileComplete && isCompanyComplete) {
      percent = 100;
    }

    percent = percent.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: MediaQuery.sizeOf(context).width < 900
          ? MediaQuery.sizeOf(context).width * 0.35
          : MediaQuery.sizeOf(context).width * 0.25,
      color: AppColors.footerBg,
      child: Column(
        children: [
          /// 🔹 TOP: MENU + TOGGLE
          // Row(
          //   children: [
          //     IconButton(
          //       icon: const Icon(Icons.menu),
          //       onPressed: widget.onDrawerToggle != null
          //           ? () => widget.onDrawerToggle!(true)
          //           : null,
          //     ),
          //   ],
          // ),
          Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              final userData = provider.userprofile;
              getProfilePercentage(userData);
              return Column(
                children: [
                  // Header
                  userData.isNotEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                          // decoration: const BoxDecoration(
                          //   gradient: LinearGradient(
                          //     colors: [
                          //       AppColors.primaryDark,
                          //       AppColors.primary,
                          //       AppColors.primaryLight,
                          //     ],
                          //     begin: Alignment.topLeft,
                          //     end: Alignment.bottomRight,
                          //     stops: [0.0, 0.5, 1.0],
                          //   ),
                          // ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ProfilePercent(
                                percent: percent,
                                userData: userData,
                              ),

                              const SizedBox(width: 14),

                              // ── Name ──
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['name'],
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .titleLarge!
                                        .copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : SizedBox(height: 0),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          /// 🔹 MENU ITEMS
          ...List.generate(items.length, (i) {
            final item = items[i];
            final selected =
                widget.currentIndex >= 0 && i == widget.currentIndex;

            return InkWell(
              onTap: () => widget.onTap(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.black.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      color: selected ? Colors.black : AppColors.textHint,
                    ),

                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: AppTextThemes.getLightTextTheme.labelLarge!
                            .copyWith(
                              fontSize: MediaQuery.sizeOf(context).width * 0.02,
                              color: selected
                                  ? Colors.black
                                  : AppColors.textHint,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // const Spacer(),

          // /// 🔹 BOTTOM TOGGLE (same as top)
          // Padding(
          //   padding: const EdgeInsets.all(12),
          //   child: _buildBuyerSellerToggle(),
          // ),
        ],
      ),
    );
  }

  /// 🔥 BUYER / SELLER TOGGLE (WORKING)
  Widget _buildBuyerSellerToggle() {
    return Consumer<SwapUserProvider>(
      builder: (context, swapProvider, _) {
        final isBuyer = swapProvider.swapedUser == 'buyer';

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withAlpha(20)),
          ),
          child: Row(
            children: [
              /// BUYER
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!isBuyer) {
                      // swapProvider.toggleUser();
                      context.go(RoutePath.home);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isBuyer ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        "Buyer",
                        style: TextStyle(
                          color: isBuyer ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              /// SELLER
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (isBuyer) {
                      // swapProvider.toggleUser();
                      context.go(RoutePath.home);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !isBuyer ? Colors.black : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        "Seller",
                        style: TextStyle(
                          color: !isBuyer ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}

import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/features/layouts/profile_percent.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
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
  List<_NavItem> _getItemsForRole(String role) {
    if (role == 'admin') {
      return const [
        _NavItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, "Admin Controls"),
        _NavItem(Icons.swap_calls_outlined, Icons.swap_calls, "Offline Queue"),
        _NavItem(Icons.gavel_outlined, Icons.gavel, "Bidding"),
        _NavItem(Icons.person_outline, Icons.person, "Account"),
      ];
    } else if (role == 'processor' || role == 'seller') {
      return const [
        _NavItem(Icons.inventory_2_outlined, Icons.inventory_2, "My Stocks"),
        _NavItem(Icons.add_circle_outline, Icons.add_circle, "Add Produce Stock"),
        _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, "Sales Dashboard"),
        _NavItem(Icons.person_outline, Icons.person, "Seller Account"),
      ];
    } else {
      return const [
        _NavItem(Icons.home_outlined, Icons.home, "Home"),
        _NavItem(Icons.shopping_basket_outlined, Icons.shopping_basket, "My Basket"),
        _NavItem(Icons.local_shipping_outlined, Icons.local_shipping, "My Orders"),
        _NavItem(Icons.person_outline, Icons.person, "My Account"),
      ];
    }
  }

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
              final role = userData['role']?.toString() ?? 'buyer';
              final items = _getItemsForRole(role);

              return Column(
                children: [
                  // Header
                  userData.isNotEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ProfilePercent(
                                percent: percent,
                                userData: userData,
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['name'] ?? 'User',
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
                      : const SizedBox(height: 0),
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}

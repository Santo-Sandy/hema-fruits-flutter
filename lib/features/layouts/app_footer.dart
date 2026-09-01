import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
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

  List<_NavItem> _itemsForRole(String role) {
    if (role == 'admin') {
      return const [
        _NavItem(
          icon: Icons.admin_panel_settings_outlined,
          activeIcon: Icons.admin_panel_settings,
          label: "Controls",
        ),
        _NavItem(
          icon: Icons.swap_calls_outlined,
          activeIcon: Icons.swap_calls,
          label: "Queue",
        ),
        _NavItem(
          icon: Icons.gavel_outlined,
          activeIcon: Icons.gavel,
          label: "Bidding",
        ),
        _NavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: "Account",
        ),
      ];
    } else if (role == 'processor' || role == 'seller') {
      return const [
        _NavItem(
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          label: "My Stocks",
        ),
        _NavItem(
          icon: Icons.add_circle_outline,
          activeIcon: Icons.add_circle,
          label: "Add Stock",
        ),
        _NavItem(
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart,
          label: "Sales",
        ),
        _NavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: "Account",
        ),
      ];
    } else {
      return const [
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

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final profile = context.watch<ProfileProvider>().userprofile;
    final role = profile['role']?.toString() ?? 'buyer';
    final items = _itemsForRole(role);

    final Color primaryAccent = role == 'admin'
        ? const Color(0xFF4A148C)
        : (role == 'processor' || role == 'seller')
            ? const Color(0xFF0F9D58)
            : const Color(0xFFE65100);

    final String roleBadge = role == 'admin'
        ? 'ADMIN CONTROL'
        : (role == 'processor' || role == 'seller')
            ? 'SELLER PORTAL'
            : 'BUYER SHOP';

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: primaryAccent.withValues(alpha: 0.18),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: primaryAccent.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Role Badge Pill Header
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                roleBadge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: primaryAccent,
                ),
              ),
            ),

            SizedBox(
              height: 56,
              child: Row(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected =
                      widget.currentIndex >= 0 && i == widget.currentIndex;

                  return Expanded(
                    child: InkWell(
                      onTap: () => widget.onTap(i),
                      borderRadius: BorderRadius.circular(24),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: EdgeInsets.symmetric(
                            horizontal: selected ? 14 : 10,
                            vertical: selected ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? primaryAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: primaryAccent.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selected ? item.activeIcon : item.icon,
                                color: selected ? Colors.white : Colors.grey[600],
                                size: selected ? 20 : 22,
                              ),
                              if (selected) ...[
                                const SizedBox(width: 6),
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
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

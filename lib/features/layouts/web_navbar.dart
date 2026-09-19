import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/core/providers/notification_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/auth_service/auth_service.dart';
import 'package:hema_fruits/features/screens/notification/notification_history.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class WebNavBar extends StatefulWidget implements PreferredSizeWidget {
  const WebNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  State<WebNavBar> createState() => _WebNavBarState();
}

class _WebNavBarState extends State<WebNavBar> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openNotificationDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            child: SizedBox(
              width: screenWidth < 1200 ? screenWidth * 0.5 : 440,
              height: MediaQuery.of(context).size.height,
              child: const NotificationHistoryPage(),
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
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final authService = context.read<AuthService>();
    final router = GoRouter.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: isLoading ? null : const Text('Confirm Sign Out'),
              content: isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF0F9D58)),
                          SizedBox(width: 16),
                          Text('Signing out...'),
                        ],
                      ),
                    )
                  : const Text('Are you sure you want to sign out from Hema Fruits Marketplace?'),
              actions: isLoading
                  ? null
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          setState(() => isLoading = true);
                          try {
                            await authService.signOut();
                          } catch (e) {
                            debugPrint("Sign out error: $e");
                          } finally {
                            await SecureStorageService.clearAll();
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            router.go('/login');
                          }
                        },
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().userprofile;
    final role = (profile['role']?.toString() ?? 'buyer').toLowerCase();
    final name = profile['name']?.toString() ?? 'User';
    final currentPath = GoRouterState.of(context).uri.toString();
    final cartItemCount = context.watch<EcommCartProvider>().itemCount;
    final notifications = context.watch<NotificationProvider>().notifications;

    final isSeller = role == 'seller' || role == 'processor';
    final isAdmin = role == 'admin';

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          // 1. Logo & App Title
          InkWell(
            onTap: () => context.go(RoutePath.home),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F9D58).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.eco_rounded, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HEMA FRUITS',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'B2B Fresh Agro Network',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 32),

          // 2. Navigation Pills
          Expanded(
            child: Row(
              children: [
                _buildNavLink(
                  context,
                  title: 'Marketplace',
                  icon: Icons.storefront_rounded,
                  path: RoutePath.home,
                  isActive: currentPath == RoutePath.home || currentPath.startsWith('/home'),
                ),
                if (isSeller || isAdmin) ...[
                  const SizedBox(width: 6),
                  _buildNavLink(
                    context,
                    title: 'My Inventory',
                    icon: Icons.inventory_2_outlined,
                    path: '/seller/stocks',
                    isActive: currentPath.startsWith('/seller/stocks'),
                  ),
                  const SizedBox(width: 6),
                  _buildNavLink(
                    context,
                    title: '+ Post Produce',
                    icon: Icons.add_circle_outline,
                    path: '/seller/add-stock',
                    isActive: currentPath.startsWith('/seller/add-stock'),
                    highlight: true,
                  ),
                  const SizedBox(width: 6),
                  _buildNavLink(
                    context,
                    title: 'Seller Dashboard',
                    icon: Icons.analytics_outlined,
                    path: '/seller/sales-dashboard',
                    isActive: currentPath.startsWith('/seller/sales-dashboard'),
                  ),
                ],
                if (isAdmin) ...[
                  const SizedBox(width: 6),
                  _buildNavLink(
                    context,
                    title: 'Admin Controls',
                    icon: Icons.admin_panel_settings_outlined,
                    path: '/admin/control',
                    isActive: currentPath.startsWith('/admin/control'),
                  ),
                ],
                if (!isSeller && !isAdmin) ...[
                  const SizedBox(width: 6),
                  _buildNavLink(
                    context,
                    title: 'My Orders',
                    icon: Icons.receipt_long_outlined,
                    path: '/ecommerce/orders/my-orders',
                    isActive: currentPath.startsWith('/ecommerce/orders'),
                  ),
                ],
              ],
            ),
          ),

          // 3. Right Action Bar
          Row(
            children: [
              // Cart Button (with live counter)
              InkWell(
                onTap: () => context.push('/ecommerce/cart'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1E293B), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Cart',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (cartItemCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F9D58),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$cartItemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Notification bell
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569), size: 24),
                    onPressed: _openNotificationDrawer,
                    tooltip: 'Notifications',
                  ),
                  if (notifications.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notifications.length > 9 ? '9+' : '${notifications.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // User Profile Dropdown Menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      context.push(RoutePath.profile);
                      break;
                    case 'points':
                      context.push(RoutePath.creditpoint);
                      break;
                    case 'seller_hub':
                      context.go('/seller/stocks');
                      break;
                    case 'admin':
                      context.go('/admin/control');
                      break;
                    case 'signout':
                      _showSignOutDialog(context);
                      break;
                  }
                },
                position: PopupMenuPosition.under,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white,
                elevation: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isSeller
                            ? Colors.orange.shade100
                            : (isAdmin ? Colors.purple.shade100 : const Color(0xFFE8F5E9)),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: isSeller
                                ? Colors.orange.shade800
                                : (isAdmin ? Colors.purple.shade800 : const Color(0xFF0F9D58)),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAdmin
                                      ? Colors.purple
                                      : (isSeller ? Colors.orange : const Color(0xFF0F9D58)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isAdmin
                                      ? Colors.purple.shade700
                                      : (isSeller ? Colors.orange.shade700 : const Color(0xFF0F9D58)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: _buildMenuItem(Icons.person_outline, 'Profile & Account', Colors.blueGrey),
                  ),
                  PopupMenuItem(
                    value: 'points',
                    child: _buildMenuItem(Icons.account_balance_wallet_outlined, 'Quota & Credits', Colors.green),
                  ),
                  if (isAdmin)
                    PopupMenuItem(
                      value: 'admin',
                      child: _buildMenuItem(Icons.admin_panel_settings_outlined, 'Admin Console', Colors.purple),
                    ),
                  if (isSeller)
                    PopupMenuItem(
                      value: 'seller_hub',
                      child: _buildMenuItem(Icons.storefront_rounded, 'Seller Inventory', Colors.orange),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'signout',
                    child: _buildMenuItem(Icons.logout_rounded, 'Sign Out', Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String path,
    required bool isActive,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF0F9D58)
              : (isActive ? const Color(0xFFE8F5E9) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: highlight
              ? null
              : (isActive ? Border.all(color: const Color(0xFF0F9D58).withOpacity(0.3)) : null),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: highlight
                  ? Colors.white
                  : (isActive ? const Color(0xFF0F9D58) : const Color(0xFF475569)),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive || highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? Colors.white
                    : (isActive ? const Color(0xFF0F9D58) : const Color(0xFF334155)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

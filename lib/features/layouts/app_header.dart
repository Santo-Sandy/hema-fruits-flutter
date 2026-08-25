import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/providers/notification_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/auth_service/auth_service.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/Responsive/responsivea_context.dart';
import 'package:hema_fruits/features/screens/notification/notification_history.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchNotificationData();
  }

  Future<void> _fetchNotificationData() async {
    if (!mounted) return;
    try {
      final userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];
      if (userId != null && userId.toString().isNotEmpty) {
        final request = FilterRequest(userId: userId.toString());
        final payload = request.getNotification();
        final provider = context.read<NotificationProvider>();
        await provider.fetch(
          endpoint: "dataset/data/notifications",
          filterPayload: payload,
        );
      }
    } catch (e) {
      debugPrint("Notification fetch error: $e");
    }
  }

  Future<void> _fetchUserData() async {
    try {
      userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];
      if (userId != null && userId.toString().isNotEmpty) {
        final request = FilterRequest(userId: userId.toString());
        context.read<ProfileProvider>().userprofilefetch(
          endpoint: "entities/filter/users",
          filterPayload: request.getuserprofile(),
        );
      }
    } catch (e) {
      debugPrint("User data fetch error: $e");
    }
  }

  String getHeaderFromPath(String path) {
    if (path.startsWith('/activity')) return Translate.t("header.my_activity");
    if (path.startsWith('/dashboard')) return Translate.t("header.dashboard");
    if (path.startsWith('/marketplace')) return Translate.t("header.posts");
    if (path.startsWith('/salesbuybidding')) return Translate.t("header.salesbidding");
    if (path.startsWith('/creditpoint')) return Translate.t("header.CreditPoints");
    if (path.startsWith('/profile')) return Translate.t("header.profile");
    if (path.startsWith('/settings')) return Translate.t("header.Settings");
    if (path.startsWith('/menu')) return Translate.t("header.Settings");
    return "Fresh Produce Marketplace";
  }

  void _openNotificationDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 767) {
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
                width: screenWidth < 1200 ? screenWidth * 0.75 : screenWidth * 0.50,
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
    } else {
      final currentLocation = GoRouterState.of(context).uri.toString();
      if (currentLocation == RoutePath.notificationshistory) {
        context.pop();
      } else {
        context.push(RoutePath.notificationshistory);
      }
    }
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        context.push(RoutePath.profile);
        break;
      case 'points':
        context.push(RoutePath.creditpoint);
        break;
      case 'settings':
        context.push(RoutePath.settings);
        break;
      case 'signout':
        _showSignOutDialog(context);
        break;
    }
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

  PopupMenuItem<String> _buildPopupMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDestructive ? AppColors.error : color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
              color: isDestructive ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.toString();

    return Consumer2<ProfileProvider, NotificationProvider>(
      builder: (context, provider, notificationprovider, child) {
        final profile = provider.userprofile;
        final notifications = notificationprovider.notifications;
        final userName = profile['name']?.toString() ?? userData['name']?.toString() ?? 'Hema Fruits';

        return AppBar(
          backgroundColor: AppColors.appheader,
          elevation: 1,
          leadingWidth: 44,
          leading: Container(
            margin: const EdgeInsets.only(left: 10),
            child: const Center(
              child: Icon(
                Icons.shopping_basket_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hema Fruits Marketplace',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: context.fontSizeMedium,
                  color: AppColors.appheadertext,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                'Welcome, $userName • ${getHeaderFromPath(currentPath)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            // Notifications Icon
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
                if (notifications.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          notifications.length > 9 ? '9+' : '${notifications.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Three-Dots Popup Menu Button (as requested by user)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.appheadertext,
              ),
              position: PopupMenuPosition.under,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              color: Colors.white,
              elevation: 8,
              onSelected: (value) => _handleMenuSelection(context, value),
              itemBuilder: (context) => [
                _buildPopupMenuItem(
                  value: 'profile',
                  icon: Icons.person_outline_rounded,
                  label: Translate.t("profile.Personal"),
                  color: AppColors.primary,
                ),
                _buildPopupMenuItem(
                  value: 'points',
                  icon: Icons.account_balance_wallet_outlined,
                  label: Translate.t("profile.GetPoint"),
                  color: AppColors.secondary,
                ),
                _buildPopupMenuItem(
                  value: 'settings',
                  icon: Icons.settings_outlined,
                  label: Translate.t("profile.Settings"),
                  color: AppColors.secondary,
                ),
                const PopupMenuDivider(height: 1),
                _buildPopupMenuItem(
                  value: 'signout',
                  icon: Icons.logout_rounded,
                  label: Translate.t("profile.logout"),
                  color: AppColors.error,
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        );
      },
    );
  }
}

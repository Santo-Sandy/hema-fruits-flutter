import 'package:cashew_marketplace/core/providers/language_provider.dart';
import 'package:cashew_marketplace/core/providers/user_provider.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/auth_service/auth_service.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/Responsive/responsivea_context.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/initial_function.dart';
import 'package:cashew_marketplace/features/screens/profile/blocked_screen.dart';
import 'package:cashew_marketplace/features/screens/profile/refferalcard.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/toast_notification.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _Menu();
}

class _Menu extends State<Menu> {
  Map<String, dynamic> userData = {};
  bool _isNotificationEnabled = false;
  double percent = 0;
  String path = RoutePath.personalInfo;
  String currentRole = "buyer";
  @override
  void initState() {
    super.initState();
    getuserprofile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getuserprofile();
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _LanguageBottomSheet(
          currentLang: Translate.currentLang,
          onSelected: (code) async {
            getuserprofile();
            await context.read<LanguageProvider>().changeLanguage(code);
          },
        );
      },
    );
  }

  void _showInitialPageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _InitialPageBottomSheet(
          currentPage: userData['initializer_screen'] ?? 'Marketplace',
          onSelected: (code) async {
            final userId = userData['_id'];
            if (userId == null) return;

            await updateProfile(
              payload: {'initializer_screen': code},
              userId: userId,
            );
            await getuserprofile();
          },
        );
      },
    );
  }

  Future<void> getProfilePercentage() async {
    final String nature = (userData['natureOfBusiness'] ?? '').toString();
    // final bool isAgent = nature.toLowerCase() == 'agent';

    // These are the best signals available in current app storage.
    final dynamic country = userData['natureOfBusiness'];
    final bool hasCountry =
        country != null && country.toString().trim().isNotEmpty;

    final bool isProfileComplete =
        (userData['natureOfBusiness'] == '' ||
            userData['natureOfBusiness'] == null) ==
        false;
    final bool isCompanyComplete =
        (userData['companyName'] == '' || userData['companyName'] == null) ==
        false;
    path = RoutePath.personalInfo;

    // Start from initial.
    percent = 25;

    // Address + country contributes toward second step only for non-agent.
    // If agent, request says completion becomes 100%.

    // Second step (address + country) -> reach 50%
    if (hasCountry) {
      percent = 50;
      path = RoutePath.businessInfo;
    }

    // Business profile completes -> 100%
    // For non-agent: when profile/company complete.
    if (isProfileComplete && isCompanyComplete) {
      percent = 100;
    }

    setState(() {
      percent = percent.clamp(0, 100);
    });
  }

  Future<void> getuserprofile() async {
    try {
      final profileProvider = context.read<ProfileProvider>();
      userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];
      FilterRequest request = FilterRequest(userId: userId);
      profileProvider.userprofilefetch(
        endpoint: "entities/filter/users",
        filterPayload: request.getuserprofile(),
      );
      await getUser(userId);
      userData = await SecureStorageService.getUserProfileData();
      await getProfilePercentage();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _openProfileDrawer(String path, Widget child) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        barrierColor: AppColors.textSecondary,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              child: SizedBox(
                width: 400,
                height: MediaQuery.of(context).size.height,
                child: child,
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
      if (currentLocation == path) {
        context.pop();
      } else {
        context.push(path);
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

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('profileScreen', context);
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        userData = provider.userprofile;
        return RefreshIndicator(
          onRefresh: getuserprofile,
          child: SingleChildScrollView(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: AppColors.primaryDark,
                  leading: IconButton(
                    onPressed: () {
                      context.pop();
                    },
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  centerTitle: false,
                  title: Text(
                    Translate.t("profile.menu"),
                    style: AppTextThemes.getLightTextTheme.titleMedium!
                        .copyWith(color: Colors.white),
                  ),
                ),
                // const SizedBox(height: 10), // Menu items
                Column(
                  children: [
                    ReferFriendCard(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _ProfileSection(Translate.t("profile.account"), [
                            _MenuItem(
                              Translate.t("profile.Personal"),
                              Icons.person_outline,
                              AppColors.primary,
                              () {
                                String currentLocation;
                                if (MediaQuery.sizeOf(context).width > 600) {
                                  currentLocation = GoRouter.of(context)
                                      .routerDelegate
                                      .currentConfiguration
                                      .uri
                                      .toString();
                                  context.pop();
                                } else {
                                  currentLocation = GoRouterState.of(
                                    context,
                                  ).uri.toString();
                                }
                                if (currentLocation == RoutePath.personalInfo) {
                                  context.pop();
                                } else {
                                  context.push(RoutePath.profile);
                                }
                              },
                            ),
                            // if (true) ...[
                            //   _MenuItem(
                            //     Translate.t("profile.Business"),
                            //     Icons.business_outlined,
                            //     AppColors.accent,
                            //     () {
                            //       String currentLocation;
                            //       if (MediaQuery.sizeOf(context).width > 600) {
                            //         currentLocation = GoRouter.of(context)
                            //             .routerDelegate
                            //             .currentConfiguration
                            //             .uri
                            //             .toString();
                            //         context.pop();
                            //       } else {
                            //         currentLocation = GoRouterState.of(
                            //           context,
                            //         ).uri.toString();
                            //       }
                            //       if (currentLocation == RoutePath.businessInfo) {
                            //         context.pop();
                            //       } else {
                            //         context.pushNamed(RouteName.businessInfo);
                            //       }
                            //     },
                            //   ),
                            // ],
                            // _MenuItem(
                            //   Translate.t('profile.role'),
                            //   Icons.swap_horiz_rounded,
                            //   AppColors.accent,
                            //   () {},
                            // ),
                            _MenuItem(
                              Translate.t("profile.GetPoint"),
                              Icons.wallet,
                              AppColors.secondary,
                              () {
                                String currentLocation;
                                if (MediaQuery.sizeOf(context).width > 600) {
                                  currentLocation = GoRouter.of(context)
                                      .routerDelegate
                                      .currentConfiguration
                                      .uri
                                      .toString();
                                  context.pop();
                                } else {
                                  currentLocation = GoRouterState.of(
                                    context,
                                  ).uri.toString();
                                }
                                if (currentLocation == RoutePath.creditpoint) {
                                  context.pop();
                                } else {
                                  context.push(RoutePath.creditpoint);
                                }
                              },
                            ),
                          ]),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  Translate.t("profile.activity"),
                                  style: TextStyle(
                                    fontSize: context.fontSizeMedium,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      leading: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppColors.textSecondary
                                              .withValues(alpha: 0.09),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.notifications_outlined,
                                          color: AppColors.accent,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        Translate.t("profile.Notification"),
                                        style: TextStyle(
                                          fontSize: context.fontSizeBase,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      trailing: Switch(
                                        value: _isNotificationEnabled,
                                        onChanged: (value) {
                                          setState(() {
                                            _isNotificationEnabled = value;
                                          });
                                        },
                                        thumbIcon:
                                            WidgetStateProperty.resolveWith<
                                              Icon?
                                            >((states) {
                                              if (states.contains(
                                                WidgetState.selected,
                                              )) {
                                                return const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                );
                                              }
                                              return const Icon(
                                                Icons.close,
                                                size: 14,
                                              );
                                            }),
                                        trackOutlineColor:
                                            WidgetStateProperty.all(
                                              Colors.transparent,
                                            ),
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: AppColors.accent,
                                        inactiveThumbColor: Colors.white,
                                        inactiveTrackColor: AppColors.beige,
                                      ),
                                      dense: true,
                                    ),
                                    _buildNormalMenuItem(
                                      context,
                                      Translate.t('profile.initialpage'),
                                      Icons.pages_outlined,
                                      AppColors.accent,
                                      _showInitialPageDialog,
                                    ),
                                    _buildNormalMenuItem(
                                      context,
                                      Translate.t('profile.language'),
                                      Icons.translate,
                                      AppColors.secondary,
                                      _showLanguageDialog,
                                    ),
                                    // _buildNormalMenuItem(
                                    //   context,
                                    //   Translate.t("profile.Settings"),
                                    //   Icons.settings_outlined,
                                    //   AppColors.secondary,
                                    //   () {
                                    //     _openProfileDrawer(
                                    //       RoutePath.settings,
                                    //       SettingsScreen(),
                                    //     );
                                    //   },
                                    // ),
                                    _buildNormalMenuItem(
                                      context,
                                      Translate.t("profile.Blocked"),
                                      Icons.block_outlined,
                                      AppColors.secondary,
                                      () {
                                        _openProfileDrawer(
                                          RoutePath.blocked,
                                          BlockedUsersPage(),
                                        );
                                      },
                                    ),
                                    _buildNormalMenuItem(
                                      context,
                                      Translate.t("profile.Support"),
                                      Icons.help_outline,
                                      AppColors.secondary,
                                      () {},
                                    ),
                                    // _buildNormalMenuItem(
                                    //   context,
                                    //   Translate.t("profile.logout"),
                                    //   Icons.logout,
                                    //   AppColors.error,
                                    //   () => _handleSignOut(context),
                                    // ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ProfileSection("", [
                            _MenuItem(
                              Translate.t("profile.logout"),
                              Icons.logout,
                              AppColors.error,
                              () => _handleSignOut(context),
                              isDestructive: true,
                            ),
                          ]),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNormalMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: context.fontSizeBase,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
      dense: true,
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final authService = context.read<AuthService>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundLight,
          title: const Text('Do you want to Sign out?'),
          // content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('No', style: TextStyle(color: AppColors.error)),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final router = GoRouter.of(context);
                Navigator.pop(dialogContext);

                try {
                  await authService.signOut();
                } catch (e) {
                  if (!mounted) return;
                  // messenger.showSnackBar(
                  //   SnackBar(
                  //     content: Text(e.toString()),
                  //     backgroundColor: AppColors.error,
                  //   ),
                  // );
                } finally {
                  bool login = false;
                  try {
                    login = await InitialFunction.layoutLogin();
                  } catch (e) {
                    debugPrintStack();
                  }
                  router.go('/login', extra: login);
                }
              },
              child: Text('Yes', style: TextStyle(color: AppColors.success)),
            ),
          ],
        );
      },
    );
  }

  // void _logout(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (_) => AlertDialog(
  //       title: const Text('Logout'),
  //       content: const Text('Are you sure you want to logout?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             context.read<AuthProvider>().logout();
  //           },
  //           child: const Text(
  //             'Logout',
  //             style: TextStyle(color: AppColors.error),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _ProfileSection(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != "")
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: context.fontSizeMedium,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                letterSpacing: 0.8,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: items.map((item) {
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: context.fontSizeBase,
                        fontWeight: FontWeight.w500,
                        color: item.isDestructive
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: item.isDestructive
                        ? null
                        : Icon(Icons.chevron_right, color: AppColors.textHint),
                    onTap: item.onTap,
                    dense: true,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MenuItem(
    this.label,
    this.icon,
    this.color,
    this.onTap, {
    this.isDestructive = false,
  });
}

class _InitialPageBottomSheet extends StatefulWidget {
  final String currentPage;
  final Future<void> Function(String) onSelected;

  const _InitialPageBottomSheet({
    required this.currentPage,
    required this.onSelected,
  });

  @override
  State<_InitialPageBottomSheet> createState() =>
      _InitialPageBottomSheetState();
}

class _InitialPageBottomSheetState extends State<_InitialPageBottomSheet> {
  late String _selected;
  bool _loading = false;

  List<Map<String, String>> get _pages => [
    {'code': 'Marketplace', 'label': Translate.t('initialpage.marketplace')},
    {'code': 'Dashboard', 'label': Translate.t('initialpage.dashboard')},
    {
      'code': 'BiddingScreen',
      'label': Translate.t('initialpage.biddingscreen'),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPage;
  }

  @override
  Widget build(BuildContext context) {
    return _PickerSheet(
      title: Translate.t('initialpage.page'),
      subtitle: Translate.t('initialpage.choose'),
      children: _pages.map((page) {
        final isSelected = _selected == page['code'];
        return _PickerOption(
          title: page['label']!,
          selected: isSelected,
          loading: _loading,
          onTap: () async {
            final navigator = Navigator.of(context);
            setState(() {
              _selected = page['code']!;
              _loading = true;
            });
            await widget.onSelected(page['code']!);
            if (mounted) navigator.pop();
          },
        );
      }).toList(),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: context.fontSizeLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.title,
    required this.selected,
    required this.loading,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.creamLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fontSizeBase,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: context.fontSizeSmall,
                        color: AppColors.textHint,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.beige, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageBottomSheet extends StatefulWidget {
  final String currentLang;
  final Future<void> Function(String) onSelected;

  const _LanguageBottomSheet({
    required this.currentLang,
    required this.onSelected,
  });

  @override
  State<_LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<_LanguageBottomSheet> {
  late String _selected;
  bool _loading = false;

  List<Map<String, String>> get _languages => [
    {
      'code': 'english',
      'label': 'English',
      'native': Translate.t('language.english'),
    },
    {
      'code': 'tamil',
      'label': 'தமிழ்',
      'native': Translate.t('language.tamil'),
    },
    {
      'code': 'hindi',
      'label': 'हिन्दी',
      'native': Translate.t('language.hindi'),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentLang;
  }

  @override
  Widget build(BuildContext context) {
    return _PickerSheet(
      title: Translate.t('language.Language'),
      subtitle: Translate.t('language.choose'),
      children: _languages.map((lang) {
        final isSelected = _selected == lang['code'];
        return _PickerOption(
          title: lang['label']!,
          subtitle: lang['native'],
          selected: isSelected,
          loading: _loading,
          onTap: () async {
            final navigator = Navigator.of(context);
            setState(() {
              _selected = lang['code']!;
              _loading = true;
            });
            await widget.onSelected(lang['code']!);
            if (mounted) navigator.pop();
          },
        );
      }).toList(),
    );
  }
}

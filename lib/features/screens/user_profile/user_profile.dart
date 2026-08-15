import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/providers/swap_user_provider.dart';
import 'package:hema_fruits/core/repositories/report_repository.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/Responsive/responsivea_context.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/core/utils/currency.dart';
import 'package:hema_fruits/core/utils/uri_launcher.dart';
import 'package:hema_fruits/features/layouts/skeleton_loader.dart';
import 'package:hema_fruits/features/screens/profile/profile_screen.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/custom.dart';
import 'package:hema_fruits/shared/widgets/view_card_widget.dart';
import 'package:hema_fruits/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? userData;
  const UserProfilePage({super.key, this.id, this.userData});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int _selectedTab = 0;
  String userId = '';
  Map<String, dynamic>? userData = {};
  String role = 'buyer';
  List<String> quickreports = [];
  bool company = true;
  bool posts = false;
  bool isloadingprofile = true;
  bool isloading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ContextManager().saveCurrentPage('UserProfile', context);
      _initializeProfile();
    });
  }

  Future<void> onReport(String reason, String id) async {
    try {
      final postService = ApiDioPostService();
      await postService.getdata(
        endpoint: "entities/reports",
        data: {
          "reason": reason.trim(),
          "report_id": id,
          "userId": userId,
          "type": "Profile",
        },
      );
    } catch (e) {
      debugPrintStack();
    }
  }

  Future<void> onBlock(String reason, String id) async {
    try {
      final postService = ApiDioPostService();
      await postService.getdata(
        endpoint: "entities/blocked",
        data: {"userId": userId, "block_id": id, "reason": reason},
      );
      context.pop();
      context.pop();
    } catch (e) {
      debugPrintStack();
    }
  }

  Future<void> _initializeProfile() async {
    try {
      await loaduser();
      final endpoint = "dataset/data/Marketplace";

      final filterPayload = _buildFilterPayload();

      await context.read<UserAccountProvider>().fetch(
        userId: widget.id ?? '',
        endpoint: endpoint,
        filterPayload: filterPayload,
      );

      final userData = await SecureStorageService.getUserData();
      if (!mounted) return;

      setState(() {
        userId = userData['_id'] ?? '';
      });

      role = context.read<SwapUserProvider>().swapedUser;

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text('Error loading profile')));
    }
    quickreport();
  }

  Future<void> loaduser() async {
    try {
      final provider = context.read<UserProfProvider>();

      await provider.fetch(
        userId: widget.id ?? '',
        endpoint: "entities/filter/users",
        filterPayload: {
          "filter": [
            {
              "clause": "AND",
              "conditions": [
                {
                  "column": "_id",
                  "operator": "EQUALS",
                  "value": widget.id?.toString() ?? '',
                },
              ],
            },
          ],
        },
      );

      if (!mounted) return;

      if (provider.post.isNotEmpty) {
        setState(() {
          userData = provider.post[0];
          isloadingprofile = false;
        });
      }
    } catch (e) {
      debugPrint('loaduser error: $e');
    } finally {
      setState(() => isloadingprofile = false);
    }
  }

  Future<void> quickreport() async {
    try {
      await context.read<CountryProvider>().fetchReports();
    } catch (e) {
      debugPrintStack();
    } finally {
      final reports = ReportRepository.instance.getReports();
      setState(() {
        quickreports = reports;
      });
    }
  }

  Map<String, dynamic> _buildFilterPayload() {
    return {
      "filter": [
        {
          "clause": "AND",
          "conditions": [
            {
              "column": "userId",
              "operator": "EQUALS",
              "value": widget.id ?? "",
            },
            {"column": "isDeleted", "operator": "EQUALS", "value": false},
            {"column": "status", "operator": "NOTEQUAL", "value": "closed"},
          ],
        },
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App Bar
        // Consumer<UserAccountProvider>(
        //   builder: (context, provider, _) {
        //     if (provider.isLoading) {
        //       return const Center(
        //         child: CircularProgressIndicator(color: AppColors.primary),
        //       );
        //     }
        //     final post = provider.post.first;
        //     final merchantName = provider.post.isNotEmpty
        //         ? post['merchantname'] ?? post['user_name']
        //         : 'User';
        //     final isVerified = provider.post.isNotEmpty
        //         ? post['isProfileComplete'] ?? false
        //         : false;

        //     return _AppBar(name: merchantName, isVerified: isVerified);
        //   },
        // ),

        // Content
        Expanded(
          child: Consumer2<UserAccountProvider, UserProfProvider>(
            builder: (context, provider, user, _) {
              // Loading state
              if (provider.isLoading && isloadingprofile && user.isLoading) {
                return Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: ProfilePageSkeleton(),
                );
              }

              // Empty state
              if (user.post.isEmpty) {
                return Center(
                  child: Text(
                    'No profile data found.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              final item = provider.post.isNotEmpty
                  ? provider.post.first
                  : null;

              final hasData = provider.post.isNotEmpty;
              final post = hasData ? provider.post.first : null;

              final merchantName = userData!['name'] ?? 'User';

              final isVerified = hasData
                  ? post!['isProfileComplete'] ?? false
                  : false;

              final rcnProducts = _filterProductsByType(provider.post, 'RCN');
              final kernelProducts = _filterProductsByType(
                provider.post,
                'Kernel',
              );

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _AppBar(
                      item: userData ?? "",
                      quickreports: quickreports,
                      name: merchantName,
                      isVerified: isVerified,
                      onReport: (reason) {
                        onReport(reason, item!['_id']);
                      },
                      onBlock: (String reason) {
                        onBlock(reason, item!['userid']);
                      },
                    ),
                    SingleChildScrollView(
                      // padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Profile Header Card
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    PersonalDetailsCard(
                                      user: userData!,
                                      isotheruser: true,
                                    ),
                                    if (userData!["companyName"] != null &&
                                        userData!["companyName"] != "") ...[
                                      // Row(
                                      //   children: [
                                      //     Expanded(
                                      //       child: GestureDetector(
                                      //         onTap: () => setState(() {
                                      //           company = !company;
                                      //         }),
                                      //         child: ListTile(
                                      //           title: Text(
                                      //             "Company Details",
                                      //             style: AppTextThemes
                                      //                 .getLightTextTheme
                                      //                 .titleMedium!
                                      //                 .copyWith(),
                                      //           ),
                                      //           trailing: Icon(
                                      //             !company
                                      //                 ? Icons.arrow_right
                                      //                 : Icons.arrow_drop_down,
                                      //             size: 40,
                                      //           ),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                      // if (company) ...[
                                      CompanyDetailsCard(
                                        nolabel: true,
                                        dropdown: company,
                                        // ontap: () => setState(() {
                                        //   company = !company;
                                        // }),
                                        company: userData!,
                                      ),
                                      // ],
                                    ],
                                  ],
                                ),
                                // _ProfileHeaderCard(
                                //   name: merchantName ?? '',
                                //   isVerified:
                                //       item['isProfileComplete'] ?? false,
                                //   company:
                                //       item['companyName'] != null &&
                                //           item['companyName'] != ''
                                //       ? item['companyName']
                                //       : 'NO Company',
                                //   bio:
                                //       item['company_description'] ??
                                //       item['description'] ??
                                //       'No bio available',
                                //   isPro: item['gstRegistered'] ?? false,
                                //   email: item['email'] ?? '—',
                                //   phone: item['phone'] ?? '—',
                                //   location: item['country'] ?? 'Unknown',
                                //   avatarUrl:
                                //       (userData!['profilePicture'] ?? "")
                                //           as String?,
                                // ),
                              ),

                              // MediaQuery.sizeOf(context).width > 600
                              //     ? provider.post.isEmpty
                              //           ? Center(
                              //               child: Text(
                              //                 'No profile data found.',
                              //                 style: TextStyle(
                              //                   fontFamily: 'Inter',
                              //                   fontSize: 14,
                              //                   color: AppColors.textSecondary,
                              //                 ),
                              //               ),
                              //             )
                              //           : Expanded(
                              //               flex: 2,
                              //               child: Column(
                              //                 mainAxisSize: MainAxisSize.max,
                              //                 children: [
                              //                   Container(
                              //                     padding:
                              //                         const EdgeInsets.only(
                              //                           left: 24,
                              //                           right: 24,
                              //                           bottom: 10,
                              //                           top: 10,
                              //                         ),
                              //                     // decoration: BoxDecoration(
                              //                     //   color: AppColors.primarySubtle,
                              //                     //   borderRadius: BorderRadius.only(
                              //                     //     topRight: Radius.circular(24),
                              //                     //     bottomRight: Radius.circular(24),
                              //                     //   ),
                              //                     //   border: Border.all(
                              //                     //     color: AppColors.primary
                              //                     //         .withAlpha(20),
                              //                     //     width: 1,
                              //                     //   ),
                              //                     // ),
                              //                     child: Column(
                              //                       mainAxisAlignment:
                              //                           MainAxisAlignment.start,
                              //                       crossAxisAlignment:
                              //                           CrossAxisAlignment.end,
                              //                       children: [
                              //                         Container(
                              //                           width: 150,
                              //                           child: ProfileTabSwitcher(
                              //                             tabs: [
                              //                               'RCN',
                              //                               'Kernel',
                              //                             ],
                              //                             selectedIndex:
                              //                                 _selectedTab,
                              //                             onTabChanged: (i) {
                              //                               if (!mounted)
                              //                                 return;
                              //                               setState(
                              //                                 () =>
                              //                                     _selectedTab =
                              //                                         i,
                              //                               );
                              //                             },
                              //                           ),
                              //                         ),
                              //                         SizedBox(height: 25),
                              //                         Row(
                              //                           children: [
                              //                             Expanded(
                              //                               child: SummaryRowCard(
                              //                                 numberOfResponse:
                              //                                     _selectedTab ==
                              //                                         0
                              //                                     ? rcnProducts
                              //                                           .length
                              //                                     : kernelProducts
                              //                                           .length,
                              //                                 label:
                              //                                     "${Translate.t("post.Total_post")}:",
                              //                               ),
                              //                             ),
                              //                             const SizedBox(
                              //                               width: 10,
                              //                             ),
                              //                           ],
                              //                         ),
                              //                       ],
                              //                     ),
                              //                   ),
                              //                 ],
                              //               ),
                              //             )
                              //     : SizedBox(),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    posts = !posts;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      10,
                                    ).copyWith(left: 20, right: 20),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        // top: Radius.circular(28),
                                      ),
                                      color: AppColors.primaryDark,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Post History",
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        // Icon(
                                        //   !posts
                                        //       ? Icons.arrow_right
                                        //       : Icons.arrow_drop_down,
                                        //   color: Colors.white.withOpacity(0.9),
                                        //   size: 40,
                                        // ),
                                        // ListTile(
                                        //   title: Text(
                                        //     "Post History",
                                        //     maxLines: 2,
                                        //     overflow: TextOverflow.ellipsis,
                                        //     style: TextStyle(
                                        //       fontSize: 22,
                                        //       fontWeight: FontWeight.w700,
                                        //       color: Colors.white,
                                        //     ),
                                        //   ),
                                        //   trailing: Icon(
                                        //     !posts
                                        //         ? Icons.arrow_right
                                        //         : Icons.arrow_drop_down,
                                        //     color: Colors.white.withOpacity(0.9),
                                        //     size: 40,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // if (posts) ...[
                          const SizedBox(height: 16),
                          // MediaQuery.sizeOf(context).width <= 600
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(
                                    left: 24,
                                    right: 24,
                                    bottom: 10,
                                    top: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySubtle,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                    ),
                                    border: Border.all(
                                      color: AppColors.primary.withAlpha(20),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: ProfileTabSwitcher(
                                          tabs: [Translate.t('filter.rcn'), Translate.t('filter.kernel')],
                                          selectedIndex: _selectedTab,
                                          onTabChanged: (i) {
                                            if (!mounted) return;
                                            setState(() => _selectedTab = i);
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 25),
                                      SummaryRowCard(
                                        numberOfResponse: _selectedTab == 0
                                            ? rcnProducts.length
                                            : kernelProducts.length,
                                        label:
                                            "${Translate.t("post.Total_post")}:",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Tab Content
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: _selectedTab == 0
                                ? _buildProductGrid(
                                    rcnProducts,
                                    userId,
                                    key: const ValueKey('rcn'),
                                  )
                                : _buildProductGrid(
                                    kernelProducts,
                                    userId,
                                    key: const ValueKey('kernel'),
                                  ),
                          ),
                          // ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filterProductsByType(
    List<dynamic> products,
    String type,
  ) {
    return products
        .whereType<Map<String, dynamic>>()
        .where((p) => p['type'] == type)
        .toList();
  }

  Future<void> action({
    required String id,
    required String action,
    bool? status,
  }) async {
    try {
      final role = context.read<SwapUserProvider>().swapedUser;
      String endpoint = role == "processor"
          ? "capitalmarket/requirements/$id/$action"
          : "capitalmarket/stocks/$id/$action";
      await context.read<PostProvider>().action(
        endpoint,
        status,
        id,
        action,
        userId,
      );
      // await _initializeProfile();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Widget _buildProductGrid(
    List<Map<String, dynamic>> products,
    String userId, {
    Key? key,
  }) {
    if (products.isEmpty) {
      return SizedBox(
        key: key,
        height: 140,
        child: Center(
          child: Text(
            'No ${products.isEmpty ? 'products' : 'items'} available',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return MarketplaceGrid(
      key: key,
      products: products
          .map(
            (p) => {
              'title': _buildProductTitle(p),
              'name': p['merchantname'] ?? 'Unknown',
              'company': p['companyName'] ?? '',
              'location': p['location'] ?? 'Unknown',
              'quantity': Formatters.formatToKg(
                p['availableqty'] ?? p['requiredqty'] ?? 0,
              ),
              'posttype': p['post_type'] ?? "",
              'availableFrom': Formatters.formatDate(
                p['fromdate'] ?? p['orderDate'] ?? p['created_on'] ?? 'N/A',
              ),
              'qtylabel': p['availableqty'] != null
                  ? Translate.t("homeScreen.available_from")
                  : Translate.t("homeScreen.required_from"),
              'availableUntil': Formatters.formatDate(
                p['availableqty'] != null ? p['expiredate'] : p['deliverydate'],
              ),
              'pricePerUnit': Formatters.formatTomoney(
                (p['priceunit'] == 'MT'
                        ? p['sellingprice'] ?? p['expectedprice'] / 1000
                        : p['sellingprice'] ?? p['expectedprice']) ??
                    p['price'] ??
                    0,
              ),
              'currency': safeCurrencySymbol(p['currency']),
              'unit': 'kg',
              'isrcn': p['type'] == 'RCN',
              'high': p['high'] == true,
              'liked': (p['favorite'] as List?)?.contains(userId) ?? false,
            },
          )
          .toList(),
      onCardTap: (index) {
        final path = products[index]['post_type'] == 'stocks'
            ? RoutePath.viewscreen
            : RoutePath.sellerviewscreen;
        context.push(path, extra: '${products[index]['_id']}');
      },
      onLike: (index, isLiked) async {
        await action(
          id: products[index]['_id'],
          action: "favorite",
          status: isLiked,
        );
      },
    );
  }

  String safeCurrencySymbol(dynamic currency) {
    if (currency == null) return getCurrencySymbol("USD");

    final code = currency.toString().trim().toUpperCase();

    if (code.isEmpty) return getCurrencySymbol("USD");

    return getCurrencySymbol(code);
  }

  String _buildProductTitle(Map<String, dynamic> product) {
    final grade = product['grade']?.toString() ?? '';
    final type = product['type']?.toString() ?? 'Product';
    final year =
        product['yearofcrop']?.toString() ??
        product['yearOfCrop']?.toString() ??
        '';
    final origin = product['origin']?.toString() ?? '';

    final displayType = type == 'RCN' ? Translate.t('filter.rcn') : (type == 'Kernel' ? Translate.t('filter.kernel') : type);
    final parts = [
      if (grade.isNotEmpty) grade else displayType,
      if (type == 'RCN') year else origin,
    ];

    return parts.join(' - ').trim();
  }
}

class _AppBar extends StatelessWidget {
  final String name;
  final List<String> quickreports;
  final bool isVerified;
  final dynamic item;
  final Function(String)? onReport;
  final Function(String)? onBlock;

  const _AppBar({
    required this.name,
    required this.item,
    required this.quickreports,
    required this.isVerified,
    required this.onReport,
    required this.onBlock,
  });

  Future<void> showReportBottomSheet(BuildContext context) async {
    final TextEditingController customReasonController =
        TextEditingController();

    int selectedIndex = -1;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isOtherSelected = selectedIndex == quickreports.length - 1;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Drag Handle
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.borderLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Title
                    Text(
                      Translate.t("view.report_user"),
                      style: AppTextThemes.getLightTextTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      Translate.t("view.report_notice"),
                      style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// Radio Options
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Column(
                              children: List.generate(quickreports.length, (
                                index,
                              ) {
                                final isSelected = selectedIndex == index;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.borderLight,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.06,
                                          )
                                        : AppColors.surface,
                                  ),
                                  child: RadioListTile<int>(
                                    value: index,
                                    groupValue: selectedIndex,
                                    activeColor: AppColors.primary,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    title: Text(
                                      quickreports[index],
                                      style: AppTextThemes
                                          .getLightTextTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    onChanged: (value) {
                                      setModalState(() {
                                        selectedIndex = value!;
                                      });
                                    },
                                  ),
                                );
                              }),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: isOtherSelected
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: TextFormField(
                                        controller: customReasonController,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                          hintText: Translate.t(
                                            "view.report_custom",
                                          ),
                                          filled: true,
                                          fillColor: AppColors.surface,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.borderLight,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.borderLight,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primary,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// Custom Reason Field
                    const SizedBox(height: 28),

                    /// Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          if (selectedIndex == -1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please select a reason'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          final reason = isOtherSelected
                              ? customReasonController.text.trim()
                              : quickreports[selectedIndex];

                          if (isOtherSelected && reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Please enter reason'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(context);

                          onReport?.call(reason);
                        },
                        child: Text(
                          Translate.t("view.report"),
                          style: AppTextThemes.getLightTextTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBlockDialog(BuildContext context) {
    TextEditingController reason = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Translate.t("view.block_user")),
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(Translate.t("view.block_notice")),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  controller: reason,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: Translate.t("view.report_custom"),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                if (reason.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter reason'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                context.pop();
                onBlock?.call(reason.text) ?? () {};
              },
              child: Text(Translate.t("view.block")),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        // borderRadius: BorderRadius.circular(10),
        // border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                _iconBtn(Icons.arrow_back_ios, 24, onTap: () => context.pop()),
                AppAvatar(
                  imageUrl: item['profilePicture'] ?? "",
                  name: name,
                  radius: 35,
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 20, 8, 0),
                    // decoration: BoxDecoration(color: AppColors.primary),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Avatar ──
                            Text(
                              name.split(' ')[0],
                              style: AppTextThemes.getLightTextTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.background,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                            ),

                            const SizedBox(height: 8),

                            // ── Role chip ──
                            Row(
                              children: [
                                AppChip(
                                  label: "${item['natureOfBusiness']}",
                                  color: AppColors.background,
                                ),
                                // Divider(
                                //   height: 30,
                                //   thickness: 10,
                                //   indent: 10,
                                //   color: AppColors.background,
                                // ),
                                // AppChip(
                                //   label: item['role'] != null
                                //       ? item['role'] == "both"
                                //             ? "Buyer & Merchant"
                                //             : (item['role'] == "processor"
                                //                   ? "Merchant"
                                //                   : "Buyer")
                                //       : "Role",
                                //   color: AppColors.background,
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // const SizedBox(width: 5),
                // Expanded(
                //   child: Row(
                //     children: [
                //       Text(
                //         name.split(" ")[0],
                //         style: TextStyle(
                //           fontFamily: 'Inter',
                //           fontSize: 18,
                //           fontWeight: FontWeight.w800,
                //           color: Colors.white,
                //         ),
                //         maxLines: 1,
                //         overflow: TextOverflow.ellipsis,
                //       ),
                //       const SizedBox(width: 6),
                //       if (isVerified)
                //         Icon(Icons.verified, color: AppColors.info, size: 15),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsetsGeometry.zero,
            tooltip: 'More options',
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: AppColors.surface,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            position: PopupMenuPosition.under,
            icon: Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) async {
              switch (value) {
                case 'report':
                  showReportBottomSheet(context);
                  break;

                case 'block':
                  _showBlockDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Translate.t("view.report"),
                      style: AppTextThemes.getLightTextTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              PopupMenuItem<String>(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block_rounded, size: 20, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text(
                      Translate.t("view.block"),
                      style: AppTextThemes.getLightTextTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, double size, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        child: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const _ProfileAvatar({this.imageUrl, this.size = 72});

  ImageProvider? _resolve() {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http'))
      return CachedNetworkImageProvider(imageUrl!);
    return CachedNetworkImageProvider('${AppConfig.imageurl}$imageUrl');
  }

  @override
  Widget build(BuildContext context) {
    final image = _resolve();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2.5),
        color: AppColors.primarySubtle,
      ),
      child: ClipOval(
        child: image != null
            ? Image(
                image: image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppColors.primarySubtle,
    child: Icon(Icons.person, color: AppColors.primary, size: size * 0.5),
  );
}

class SummaryRowCard extends StatelessWidget {
  final int numberOfResponse;
  final String label;

  const SummaryRowCard({
    super.key,
    required this.numberOfResponse,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
            color: AppColors.textSecondaryLight,
            letterSpacing: 0.8,
          ),
        ),
        Text(
          '$numberOfResponse',
          style: AppTextThemes.getLightTextTheme.titleMedium,
        ),
      ],
    );
  }
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Tax Registered',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final bool isVerified;
  final String company;
  final String bio;
  final bool isPro;
  final String email;
  final String phone;
  final String location;
  final String? avatarUrl;

  const _ProfileHeaderCard({
    required this.name,
    required this.isVerified,
    required this.company,
    required this.bio,
    required this.isPro,
    required this.email,
    required this.phone,
    required this.location,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return _card(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // if (name != "")
                    //   Row(
                    //     children: [
                    //       Icon(
                    //         Icons.person_2_outlined,
                    //         size: 20,
                    //         color: AppColors.textSecondary,
                    //       ),
                    //       const SizedBox(width: 5),
                    //       Expanded(
                    //         child: Text(
                    //           name,
                    //           maxLines: 2,
                    //           overflow: TextOverflow.ellipsis,
                    //           style: AppTextThemes.getLightTextTheme.labelLarge!
                    //               .copyWith(
                    //                 fontWeight: FontWeight.w700,
                    //                 color: AppColors.textPrimary,
                    //               ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // Company Info
                    if (company != "")
                      Row(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextThemes.getLightTextTheme.labelLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isPro) const _ProBadge(),
                        ],
                      ),
                    const SizedBox(height: 5),

                    // Contact Info
                    if (location != '')
                      _ContactItem(
                        icon: Icons.location_on_outlined,
                        label: location,
                      ),

                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => ExternalLauncher.call(phone),
                      child: _ContactItem(
                        icon: Icons.phone_outlined,
                        label: phone,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => ExternalLauncher.email(email),
                      child: _ContactItem(
                        icon: Icons.email_outlined,
                        label: email,
                      ),
                    ),
                    // Bio
                  ],
                ),
              ),

              // Avatar
              const SizedBox(width: 14),
              Column(children: [_ProfileAvatar(imageUrl: avatarUrl, size: 60)]),
            ],
          ),
          if (bio.isNotEmpty) ...[
            // const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 11.0),
                  child: Icon(
                    Icons.description_outlined,
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ExpandableText(
                        isonlytext: true,
                        text: 'About: $bio',
                        style: AppTextThemes.getLightTextTheme.labelLarge!
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextThemes.getLightTextTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileTabSwitcher extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Color? backgroundColor;
  final ValueChanged<int> onTabChanged;

  const ProfileTabSwitcher({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.background
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ProfileIconTabSwitcher extends StatelessWidget {
  final List<IconData> icons;
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color? backgroundColor;

  const ProfileIconTabSwitcher({
    super.key,
    required this.icons,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.backgroundColor,
  }) : assert(
         icons.length == labels.length,
         'Icons and labels length must match',
       );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        height: 45,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black),
        ),
        child: Stack(
          children: [
            Row(
              children: List.generate(icons.length, (index) {
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.82),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.24,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : [],
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        padding: EdgeInsets.all(isSelected ? 5 : 4),
                        decoration: BoxDecoration(
                          // color: isSelected
                          //     ? Colors.white.withValues(alpha: 0.18)
                          //     : AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icons[index],
                          size: 22,
                          color: isSelected ? Colors.black : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned(
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.swap_horiz_outlined,
                  color: AppColors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _card({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      border: Border.all(color: AppColors.borderLight, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

// class MarketplaceListingCard extends StatefulWidget {
//   final String title;
//   final String location;
//   final String name;
//   final String company;
//   final String availableUntil;
//   final String qtylabel;
//   final String quantity;
//   final String pricePerUnit;
//   final String currency;
//   final String unit;
//   final bool high;
//   final bool isrcn;
//   final bool liked;
//   final Function(bool isLiked)? onLike;
//   final VoidCallback? onShare;
//   final VoidCallback? onTap;
//   final double? height;
//   final double? width;
//   final String? badge;
//   final Color? badgeColor;
//   final double? rating;
//   final int? reviewCount;
//   final Widget? additionalInfo;

//   const MarketplaceListingCard({
//     super.key,
//     required this.title,
//     required this.name,
//     required this.company,
//     required this.location,
//     required this.quantity,
//     required this.isrcn,
//     required this.liked,
//     required this.qtylabel,
//     required this.availableUntil,
//     required this.pricePerUnit,
//     this.currency = '',
//     this.unit = 'kg',
//     required this.high,
//     this.onLike,
//     this.onShare,
//     this.onTap,
//     this.height,
//     this.width,
//     this.badge,
//     this.badgeColor,
//     this.rating,
//     this.reviewCount,
//     this.additionalInfo,
//   });

//   @override
//   State<MarketplaceListingCard> createState() => _MarketplaceListingCardState();
// }

// class _MarketplaceListingCardState extends State<MarketplaceListingCard>
//     with SingleTickerProviderStateMixin {
//   late bool isLiked;
//   late AnimationController _likeAnimationController;
//   late Animation<double> _likeScaleAnimation;

//   @override
//   void initState() {
//     super.initState();
//     isLiked = widget.liked;

//     _likeAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
//       CurvedAnimation(
//         parent: _likeAnimationController,
//         curve: Curves.elasticOut,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _likeAnimationController.stop();
//     _likeAnimationController.dispose();
//     super.dispose();
//   }

//   void _toggleLike() {
//     if (!isLiked == true) {
//       AppToast.showFavoriteToast(context, "Added to favorite");
//       setState(() => isLiked = !isLiked);
//       widget.onLike?.call(isLiked);
//     } else {
//       // final shouldRemove = await FavoriteDialog.showUnFavoriteDialog(context);
//       AppToast.showFavoriteToast(context, "Removed from favorite");
//       // if (shouldRemove == true) {
//       setState(() => isLiked = !isLiked);
//       widget.onLike?.call(isLiked);
//       // remove favorite
//       // } else {}
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: widget.onTap,
//       child: Container(
//         width: widget.width,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: AppColors.borderLight, width: 1),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.05),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         clipBehavior: Clip.hardEdge,
//         child: Stack(
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 60,
//                     height: 60,
//                     margin: EdgeInsets.only(right: 5),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.grey.shade300, width: 1),
//                       color: Colors.white, // optional
//                     ),
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Image.asset(
//                         widget.isrcn ? AppAssets.iconRcn : AppAssets.iconKernel,
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Row(
//                               children: [
//                                 _buildTitleSection(),
//                                 const SizedBox(width: 8),
//                                 _buildLocationBadge(),
//                               ],
//                             ),
//                             ScaleTransition(
//                               scale: _likeScaleAnimation,
//                               child: GestureDetector(
//                                 onTap: _toggleLike,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     shape: BoxShape.circle,
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black.withValues(
//                                           alpha: 0.1,
//                                         ),
//                                         blurRadius: 4,
//                                         offset: const Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: Icon(
//                                     isLiked
//                                         ? Icons.favorite
//                                         : Icons.favorite_outline,
//                                     color: isLiked
//                                         ? AppColors.error
//                                         : AppColors.textSecondary,
//                                     size: 18,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         _buildMetaInfo(),
//                         const SizedBox(height: 8),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // Like Button
//             // Positioned(
//             //   top: 0,
//             //   right: 0,
//             //   child: ScaleTransition(
//             //     scale: _likeScaleAnimation,
//             //     child: GestureDetector(
//             //       onTap: _toggleLike,
//             //       child: Container(
//             //         padding: const EdgeInsets.all(6),
//             //         decoration: BoxDecoration(
//             //           color: Colors.white,
//             //           shape: BoxShape.circle,
//             //           boxShadow: [
//             //             BoxShadow(
//             //               color: Colors.black.withValues(alpha: 0.1),
//             //               blurRadius: 4,
//             //               offset: const Offset(0, 2),
//             //             ),
//             //           ],
//             //         ),
//             //         child: Icon(
//             //           isLiked ? Icons.favorite : Icons.favorite_outline,
//             //           color: isLiked
//             //               ? AppColors.error
//             //               : AppColors.textSecondary,
//             //           size: 18,
//             //         ),
//             //       ),
//             //     ),
//             //   ),
//             // ),

//             // Badge
//             if (widget.badge != null)
//               Positioned(
//                 top: 0,
//                 left: 0,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: widget.badgeColor ?? AppColors.primary,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Text(
//                     widget.badge!,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 9,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTitleSection() {
//     return Stack(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.title,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.textPrimary,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLocationBadge() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//           decoration: BoxDecoration(
//             color: widget.high
//                 ? AppColors.error.withValues(alpha: 0.1)
//                 : AppColors.buyerColor.withValues(alpha: 0.1),
//             border: Border.all(
//               color: widget.high ? AppColors.error : AppColors.buyerColor,
//               width: 0.5,
//             ),
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: Text(
//             widget.high ? '🌊 High Sea' : widget.location,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 10,
//               fontWeight: FontWeight.w500,
//               color: widget.high ? AppColors.error : AppColors.buyerColor,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildMetaInfo() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   Icon(Icons.pages, size: 12, color: AppColors.textHintDark),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${widget.qtylabel}:',
//                     style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.textHintDark,
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       widget.quantity,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.calendar_today_outlined,
//                     size: 12,
//                     color: AppColors.textHintDark,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     'Until:',
//                     style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w500,
//                       color: AppColors.textHintDark,
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   Expanded(
//                     child: Text(
//                       widget.availableUntil,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//           decoration: BoxDecoration(
//             color: AppColors.primary.withValues(alpha: 0.08),
//             borderRadius: BorderRadius.circular(6),
//             border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
//           ),
//           child: Text(
//             '${widget.currency}${widget.pricePerUnit}/${widget.unit}',
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//               color: AppColors.primary,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

class MarketplaceGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(int index)? onCardTap;
  final Function(int index, bool isLiked)? onLike;

  const MarketplaceGrid({
    super.key,
    required this.products,
    this.onCardTap,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No products available',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    if (context.isMobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) => SizedBox(height: context.v(10)),
        itemBuilder: (context, index) => _buildCard(products[index], index),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width < 1200 ? 1 : 2,
        childAspectRatio: context.isTablet ? 4.6 : 3.6,
        crossAxisSpacing: context.h(10),
        mainAxisSpacing: context.v(10),
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => _buildCard(products[index], index),
    );
  }

  Widget _buildCard(Map<String, dynamic> product, int index) {
    return MarketplaceListingCard(
      posttype: product['posttype'],
      availableFrom: product['availableFrom'],
      qtyavailablelabel: product['qtylabel'] ?? 'Quantity',
      title: product['title'] ?? 'Product',
      name: product['name'] ?? 'Unknown',
      company: product['company'] ?? '',
      location: product['location'] ?? 'Unknown',
      quantity: product['quantity'] ?? '0',
      isrcn: product['isrcn'] ?? false,
      liked: product['liked'] ?? false,
      qtylabel: product['qtylabel'] ?? 'Quantity',
      availableUntil: product['availableUntil'] ?? 'N/A',
      pricePerUnit: product['pricePerUnit'] ?? '0',
      currency: product['currency'] ?? '',
      unit: product['unit'] ?? 'kg',
      high: product['high'] ?? false,
      badge: product['badge'],
      badgeColor: product['badgeColor'],
      onLike: (isLiked) => onLike?.call(index, isLiked),
      onTap: () => onCardTap?.call(index),
    );
    // MarketplaceListingCard(
    //   title: product['title'] ?? 'Product',
    //   name: product['name'] ?? 'Unknown',
    //   company: product['company'] ?? '',
    //   location: product['location'] ?? 'Unknown',
    //   quantity: product['quantity'] ?? '0',
    //   isrcn: product['isrcn'] ?? false,
    //   liked: product['liked'] ?? false,
    //   qtylabel: product['qtylabel'] ?? 'Quantity',
    //   availableUntil: product['availableUntil'] ?? 'N/A',
    //   pricePerUnit: product['pricePerUnit'] ?? '0',
    //   currency: product['currency'] ?? '',
    //   unit: product['unit'] ?? 'kg',
    //   high: product['high'] ?? false,
    //   badge: product['badge'],
    //   badgeColor: product['badgeColor'],
    //   onLike: (isLiked) => onLike?.call(index, isLiked),
    //   onTap: () => onCardTap?.call(index),
    // );
  }
}

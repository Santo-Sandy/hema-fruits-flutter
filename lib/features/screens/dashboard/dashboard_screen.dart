import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/config/app_config.dart';
import 'package:cashew_marketplace/core/constants/app_assets.dart';
import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
import 'package:cashew_marketplace/core/repositories/settings_repository.dart';
import 'package:cashew_marketplace/core/utils/Responsive/responsivea_context.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/core/utils/responsive/app_typography.dart';
import 'package:cashew_marketplace/features/layouts/skeleton_loader.dart';
import 'package:cashew_marketplace/features/screens/user_profile/user_profile.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cashew_marketplace/core/services/offline_queue_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, dynamic>> recentPosts = [];
  bool isLoadingPosts = true;
  String? currentRole;
  String _productType = "Both";
  bool isboth = true;
  String _selectedCategory = "RCN";
  bool _isUserDataCached = false;
  String _cachedUserId = "";

  @override
  void initState() {
    super.initState();
    fetchRecentPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final role = context.watch<SwapUserProvider>().swapedUser;
    final producttype = context.watch<SwapUserProvider>().productType;
    if (producttype == "Both") {
      isboth = true;
    } else {
      _productType = producttype;
      _selectedCategory = producttype;
      isboth = false;
    }
  }

  Future<void> fetchRecentPosts() async {
    if (!mounted) return;

    setState(() => isLoadingPosts = true);
    try {
      // Use cached userId if available
      if (!_isUserDataCached || _cachedUserId.isEmpty) {
        final userData = await SecureStorageService.getUserData();
        _cachedUserId = userData['_id'] ?? '';
        _isUserDataCached = true;
      }

      final request = FilterRequest(
        userId: _cachedUserId,
        type: _selectedCategory,
      );
      final payload = request.getdashboard();
      final provider = context.read<RecentPostProvider>();

      await provider.fetch(
        endpoint: "entities/filter/post",
        userId: _cachedUserId,
        filterPayload: payload,
        type: _selectedCategory,
      );
      if (!mounted) return;

      setState(() {
        recentPosts = List<Map<String, dynamic>>.from(provider.post);
        isLoadingPosts = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoadingPosts = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    }
  }

  void _onCategoryChanged(String newCategory) {
    setState(() => _selectedCategory = newCategory);
    fetchRecentPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child:
            // MediaQuery.sizeOf(context).width >= 1024
            //     ? Row(
            //         crossAxisAlignment: CrossAxisAlignment.center,
            //         children: [
            //           Expanded(
            //             flex: 2, // adjust ratio as needed
            //             child: Column(
            //               crossAxisAlignment: CrossAxisAlignment.start,
            //               children: [
            //                 WelcomeHeader(
            //                   isboth: isboth,
            //                   selectedCategory: _selectedCategory,
            //                   onCategoryChanged: _onCategoryChanged,
            //                 ),
            //                 OverviewSection(
            //                   isboth: isboth,
            //                   selectedCategory: _selectedCategory,
            //                   onCategoryChanged: _onCategoryChanged,
            //                 ),
            //               ],
            //             ),
            //           ),
            //           Expanded(
            //             flex: 1,
            //             child: Padding(
            //               padding: EdgeInsets.all(AppSpacing.lg),
            //               child: Column(
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   if (isLoadingPosts) ...[
            //                     // Text(
            //                     //   'Latest ${recentPosts.length} postings',
            //                     //   style: TextStyle(
            //                     //     fontSize: context.fontSizeSmall,
            //                     //     color: AppColors.textSecondary,
            //                     //     fontWeight: FontWeight.w500,
            //                     //   ),
            //                     // ),
            //                     const SizedBox(height: 16),
            //                     const ActionItemSkeleton(),
            //                   ] else ...[
            //                     RecentActionsSection(posts: recentPosts),
            //                   ],
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ],
            //       ):
            ListView(
              children: [
                WelcomeHeader(
                  isboth: isboth,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: _onCategoryChanged,
                ),
                OverviewSection(
                  isboth: isboth,
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: _onCategoryChanged,
                ),
                QuickNavigationSection(selectedCategory: _selectedCategory),
                // const SizedBox(height: 28),
                isLoadingPosts
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Translate.t("dashboard.recent_activity"),
                              style: TextStyle(
                                fontSize: context.fontSizeXXLarge,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Latest ${recentPosts.length} postings',
                              style: TextStyle(
                                fontSize: context.fontSizeSmall,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ActionItemSkeleton(),
                          ],
                        ),
                      )
                    : RecentActionsSection(posts: recentPosts),
                const SizedBox(height: 28),
              ],
            ),
      ),
    );
  }
}

class QuickNavigationSection extends StatelessWidget {
  final String selectedCategory;

  const QuickNavigationSection({super.key, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final cards = _sellerCards(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: context.isDesktop
              ? 4
              : context.isTablet
              ? 2
              : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: cards,
        ),
      ],
    );
  }

  List<Widget> _sellerCards(BuildContext context) => [];
}

class _QuickNavCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String tag;
  final VoidCallback onTap;

  const _QuickNavCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.fontSizeXSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: context.fontSizeXSmall * 0.9,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeHeader extends StatefulWidget {
  final String selectedCategory;
  final Function(String) onCategoryChanged;
  final bool isboth;

  const WelcomeHeader({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.isboth,
  });

  @override
  State<WelcomeHeader> createState() => _WelcomeHeaderState();
}

class _WelcomeHeaderState extends State<WelcomeHeader> {
  String username = "User";
  Map<String, dynamic>? userData;

  Widget _defaultAvatar() => Container(
    color: AppColors.borderLight,
    child: const Center(
      child: Icon(Icons.person, color: Colors.grey, size: 28),
    ),
  );

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final data = await SecureStorageService.getUserData();
    if (!mounted) return;
    setState(() {
      userData = data;
      username = data['name'] ?? 'User';
    });
  }

  ImageProvider? _resolveImage(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http')) return CachedNetworkImageProvider(value);
    return CachedNetworkImageProvider('${AppConfig.imageurl}$value');
  }

  Widget _profileAvatar() {
    final image = _resolveImage(userData?['profilePicture']?.toString());
    if (image == null) return _defaultAvatar();
    return Image(
      image: image,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _defaultAvatar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("WelcomeHeader Build");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ).copyWith(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDark.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pushNamed(RouteName.profile),
            child: RepaintBoundary(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _profileAvatar(),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translate.t("dashboard.welcome"),
                  style:
                      AppTypography.responsive(
                        context,
                        baseSize: 16,
                        tabletSize: 18,
                        desktopSize: 20,
                      ).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                ),

                const SizedBox(height: 6),

                GestureDetector(
                  onTap: () => context.pushNamed(RouteName.profile),
                  child: Text(
                    username,
                    style: AppTextThemes.getLightTextTheme.titleMedium!.copyWith(
                      color: AppColors.backgroundLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Queue notifier
          ValueListenableBuilder<({bool uploading, int count})>(
            valueListenable: OfflineQueueService.uploadState,
            builder: (context, uploadState, _) {
              return ValueListenableBuilder<int>(
                valueListenable: OfflineQueueService.queueChanged,
                builder: (context, _, __) {
                  // Read synchronously from Hive cache — no async needed
                  final allPending = OfflineQueueService.instance
                      .getPendingRequestsSync();
                  final pendingCount = uploadState.uploading
                      ? uploadState.count
                      : allPending.where(OfflineQueueService.isVisible).length;

                  if (pendingCount <= 0) return const SizedBox();

                  return GestureDetector(
                    onTap: () => context.pushNamed(RouteName.offlineQueue),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (uploadState.uploading) ...[
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Posting $pendingCount...',
                              style: AppTextThemes.getLightTextTheme.labelSmall!
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.schedule_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$pendingCount pending',
                              style: AppTextThemes.getLightTextTheme.labelSmall!
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class OverviewSection extends StatefulWidget {
  final String selectedCategory;
  final bool isboth;
  final ValueChanged<String> onCategoryChanged;

  const OverviewSection({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.isboth,
  });

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  final PostService _service = PostService();

  Map<dynamic, dynamic>? buyerDash;
  Map<dynamic, dynamic>? quotesDash;
  Map<dynamic, dynamic>? marketplaceDash;
  Map<dynamic, dynamic>? responseDash;
  Map<dynamic, dynamic>? stockDash;
  Map<dynamic, dynamic>? enquiryDash;
  Map<dynamic, dynamic>? buyerResponseDash;
  Map<dynamic, dynamic>? my_enquiry;
  Map<String, dynamic> userData = {};
  String userId = "";
  bool isLoading = true;
  String _currentRole = "";
  String get _selectedCategory => widget.selectedCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final role = context.watch<SwapUserProvider>().swapedUser;

    if (_currentRole != role) {
      _currentRole = role;
      isLoading = true;
      fetchDashboard();
    }
  }

  @override
  void didUpdateWidget(OverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      fetchDashboard();
    }
  }

  Map<dynamic, dynamic>? safeResponse(dynamic result) {
    if (result == null) return null;

    final data = result['data'];
    if (data == null || data.isEmpty) return null;

    final response = data[0]['response'];
    if (response == null || response.isEmpty) return null;

    return response[0];
  }

  Future<void> fetchDashboard() async {
    setState(() => isLoading = true);

    final userData = await SecureStorageService.getUserData();
    userId = userData['_id'];

    final request = FilterRequest(userId: userId, type: _selectedCategory);
    final payload = request.getPostByCategory();
    try {
      final results = await Future.wait([
        _service.getPosts(
          endpoint: "dataset/data/post_dashboard",
          data: payload,
        ),
        _service.getPosts(
          endpoint: "dataset/data/mobile_marketplace_post_dashboard",
          data: payload,
        ),
        _service.getPosts(
          endpoint: "dataset/data/post_response_dashboard",
          data: payload,
        ),
        _service.getPosts(
          endpoint: "dataset/data/post_enquiry_dashboard",
          data: payload,
        ),
      ]);
      if (_selectedCategory == 'RCN') {
        await SettingsLocalRepository.instance.clearDashboardRCNSettings();
        await SettingsLocalRepository.instance.saveDasboardRCNSettings(results);
      } else if (_selectedCategory == 'Kernel') {
        await SettingsLocalRepository.instance.clearDashboardKernelSettings();
        await SettingsLocalRepository.instance.saveDasboardKernelSettings(
          results,
        );
      }
      setState(() {
        stockDash = safeResponse(results[0]);
        enquiryDash = safeResponse(results[1]);
        buyerResponseDash = safeResponse(results[2]);
        my_enquiry = safeResponse(results[3]);
      });
    } catch (e) {
      debugPrintStack();
    } finally {
      try {
        List<dynamic> results = [];
        if (_selectedCategory == 'RCN') {
          results = SettingsLocalRepository.instance.getDashboardRCNSettings();
        } else if (_selectedCategory == 'Kernel') {
          results = SettingsLocalRepository.instance
              .getDashboardKernelSettings();
        }
        setState(() {
          stockDash = safeResponse(results[0]);
          enquiryDash = safeResponse(results[1]);
          buyerResponseDash = safeResponse(results[2]);
          my_enquiry = safeResponse(results[3]);
        });
      } catch (e) {
        debugPrintStack();
      }
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('Dashboard', context);
    final userRole = context.watch<SwapUserProvider>().swapedUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overview Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Translate.t("dashboard.Overview"),
                    style:
                        AppTypography.responsive(
                          context,
                          baseSize: 24,
                          tabletSize: 26,
                          desktopSize: 28,
                        ).copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Translate.t("dashboard.yourmetrics"),
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.isboth)
                      Container(
                        width: 130,
                        child: ProfileTabSwitcher(
                          backgroundColor: AppColors.textHint,
                          tabs: ['RCN', 'Kernel'],
                          selectedIndex: widget.selectedCategory == 'RCN'
                              ? 0
                              : 1,
                          onTabChanged: (i) => widget.onCategoryChanged(
                            i == 0 ? 'RCN' : 'Kernel',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Stats Grid
        _buildSellerOverview(),
      ],
    );
  }

  Widget _buildBuyerOverview() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.folder_rounded,
                  iconColor: AppColors.primary,
                  title: Translate.t("dashboard.my_requirements"),
                  value: isLoading
                      ? "0"
                      : (buyerDash?['count'] ?? 0).toString(),
                  unit: Translate.t("dashboard.total"),
                  total: isLoading
                      ? ""
                      : "${buyerDash?['active'] ?? 0} ${Translate.t("dashboard.active")}, ${buyerDash?['closed'] ?? 0} ${Translate.t("dashboard.closed")}",
                  hasNotification: false,
                  onTap: () => context.goNamed(
                    RouteName.myActivityPost,
                    extra: {"type": _selectedCategory, "initialTab": 0},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.mail_rounded,
                  iconColor: AppColors.rcnColor,
                  title: Translate.t("dashboard.seller_responses"),
                  value: isLoading
                      ? "0"
                      : (quotesDash?['response_count'] ?? 0).toString(),
                  unit: Translate.t("dashboard.responses"),
                  total: isLoading
                      ? ""
                      : "${Translate.t("dashboard.from")} ${quotesDash?['requirement_from'] ?? 0} ${Translate.t("dashboard.requirement")}",
                  hasNotification: true,
                  onTap: () => context.goNamed(
                    RouteName.myActivityResponses,
                    extra: {"type": _selectedCategory, "initialTab": 1},
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.check_circle_rounded,
                  iconColor: AppColors.kernelColor,
                  title: Translate.t("dashboard.confirmed_orders"),
                  value: isLoading
                      ? "0"
                      : (responseDash?['total'] ?? 0).toString(),
                  unit: Translate.t("dashboard.deals"),
                  total: isLoading
                      ? ""
                      : "${responseDash?['confirm'] ?? 0} ${Translate.t("dashboard.confirmed")}",
                  hasNotification: false,
                  onTap: () => context.goNamed(
                    RouteName.myEnquiry,
                    extra: {"type": _selectedCategory, "initialTab": 1},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.store_rounded,
                  iconColor: AppColors.error,
                  title: Translate.t("dashboard.marketplace"),
                  value: isLoading
                      ? "0"
                      : (marketplaceDash?['marketplace'] ?? 0).toString(),
                  unit: Translate.t("dashboard.products"),
                  total: _selectedCategory, // already dynamic
                  hasNotification: false,
                  onTap: () => context.go(
                    RoutePath.home,
                    extra: {"type": _selectedCategory},
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSellerOverview() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.inventory_2_rounded,
                  iconColor: AppColors.primary,
                  title: Translate.t("dashboard.my_stocks"),
                  value: isLoading
                      ? "0"
                      : (stockDash?['count'] ?? 0).toString(),
                  unit: Translate.t("dashboard.count"),
                  total: isLoading
                      ? "${stockDash?['active'] ?? 0} ${Translate.t("dashboard.active")}, ${stockDash?['closed'] ?? 0} ${Translate.t("dashboard.closed")} "
                      : "${stockDash?['active'] ?? 0} ${Translate.t("dashboard.active")}, ${stockDash?['closed'] ?? 0} ${Translate.t("dashboard.closed")}",
                  hasNotification: false,
                  onTap: () => context.goNamed(
                    RouteName.myActivityPost,
                    extra: {"type": _selectedCategory, "initialTab": 0},
                  ),
                ),
              ),
              const SizedBox(width: 12),
              //       Expanded(
              //         child: StatCard(
              //           icon: Icons.help_outline_rounded,
              //           iconColor: AppColors.rcnColor,
              //           title: Translate.t("dashboard.marketplace"),
              //           //title: Translate.t("dashboard.enquiries"),
              //           value: isLoading
              //               ? "0"
              //               : (enquiryDash?['marketplace'] ?? 0).toString(),
              //           unit: Translate.t("dashboard.stocks"),

              //           // unit: Translate.t("dashboard.enquiries"),
              //           total: _selectedCategory,
              //           hasNotification: true,
              //           onTap: () => context.goNamed(
              //             RouteName.home,
              //             extra: {"type": _selectedCategory},
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 12),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: Row(
              //     children: [
              // Expanded(
              //   child: StatCard(
              //     icon: Icons.handshake_rounded,
              //     iconColor: AppColors.kernelColor,
              //     title: Translate.t("dashboard.buyer_responses"),
              //     value: isLoading
              //         ? "0"
              //         : (buyerResponseDash?['total'] ?? 0).toString(),
              //     unit: Translate.t("dashboard.responses"),
              //     total: isLoading
              //         ? ""
              //         : "${buyerResponseDash?['Reject'] ?? 0} ${Translate.t("dashboard.rejected")}",
              //     hasNotification: false,
              //     // onTap: () => context.goNamed(
              //     //   RouteName.myActivityResponses,
              //     //   extra: {"type": _selectedCategory, "initialTab": 1},
              //     // ),
              //   ),
              // ),
              // const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.verified_user_rounded,
                  iconColor: AppColors.secondary,
                  title: Translate.t("dashboard.my_enquiry"),
                  // title: Translate.t("dashboard.confirmed"),
                  value: isLoading
                      ? "0"
                      : (my_enquiry?['my_enquiry_count'] ?? 0).toString(),
                  unit: Translate.t("dashboard.deals"),
                  total: isLoading
                      ? "${isLoading ? "0" : (my_enquiry?['my_enquiry_count'] ?? 0).toString()} ${Translate.t("dashboard.active")}"
                      : "${isLoading ? "0" : (my_enquiry?['my_enquiry_count'] ?? 0).toString()} ${Translate.t("dashboard.active")}",
                  hasNotification: false,
                  onTap: () => context.goNamed(
                    RouteName.myEnquiry,
                    extra: {"type": _selectedCategory, "initialTab": 1},
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String total;
  final String unit;
  final bool hasNotification;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.total,
    required this.unit,
    required this.hasNotification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and notification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                // Value section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: context.fontSizeHeading,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: context.fontSizeXSmall,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // if (hasNotification)
                //   Container(
                //     width: 8,
                //     height: 8,
                //     decoration: const BoxDecoration(
                //       color: Color(0xFF2ECC71),
                //       shape: BoxShape.circle,
                //     ),
                //   ),
              ],
            ),

            const SizedBox(height: 8),

            // Title and details
            Text(
              title,
              style: TextStyle(
                fontSize: context.fontSizeMedium,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            if (total.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                total,
                style: TextStyle(
                  fontSize: context.fontSizeSmall,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RecentActionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> posts;
  Function(dynamic) formatToKg = Formatters.formatToKg;

  RecentActionsSection({super.key, required this.posts});

  String timeAgo(String? dateString) {
    if (dateString == null) return "-";

    try {
      final created = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inMinutes < 1) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      if (diff.inDays < 7) return "${diff.inDays}d ago";

      return DateFormat('dd MMM').format(created);
    } catch (_) {
      return "-";
    }
  }

  String buildSubtitle(Map<String, dynamic> item) {
    final qty = formatToKg(item["requiredqty"] ?? item["availableqty"] ?? 0);

    if (item["type"] == "Kernel") {
      return "${item["grade"] ?? "-"} - $qty";
    } else {
      return "${item["yearOfCrop"] ?? item["yearofcrop"] ?? "-"} RCN - $qty";
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedPosts = List<Map<String, dynamic>>.from(posts);

    sortedPosts.sort((a, b) {
      final aDate =
          DateTime.parse(a["created_on"] ?? "").toLocal() ?? DateTime(2000);
      final bDate =
          DateTime.parse(b["created_on"] ?? "").toLocal() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    final lastFour = sortedPosts.take(4).toList();

    if (lastFour.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translate.t("dashboard.recent_activity"),
              style: TextStyle(
                fontSize: context.fontSizeXXLarge,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 25),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.iconCashew,
                    width: MediaQuery.sizeOf(context).width * 0.2,
                    height: MediaQuery.sizeOf(context).width * 0.2,
                    color: AppColors.textHintLight,
                  ),
                  Text(
                    Translate.t("homeScreen.no_data"),
                    style: AppTextThemes.getLightTextTheme.titleLarge?.copyWith(
                      color: AppColors.textHintLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Translate.t("dashboard.recent_activity"),
                style: TextStyle(
                  fontSize: context.fontSizeXXLarge,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              // const SizedBox(height: 4),
              // Text(
              //   Translate.t(
              //     "dashboard.latest_postings",
              //   ).replaceAll("{count}", lastFour.length.toString()),
              //   style: TextStyle(
              //     fontSize: context.fontSizeSmall,
              //     color: AppColors.textSecondary,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ...lastFour.map((item) {
          final widget = Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ActionItem(
              onTap: () {
                String path = item["post_type"] != "stocks"
                    ? RoutePath.postBuyer
                    : RoutePath.postSeller;
                context.push(path, extra: '${item['_id']}');
              },
              icon: item["type"] == "Kernel"
                  ? AppAssets.iconKernel
                  : AppAssets.iconRcn,
              iconBackground: AppColors.primarySubtle,
              title: item["type"] == "Kernel"
                  ? "Kernel Stock Posted"
                  : "RCN Requirement Posted",
              subtitle: buildSubtitle(item),
              timeAgo: timeAgo(item["created_on"]),
              iconColor: AppColors.primary,
            ),
          );

          final isOffline =
              (item['isOffline'] == true) || (item['offlineQueueId'] != null);

          return isOffline ? Opacity(opacity: 0.5, child: widget) : widget;
        }).toList(),
      ],
    );
  }
}

class ActionItem extends StatelessWidget {
  final String icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String timeAgo;
  final Function()? onTap;
  final Color iconColor;

  const ActionItem({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.onTap,
    required this.subtitle,
    required this.timeAgo,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(icon, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: context.fontSizeSmall,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

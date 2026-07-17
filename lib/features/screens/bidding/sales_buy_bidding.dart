import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/Responsive/responsivea_context.dart';
import 'package:cashew_marketplace/core/utils/filters_dynamc.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/activity_page_controls.dart';
import 'package:cashew_marketplace/shared/widgets/bidding_card_widget.dart';
import 'package:cashew_marketplace/shared/widgets/custom.dart';
import 'package:cashew_marketplace/shared/widgets/custom_input.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SalesBuyBidding extends StatefulWidget {
  final String? type;

  const SalesBuyBidding({super.key, this.type});

  @override
  State<SalesBuyBidding> createState() => _SalesBuyBiddingState();
}

class _SalesBuyBiddingState extends State<SalesBuyBidding> {
  // =========================
  // Controllers
  // =========================

  final ScrollController _scrollController = ScrollController();
  late final ActivityFilterController _filterController;
  late final ActivitySortController _sortController;

  // =========================
  // State
  // =========================

  bool isLoading = false;
  bool isinit = true;
  bool isbothtype = true;
  bool isbothpost = true;
  bool isFromDashboard = false;

  bool _isFetchingMore = false;
  bool _isRequestRunning = false;
  bool _hasMoreData = true;

  String userId = "";

  String? currentRole = "";
  String? post_type;
  String? lastProductType;

  String selectedFilter = "All Listings";
  String _sortBy = "Ending soon";

  String selectedOrigin = "All";
  String selectedGrade = "All";

  String? type;
  String? origin;
  String? grade;

  String selectedPostFilter = "All"; // All / Sale / Purchase
  String? _postTypeRole; // null / "processor" / "buyer"

  Map<String, dynamic> userData = {};

  List<String> origins = ["All"];
  List<String> grades = ["All"];

  List<String> postTypes = ["All", "Sale", "Purchase"];
  List<String> productTypes = ["All Listings", "RCN", "Kernel"];
  // =========================
  // Lifecycle
  // =========================

  @override
  void initState() {
    super.initState();

    _setupInitialFilters();

    _filterController = ActivityFilterController()..setActivePage(0);
    _sortController = ActivitySortController()..setActivePage(0);

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _registerToolbarDrawers();
      _initializeAndLoadPosts();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _filterController.dispose();
    _sortController.dispose();

    super.dispose();
  }

  void _registerToolbarDrawers() {
    _filterController.register(0, _showFilterDrawer);
    _sortController.register(0, _showSortDrawer);
    _syncFilterIndicator();
    _syncSortIndicator();
  }

  // =========================
  // Initial Setup
  // =========================

  void _setupInitialFilters() {
    if (widget.type != null) {
      isFromDashboard = true;

      type = widget.type;

      selectedFilter = widget.type!;
    } else {
      selectedFilter = "All Listings";

      isbothtype = true;
    }
  }

  Future<void> _initializeAndLoadPosts({bool load = false}) async {
    try {
      _handleProviderChanges();
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      userData = await SecureStorageService.getUserData();

      userId = userData['_id'] ?? '';

      if (userId.isEmpty) {
        return;
      }

      await getPost(load: true);

      if (!mounted) return;

      final provider = context.read<BiddingPostProvider>();

      setState(() {
        origins = ["All", ...provider.origins];
        grades = ["All", ...provider.grades];
      });
    } catch (e, stackTrace) {
      debugPrint("Initialization Error: $e");

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text("Failed to initialize data")));
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // Provider Listener
  // =========================

  Future<void> _handleProviderChanges() async {
    if (!mounted) return;

    final role = context.read<SwapUserProvider>().swapedUser;
    final producttype = context.read<SwapUserProvider>().productType;
    setState(() {
      if (producttype == "Both") {
        isbothtype = true;
        type = null;
        selectedFilter = "All Listings";
      } else {
        type = producttype;
        isbothtype = false;
        setState(() {
          selectedFilter = producttype;
        });
      }
      if (role == "both") {
        isbothpost = true;
        post_type = null;
        selectedPostFilter = "All";
      } else {
        post_type = role == "buyer" ? "stocks" : "requirements";
        currentRole = post_type;
        isbothpost = false;
        selectedPostFilter = post_type ?? "All";
      }
    });

    _syncFilterIndicator();
  }

  // =========================
  // Scroll Pagination
  // =========================

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_isFetchingMore) return;

    if (!_hasMoreData) return;

    final extentAfter = _scrollController.position.extentAfter;

    if (extentAfter < 300) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    _isFetchingMore = true;

    await getPost(loadMore: true, load: true);

    _isFetchingMore = false;
  }

  // =========================
  // API Calls
  // =========================

  Future<void> getPost({bool loadMore = false, bool load = false}) async {
    if (_isRequestRunning) return;

    _isRequestRunning = true;

    try {
      if (userId.isEmpty) {
        userData = await SecureStorageService.getUserData();

        userId = userData['_id'] ?? '';
      }

      if (userId.isEmpty) return;

      final request = FilterRequest(userId: userId);

      final filterPayload = _handleFilter(request);

      await context.read<BiddingPostProvider>().postFetch(
        userId: userId,
        endpoint: "dataset/data/Marketplace",
        filterPayload: filterPayload,
        loadMore: loadMore,
      );

      if (!mounted) return;

      final provider = context.read<BiddingPostProvider>();

      final fetchedPosts = provider.post;

      if (loadMore && fetchedPosts.isEmpty) {
        _hasMoreData = false;
      }

      final org = context.read<BiddingPostProvider>().origins;
      final gr = context.read<BiddingPostProvider>().grades;
      final typ = context.read<BiddingPostProvider>().type;
      final posttyp = context.read<BiddingPostProvider>().posttype;
      if (isinit) {
        setState(() {
          if (origin == null) {
            origins = ["All", ...org];
          }
          if (grade == null) {
            grades = ["All", ...gr];
          }
          if (type == null || type == "All Listings") {
            productTypes = ["All Listings", ...typ];
          }
          if (post_type == null) {
            postTypes = ["All", ...posttyp];
          }
        });
        isinit = false;
      }
      _syncFilterIndicator();
    } catch (e, stackTrace) {
      debugPrint("Post Fetch Error: $e");

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text("Failed to load posts")));
    } finally {
      _isRequestRunning = false;
    }
  }

  Map<String, dynamic> _handleFilter(FilterRequest request) {
    final apiType = (type == null || type == "All Listings") ? null : type;

    return request.getBiddingBuyerPost(
      type: apiType,
      origin: origin,
      posttype: _postTypeRole,
      grade: grade,
    );
  }

  // =========================
  // Helpers
  // =========================

  void _updateFilter(String filterName) {
    final displayName = filterName == "Both" ? "All Listings" : filterName;

    final typeValue = filterName == "Both" || filterName == "All Listings"
        ? null
        : filterName;

    setState(() {
      selectedFilter = displayName;

      type = typeValue;
    });
    // origin = null;
    // grade = null;
    // selectedOrigin = "All";
    // selectedGrade = 'All';
    // getPost(load: true);
    _syncFilterIndicator();
  }

  bool get _hasActiveFilters {
    return selectedFilter != "All Listings" || origin != null || grade != null;
  }

  void _syncFilterIndicator() {
    _filterController.setPageHasActiveFilter(0, _hasActiveFilters);
  }

  void _syncSortIndicator() {
    _sortController.setPageHasActiveFilter(0, _sortBy != "Ending soon");
  }

  DateTime? _parseDate(dynamic rawDate) {
    if (rawDate == null) return null;

    return DateTime.tryParse(rawDate.toString());
  }

  List<dynamic> _getValidPosts(List<dynamic> posts) {
    final now = DateTime.now().toUtc();

    return posts.where((post) {
      final rawDate = post['expiredate'] ?? post["deliverydate"];

      final close = _parseDate(rawDate);

      if (close == null) return false;

      return close.toUtc().isAfter(now);
    }).toList();
  }

  List<dynamic> _sortPosts(List<dynamic> posts) {
    final sorted = List<dynamic>.from(posts);

    int compareCloseDate(dynamic a, dynamic b) {
      final left = _parseDate(a['expiredate'] ?? a["deliverydate"]);
      final right = _parseDate(b['expiredate'] ?? b["deliverydate"]);
      final result = (left ?? DateTime(9999)).compareTo(
        right ?? DateTime(9999),
      );
      return _sortBy == "Ending soon" ? result : -result;
    }

    sorted.sort(compareCloseDate);
    return sorted;
  }

  Future<void> _onRefresh() async {
    _hasMoreData = true;

    await getPost();
  }

  void _resetFilters() async {
    setState(() {
      selectedPostFilter = "All";
      _postTypeRole = null;
      selectedFilter = "All Listings";
      type = null;
      origin = null;
      grade = null;
      selectedOrigin = "All";
      selectedGrade = "All";
    });
    await getPost(load: true);
    filter("productTypes");
    _syncFilterIndicator();
  }

  void _showFilterDrawer() {
    ActivityFilterDrawer.show(
      context: context,
      title: "Filters",
      onReset: _resetFilters,
      contentBuilder: (context, refresh) => _buildFilterDrawerContent(refresh),
    );
  }

  void _showSortDrawer() {
    ActivityFilterDrawer.show(
      context: context,
      title: "Sort",
      headerIcon: Icons.swap_vert,
      onReset: () {
        setState(() => _sortBy = "Ending soon");
        _syncSortIndicator();
      },
      contentBuilder: (context, refresh) => _buildSortDrawerContent(refresh),
    );
  }

  Widget _buildSortDrawerContent([VoidCallback? refreshDrawer]) {
    return ActivityDrawerField(
      icon: Icons.sort_rounded,
      label: "Sort By",
      child: Column(
        children: [
          RadioListTile<String>(
            value: "Ending soon",
            groupValue: _sortBy,
            onChanged: (value) {
              _updateSort(value);
              refreshDrawer?.call();
            },
            title: const Text("Ending soon"),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: "Ending later",
            groupValue: _sortBy,
            onChanged: (value) {
              _updateSort(value);
              refreshDrawer?.call();
            },
            title: const Text("Ending later"),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void filter(String exludedfilter) {
    final org = context.read<BiddingPostProvider>().origins;
    final gr = context.read<BiddingPostProvider>().grades;
    final typ = context.read<BiddingPostProvider>().type;
    final posttyp = context.read<BiddingPostProvider>().posttype;
    final filters = FiltersDynamic.getFilters(exludedfilter, [
      org,
      gr,
      typ,
      posttyp,
    ]);

    if (exludedfilter != "origins") {
      origins = ["All", ...org];
    }
    if (exludedfilter != "grades") {
      grades = ["All", ...gr];
    }
    if (exludedfilter != "productTypes") {
      productTypes = ["All Listings", ...typ];
    }
    if (exludedfilter != "postTypes") {
      postTypes = ["All", ...posttyp];
      if (_postTypeRole == "stocks") {
        selectedPostFilter = "Sale";
      } else if (_postTypeRole == "requirements") {
        selectedPostFilter = "Purchase";
      }
    }
  }

  void _updateSort(String? value) {
    if (value == null) return;
    setState(() => _sortBy = value);
    _syncSortIndicator();
  }

  Widget _buildFilterDrawerContent([VoidCallback? refreshDrawer]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isbothtype && isbothpost) ...[
          Container(
            padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary, width: 1),
            ),
            child: Text(
              type ?? "",
              style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // POST TYPE filter
        if (isbothpost) ...[
          ActivityDrawerField(
            icon: Icons.swap_horiz_rounded,
            label: "Post Type",
            child: CustomDropdownFormField<String>(
              label: "Post Type",
              value: selectedPostFilter,
              items: postTypes,
              labels: postTypes,
              onChanged: (val) async {
                setState(() {
                  selectedPostFilter = val ?? "All";
                  if (val == "Sale") {
                    _postTypeRole = "stocks";
                  } else if (val == "Purchase") {
                    _postTypeRole = "requirements";
                  } else {
                    _postTypeRole = null;
                  }
                });
                await getPost();
                filter("postTypes");
                _syncFilterIndicator();
                refreshDrawer?.call();
              },
            ),
          ),
        ] else ...[
          Row(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Text(
                  currentRole == 'stocks'
                      ? "Sale"
                      : currentRole == 'requirements'
                      ? "Purchase"
                      : "",
                  style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (!isbothtype)
                Container(
                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary, width: 1),
                  ),
                  child: Text(
                    type == "RCN" ? Translate.t("filter.rcn") : (type == "Kernel" ? Translate.t("filter.kernel") : (type ?? "")),
                    style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (isbothtype) ...[
          ActivityDrawerField(
            icon: Icons.inventory_2_outlined,
            label: Translate.t("button.select"),
            child: CustomDropdownFormField<String>(
              label: Translate.t("button.select"),
              value: selectedFilter,
              items: productTypes,
              labels: productTypes.map((t) => t == "RCN" ? Translate.t("filter.rcn") : (t == "Kernel" ? Translate.t("filter.kernel") : t)).toList(),
              onChanged: (value) async {
                if (value != null) {
                  _updateFilter(value);
                  await getPost();
                  filter("productTypes");
                  refreshDrawer?.call();
                }
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        ActivityDrawerField(
          icon: Icons.public_rounded,
          label: "Origin",
          child: CustomDropdownFormField<String>(
            label: "Origin",
            value: selectedOrigin,
            items: origins,
            labels: origins,
            onChanged: (value) async {
              setState(() {
                selectedOrigin = value!.toString();
                origin = value == "All" ? null : value;
              });
              await getPost();
              filter("origins");
              _syncFilterIndicator();
              refreshDrawer?.call();
            },
          ),
        ),
        if (type != 'RCN') ...[
          const SizedBox(height: 16),
          ActivityDrawerField(
            icon: Icons.grade_outlined,
            label: "Grade",
            child: CustomDropdownFormField<String>(
              label: "Grade",
              value: selectedGrade,
              items: grades,
              labels: grades,
              onChanged: (value) async {
                setState(() {
                  selectedGrade = value!.toString();
                  grade = value == "All" ? null : value;
                });
                await getPost();
                filter("grades");
                _syncFilterIndicator();
                refreshDrawer?.call();
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        ActivityActiveFilters(
          chips: [
            if (isbothpost && selectedPostFilter != "All")
              ActivityActiveFilterChip(
                label: "Post Type: $selectedPostFilter",
                onRemove: () {
                  selectedPostFilter = "All";
                  _postTypeRole = null;
                  getPost();
                  _syncFilterIndicator();
                  refreshDrawer?.call();
                },
              ),
            if (isbothtype && selectedFilter != "All Listings")
              ActivityActiveFilterChip(
                label: "Product Type: $selectedFilter",
                onRemove: () {
                  _updateFilter("All Listings");
                  getPost();
                  _syncFilterIndicator();
                  refreshDrawer?.call();
                },
              ),
            if (origin != null)
              ActivityActiveFilterChip(
                label: "Origin: $origin",
                onRemove: () {
                  setState(() {
                    origin = null;
                    selectedOrigin = "All";
                  });
                  getPost();
                  _syncFilterIndicator();
                  refreshDrawer?.call();
                },
              ),
            if (grade != null)
              ActivityActiveFilterChip(
                label: "Grade: $grade",
                onRemove: () {
                  setState(() {
                    grade = null;
                    selectedGrade = "All";
                  });
                  getPost();
                  _syncFilterIndicator();
                  refreshDrawer?.call();
                },
              ),
          ],
        ),
      ],
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<BiddingPostProvider>(
        builder: (context, biddingProvider, child) {
          final posts = biddingProvider.post;
          final filteredPosts = biddingProvider.post.where((e) {
            final apiType = (type == null || type == 'All Listings')
                ? null
                : type;
            if (apiType != null && e['type']?.toString() != apiType)
              return false;
            if (_postTypeRole != null &&
                e['post_type']?.toString() != _postTypeRole)
              return false;
            if (origin != null && e['origin']?.toString() != origin)
              return false;
            if (grade != null && e['grade']?.toString() != grade) return false;
            return true;
          }).toList();
          final validPosts = _sortPosts(_getValidPosts(filteredPosts));

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _onRefresh,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    // border: Border(
                    //   bottom: BorderSide(
                    //     color: AppColors.primaryDark,
                    //     width: 1,
                    //   ),
                    // ),
                  ),
                  child: ActivityPageToolbar(
                    selectedPage: 0,
                    pages: [
                      ActivityPageOption(
                        value: 0,
                        label: Translate.t("tabs.ending_bids"),
                        icon: Icons.gavel_outlined,
                      ),
                    ],
                    filterController: _filterController,
                    sortController: _sortController,
                    onPageChanged: (_) {},
                  ),
                ),

                if (isLoading && biddingProvider.post.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ] else if (validPosts.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: Text(
                        Translate.t("homeScreen.no_data"),
                        style: AppTextThemes.getgetLightTextTheme(
                          context,
                        ).bodyMedium,
                      ),
                    ),
                  ),
                ] else ...[
                  _buildBiddingSection(context, validPosts),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBiddingSection(BuildContext context, List<dynamic> posts) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekEnd = now.add(Duration(days: 7 - now.weekday));
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

    final Map<String, List<dynamic>> groups = {
      'Today': [],
      'This Week': [],
      'This Month': [],
      'This Year': [],
    };

    for (final post in posts) {
      final close = _parseDate(post['expiredate'] ?? post['deliverydate']);
      if (close == null) continue;
      if (!close.isAfter(todayEnd)) {
        groups['Today']!.add(post);
      } else if (!close.isAfter(weekEnd)) {
        groups['This Week']!.add(post);
      } else if (!close.isAfter(monthEnd)) {
        groups['This Month']!.add(post);
      } else if (!close.isAfter(yearEnd)) {
        groups['This Year']!.add(post);
      }
    }

    final columns = context.isMobile
        ? 2
        : context.isTablet
        ? 3
        : 3;

    return Expanded(
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: context.h(16),
          vertical: context.v(10),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: groups.entries.where((e) => e.value.isNotEmpty).map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.key.toUpperCase(),
                      style: AppTextThemes.getgetLightTextTheme(context).labelSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Divider(color: AppColors.accent)),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: context.isMobile ? 1 : 1,
                  mainAxisSpacing: context.v(10),
                  crossAxisSpacing: context.h(10),
                ),
                itemCount: entry.value.length,
                itemBuilder: (context, index) {
                  final post = entry.value[index];
                  final close = _parseDate(
                    post['expiredate'] ?? post['deliverydate'],
                  );
                  final isStock = post['post_type'] == 'stocks';
                  final cardColor = isStock
                      ? AppColors.sellerCardBg
                      : AppColors.buyerCardBg;
                  return BiddingCardsWidget(
                    color: cardColor,
                    // posttype: post['post_type']?.toString(),
                    onPlaceBid: () async {
                      final path = isStock
                          ? RoutePath.viewscreen
                          : RoutePath.sellerviewscreen;
                      await context.push(path, extra: post['_id']);
                      if (!mounted) return;
                      await getPost();
                    },
                    title:
                        "${post['grade'] == 'RCN' ? '' : post['grade'] ?? ''} "
                        "${post['yearOfCrop'] ?? post['yearofcrop'] ?? ''} "
                        "${post['type'] == 'RCN' ? Translate.t('filter.rcn') : (post['type'] == 'Kernel' ? Translate.t('filter.kernel') : post['type'])}",
                    subtitle: post['origin'] ?? '',
                    closingIn: close ?? DateTime.now(),
                    qty: Formatters.formatToKg(
                      post['requiredqty'] ?? post['availableqty'] ?? 0,
                    ),
                  );
                },
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

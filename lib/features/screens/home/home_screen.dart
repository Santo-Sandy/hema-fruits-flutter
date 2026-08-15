import 'dart:async';

import 'package:hema_fruits/core/constants/app_assets.dart';
import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/providers/swap_user_provider.dart';

import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/services/translate.dart' show Translate;
import 'package:hema_fruits/core/utils/Responsive/responsivea_context.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/filters_dynamc.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/core/utils/stream_refresher.dart';
import 'package:hema_fruits/features/layouts/skeleton_loader.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/custom.dart';
import 'package:hema_fruits/shared/widgets/custom_input.dart';
import 'package:hema_fruits/shared/widgets/filter_widgets.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  final String? type;

  const HomeScreen({super.key, required this.initialTab, this.type});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeTabFilterState {
  String selectedFilter = "All Listings";
  String selectedPostFilter = "All";
  String date = Translate.t("homeScreen.select_date");
  String? type;
  String? currentRole;
  String? startDate;
  String? endDate;
  String? origin;
  String? originvalue = 'All';
  String? search;

  void applyRouteType(String? routeType) {
    if (routeType == "RCN" || routeType == "Kernel") {
      type = routeType;
      selectedFilter = routeType ?? "All Listings";
      return;
    }

    type = null;
    selectedFilter = "All Listings";
  }

  void applyProductType(String? productType) {
    if (productType == null || productType == "Both") {
      type = null;
      selectedFilter = "All Listings";
      return;
    }

    type = productType;
    selectedFilter = productType;
  }

  void applyRole(String role) {
    if (role == "both") {
      currentRole = null;
      selectedPostFilter = "All";
      return;
    }

    if (role == "buyer") {
      currentRole = "stocks";
      selectedPostFilter = "Sale";
    } else {
      currentRole = "requirements";
      selectedPostFilter = "Purchase";
    }
  }

  void resetPrimaryFilters() {
    selectedPostFilter = "All";
    currentRole = null;
    selectedFilter = "All Listings";
    type = null;
  }

  void resetAll() {
    resetPrimaryFilters();
    origin = null;
    originvalue = 'All';
    startDate = null;
    endDate = null;
    date = Translate.t("homeScreen.select_date");
    search = null;
  }

  bool get hasActiveFilter {
    return currentRole != null ||
        type != null ||
        origin != null ||
        (startDate != null && startDate!.isNotEmpty) ||
        (search != null && search!.isNotEmpty);
  }
}

class _HomeScreen extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  bool isFilter = false;
  bool isLoading = true;
  Map<String, dynamic> userData = {};
  String userId = "";
  bool isbothtype = true;
  bool isbothpost = true;
  final ScrollController _scrollController = ScrollController();
  final List<_HomeTabFilterState> _tabFilters = List.generate(
    3,
    (_) => _HomeTabFilterState(),
  );
  bool _isFromDashboard = false;
  bool is_init = true;
  bool isinit = true;
  bool isinits = true;
  bool isviewed = false;
  bool refresh = false;
  bool iscomplete = false;
  int tab = 0;
  Map<String, dynamic> Settings = {};
  Function(dynamic) formatToKg = Formatters.formatToKg;
  Function(dynamic) formatToMoney = Formatters.formatTomoney;
  TextEditingController searchController = TextEditingController();
  List<String> origins = [
    "All",
    "India",
    "Vietnam",
    "Ivory Coast",
    "Nigeria",
    "Ghana",
  ];
  List<String> postTypes = ["All", "Sale", "Purchase"];
  List<String> productTypes = ["All Listings", "RCN", "Kernel"];
  String? _lastProductType;

  bool _filterDrawerOpen = false;

  _HomeTabFilterState get _activeFilter => _tabFilters[_currentIndex];

  _HomeTabFilterState _filterForTab(int index) => _tabFilters[index];

  // Sync the active filter to all tabs so the drawer applies globally.
  void _syncFiltersToAllTabs() {
    final src = _activeFilter;
    for (final f in _tabFilters) {
      f.type = src.type;
      f.selectedFilter = src.selectedFilter;
      f.currentRole = src.currentRole;
      f.selectedPostFilter = src.selectedPostFilter;
      f.origin = src.origin;
      f.originvalue = src.originvalue;
      f.startDate = src.startDate;
      f.endDate = src.endDate;
      f.date = src.date;
      f.search = src.search;
    }
  }

  String get selectedFilter => _activeFilter.selectedFilter;
  set selectedFilter(String value) => _activeFilter.selectedFilter = value;

  String get selectedPostFilter => _activeFilter.selectedPostFilter;
  set selectedPostFilter(String value) =>
      _activeFilter.selectedPostFilter = value;

  String get date => _activeFilter.date;
  set date(String value) => _activeFilter.date = value;

  String? get type => _activeFilter.type;
  set type(String? value) => _activeFilter.type = value;

  String? get currentRole => _activeFilter.currentRole;
  set currentRole(String? value) => _activeFilter.currentRole = value;

  String? get startDate => _activeFilter.startDate;
  set startDate(String? value) => _activeFilter.startDate = value;

  String? get endDate => _activeFilter.endDate;
  set endDate(String? value) => _activeFilter.endDate = value;

  String? get origin => _activeFilter.origin;
  set origin(String? value) => _activeFilter.origin = value;

  String? get originvalue => _activeFilter.originvalue;
  set originvalue(String? value) => _activeFilter.originvalue = value;

  String? get search => _activeFilter.search;
  set search(String? value) => _activeFilter.search = value;
  late StreamSubscription _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = AppEvents.postRefreshController.stream.listen((_) {
      getPost();
    });
    _currentIndex = widget.initialTab;
    // Keep search controller in sync with active filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => searchController.text = _activeFilter.search ?? '');
      _refreshDynamicFilters();
    });

    if (widget.type != null) {
      _isFromDashboard = true;
      for (final filter in _tabFilters) {
        filter.applyRouteType(widget.type);
      }
    } else {
      for (final filter in _tabFilters) {
        filter.applyRouteType(null);
      }
      isbothtype = true;
    }

    _scrollController.addListener(() {
      if (!mounted) return;

      final provider = context.read<PostProvider>();

      final isNearBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200;

      if (!isNearBottom) return;

      switch (_currentIndex) {
        case 0: // New
          if (provider.hasMoreNew &&
              !provider.isFetchingMoreNew &&
              !provider.loading) {
            getPost(loadMore: true, load: true);
          }
          break;

        case 1: // Viewed
          if (provider.hasMoreViewed &&
              !provider.isFetchingMoreViewed &&
              !provider.loading) {
            getPost(loadMore: true, load: true);
          }
          break;

        case 2: // Favorite
          if (provider.hasMoreFavorite &&
              !provider.isFetchingMoreFavorite &&
              !provider.loading) {
            getPost(loadMore: true, load: true);
          }
          break;
      }
    });

    _initializeAndLoadPosts();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.type != widget.type) {
      setState(() {
        _applyRouteType(widget.type);
      });
      getPost(load: true);
    }

    // Sync route query parameter ?tab=X to local index state
    final routeState = GoRouterState.of(context);
    final tabParam = routeState.uri.queryParameters['tab'];
    if (tabParam != null) {
      final targetTabIndex = int.tryParse(tabParam) ?? 0;
      if (_currentIndex != targetTabIndex &&
          targetTabIndex < _tabFilters.length) {
        setState(() {
          _currentIndex = targetTabIndex;
        });
        getPost(load: true);
        loadSettings();
      }
    }
  }

  Future<void> loadSettings() async {
    try {
      final setting = await context.read<Settingsprovider>().settingsfetch(
        endpoint: "entities/filter/settings",
        filterPayload: {},
      );
      if (setting.isNotEmpty) {
        await SettingsLocalRepository.instance.clearAdminSettings();
        await SettingsLocalRepository.instance.saveAdminSettings(setting);
      }
      setState(() {
        Settings = setting;
      });
    } catch (e) {
      debugPrint("$e");
    } finally {
      setState(() {
        Settings = SettingsLocalRepository.instance.getAdminSettings();
      });
    }
  }

  void _applyRouteType(String? routeType) {
    for (final filter in _tabFilters) {
      filter.applyRouteType(routeType);
    }

    if (routeType == "RCN" || routeType == "Kernel") {
      _isFromDashboard = true;
      return;
    }

    _isFromDashboard = false;
  }

  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final role = context.watch<SwapUserProvider>().swapedUser;
    final producttype = context.watch<SwapUserProvider>().productType;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final hasProductTypeChanged = _lastProductType != producttype;
      if (hasProductTypeChanged) {
        _lastProductType = producttype;
        setState(() {
          if (producttype == "Both") {
            isbothtype = true;
            if (widget.type == null) {
              for (final filter in _tabFilters) {
                filter.applyProductType(producttype);
              }
            }
          } else {
            isbothtype = false;
            if (widget.type == null) {
              for (final filter in _tabFilters) {
                filter.applyProductType(producttype);
              }
            }
          }

          if (role == "both") {
            isbothpost = true;
          } else {
            isbothpost = false;
          }
          for (final filter in _tabFilters) {
            filter.applyRole(role);
          }

          _isFromDashboard = false;
        });
      }
    });
  }

  Timer? _debounce;

  Future<void> _initializeAndLoadPosts() async {
    try {
      userData = await SecureStorageService.getUserData();
      userId = userData['_id']?.toString() ?? '';
      await check();
      // if (userId.isNotEmpty) {
      //   await getUser(userId);
      // }
      if (userId.isNotEmpty) {
        await getPost(load: true);
      }
    } catch (e) {
      debugPrint('Error initializing home screen: $e');
      if (mounted) {
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<bool> check() async {
    userData = await SecureStorageService.getUserData();
    final points = (userData['points'] as int?) ?? 0;

    final int requiredPoints =
        int.tryParse(Settings['EnquiresDetectionPoint']?.toString() ?? '') ?? 0;
    if (userData['points'] == null &&
        (userData['natureOfBusiness'] != 'Agent' ||
            userData['natureOfBusiness'] == null)) {
      showCompleteProfilePopup(
        context,
        userData['natureOfBusiness'] == null
            ? Translate.t("popup.profile_update")
            : Translate.t("popup.business_profile_update"),
        userData['natureOfBusiness'] == null
            ? Translate.t("popup.go_to_profile")
            : Translate.t("popup.go_to_business_profile"),
        userData['natureOfBusiness'] == null
            ? RoutePath.personalInfo
            : RoutePath.businessInfo,
      );
      return true;
    }
    if (_currentIndex == 0 || _currentIndex == 2) isviewed = true;
    isinit = false;

    return false;
  }

  Future<void> getviewedpost(
    bool loadMore,
    FilterRequest request, {
    _HomeTabFilterState? filter,
    bool suppressLoading = false,
  }) async {
    final tabFilter = filter ?? _filterForTab(1);
    await context.read<PostProvider>().viewedpostFetch(
      userId: userId,
      endpoint: "dataset/data/Marketplace",
      filterPayload: request.getBuyerPost(
        role: tabFilter.currentRole,
        type: _apiType(tabFilter),
        origin: tabFilter.origin,
        search: tabFilter.search,
        fromDate: tabFilter.startDate,
        toDate: tabFilter.endDate,
        view: "true",
      ),
      loadMore: loadMore,
      suppressLoading: suppressLoading,
    );
  }

  Future<void> getfavoritepost(
    bool loadMore,
    FilterRequest request, {
    _HomeTabFilterState? filter,
    bool suppressLoading = false,
  }) async {
    final tabFilter = filter ?? _filterForTab(2);
    await context.read<PostProvider>().favoritepostFetch(
      userId: userId,
      endpoint: "dataset/data/Marketplace",
      filterPayload: request.getBuyerPost(
        role: tabFilter.currentRole,
        type: _apiType(tabFilter),
        origin: tabFilter.origin,
        search: tabFilter.search,
        fromDate: tabFilter.startDate,
        toDate: tabFilter.endDate,
        fav: "true",
      ),
      loadMore: loadMore,
      suppressLoading: suppressLoading,
    );
  }

  Future<void> getnewpost(
    bool loadMore,
    Map<String, dynamic> filterPayload, {
    bool suppressLoading = false,
  }) async {
    await context.read<PostProvider>().postFetch(
      userId: userId,
      endpoint: "dataset/data/Marketplace",
      filterPayload: filterPayload,
      loadMore: loadMore,
      suppressLoading: suppressLoading,
    );
  }

  Future<void> getPost({
    bool loadMore = false,
    int? cur_tab,
    bool? viewed,
    bool load = false,
    bool refreshDynamicFilters = true,
    bool suppressLoading = false,
  }) async {
    try {
      if (userId.isEmpty) {
        userData = await SecureStorageService.getUserData();
        userId = (userData['_id'] ?? '').toString();

        // userId is always a String for non-null assignments
      }

      final request = FilterRequest(userId: userId);
      final newPostFilter = _handleFilter(request, tabIndex: 0);
      final activeFilter = _handleFilter(request, tabIndex: _currentIndex);

      final currentTab = _currentIndex;
      if (loadMore) {
        if (currentTab == 0) {
          await getnewpost(
            true,
            activeFilter,
            suppressLoading: suppressLoading,
          );
        } else if (currentTab == 1) {
          await getviewedpost(
            true,
            request,
            filter: _filterForTab(1),
            suppressLoading: suppressLoading,
          );
        } else if (currentTab == 2) {
          await getfavoritepost(
            true,
            request,
            filter: _filterForTab(2),
            suppressLoading: suppressLoading,
          );
        }
        loadMore = false;
      } else {
        if (currentTab == 0) {
          await getnewpost(
            false,
            activeFilter,
            suppressLoading: suppressLoading,
          );
        } else if (currentTab == 1) {
          await getviewedpost(
            false,
            request,
            filter: _filterForTab(1),
            suppressLoading: suppressLoading,
          );
        } else if (currentTab == 2) {
          await getfavoritepost(
            false,
            request,
            filter: _filterForTab(2),
            suppressLoading: suppressLoading,
          );
        }
      }
      // } else {
      //   if (cur_tab == 0) {
      //     await getnewpost(role, false, filterPayload);
      //   } else if (cur_tab == 1) {
      //     await getviewedpost(role, false, request);
      //   } else if (cur_tab == 2) {
      //     await getfavoritepost(role, false, request);
      //   }
      // }

      // if (tab == 1 || is_init || isviewed) {
      //   await getviewedpost(role, loadMore, request);
      //   isviewed = false;
      // }
      // if (tab == 2 || is_init) {
      //   await getfavoritepost(role, loadMore, request);
      // }
      // if (tab == 0 || is_init || isviewed) {
      //   await getnewpost(role, loadMore, filterPayload);
      //   isviewed = false;
      // }
      // is_init = true;
      if (refreshDynamicFilters) {
        _refreshDynamicFilters();
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (mounted) {
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    }
  }

  void filter(String exludedfilter) {
    _refreshDynamicFilters(excludedFilter: exludedfilter);
  }

  void _refreshDynamicFilters({String? excludedFilter}) {
    if (!mounted) return;

    final provider = context.read<PostProvider>();
    final posts = _postsForActiveTab(provider);
    final filters = FiltersDynamic.getFilters(excludedFilter ?? "", [
      _originsFromPosts(posts),
      <String>[],
      _typesFromPosts(posts),
      _postTypesFromPosts(posts),
    ]);

    setState(() {
      if (excludedFilter != "origins") {
        origins = List<String>.from(filters[0]);
      }
      if (excludedFilter != "productTypes") {
        productTypes = List<String>.from(filters[2]);
      }
      if (excludedFilter != "postTypes") {
        postTypes = List<String>.from(filters[3]);
        if (currentRole == "stocks") {
          selectedPostFilter = "Sale";
        } else if (currentRole == "requirements") {
          selectedPostFilter = "Purchase";
        }
      }
      isinits = false;
    });
  }

  List<dynamic> _postsForActiveTab(PostProvider provider) {
    switch (_currentIndex) {
      case 1:
        return provider.viewedpost;
      case 2:
        return provider.favoritepost;
      default:
        return provider.post;
    }
  }

  List<String> _originsFromPosts(List<dynamic> posts) {
    return posts
        .where((post) => post["origin"] != null)
        .map<String>((post) => post["origin"].toString())
        .toSet()
        .toList();
  }

  List<String> _typesFromPosts(List<dynamic> posts) {
    return posts
        .where((post) => post["type"] != null)
        .map<String>((post) => post["type"].toString())
        .toSet()
        .toList();
  }

  List<String> _postTypesFromPosts(List<dynamic> posts) {
    return posts
        .where((post) => post["post_type"] != null)
        .map<String>(
          (post) =>
              post["post_type"].toString() == "stocks" ? "Sale" : "Purchase",
        )
        .toSet()
        .toList();
  }

  Future<void> action({
    required String id,
    required String action,
    bool? status,
  }) async {
    try {
      String endpoint = "capitalmarket/stocks/$id/$action";
      await context.read<PostProvider>().action(
        endpoint,
        status,
        id,
        action,
        userId,
      );
      // await getPost();
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  String? _apiType(_HomeTabFilterState filter) {
    return (filter.type == null || filter.type == "All Listings")
        ? null
        : filter.type;
  }

  Map<String, dynamic> _handleFilter(FilterRequest request, {int? tabIndex}) {
    final filter = tabIndex == null ? _activeFilter : _filterForTab(tabIndex);

    return request.getBuyerPost(
      role: filter.currentRole,
      type: _apiType(filter),
      origin: filter.origin,
      search: filter.search,
      fromDate: filter.startDate,
      toDate: filter.endDate,
    );
  }

  void _updateFilter(String filterName) {
    final displayName = filterName == "Both" ? "All Listings" : filterName;
    final typeValue = filterName == "Both" || filterName == "All Listings"
        ? null
        : filterName;
    setState(() {
      selectedFilter = displayName;
      type = typeValue;
      // origin = null;
      // originvalue = 'All';
      // startDate = null;
      // endDate = null;
      // date = "Select Date";
    });
    _applyDynamicFilterChange("productTypes");
  }

  Future<void> _applyDynamicFilterChange(String excludedFilter) async {
    await getPost(load: true, refreshDynamicFilters: false);
    filter(excludedFilter);
  }

  String _formatUtcIso(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    showCustomDateRangePicker(
      context,
      dismissible: true,
      minimumDate: DateTime.now().subtract(const Duration(days: 3000)),
      maximumDate: DateTime.now().add(const Duration(days: 3000)),
      backgroundColor: AppColors.surfaceLight,
      primaryColor: AppColors.primary,
      onApplyClick: (start, end) {
        if (!mounted) return;
        setState(() {
          endDate = _formatUtcIso(end.add(const Duration(days: 1)));
          startDate = _formatUtcIso(start);
          date =
              "${DateFormat('dd-MM-yyyy').format(start)} - ${DateFormat('dd-MM-yyyy').format(end)}";
          _syncFiltersToAllTabs();
        });
        _applyDynamicFilterChange("");
      },
      onCancelClick: () {
        setState(() {
          endDate = null;
          startDate = null;
          date = "Select Date";
          _syncFiltersToAllTabs();
        });
        _applyDynamicFilterChange("");
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _subscription.cancel();
    _scrollController.dispose();
    // _tab.dispose(); // Commented out as _tab is not defined in this context
    searchController.dispose();
    super.dispose();
  }

  List<dynamic> post = [];
  List<dynamic> viewed = [];
  List<dynamic> favorite = [];
  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    ContextManager().saveCurrentPage('home', context);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth > 768 ? 360.0 : screenWidth * 0.82;

    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // OLD TAB BAR → replaced by dropdown navigation
            // _buildStylishTabBar(context),

            // NEW: pill-dropdown + filter button row
            _buildNewTabNavigation(context),

            // _buildFilterSection(context),
            Expanded(
              child: Consumer<PostProvider>(
                builder: (context, provider, child) {
                  if (isLoading &&
                      (provider.post.isEmpty ||
                          provider.viewedpost.isEmpty ||
                          provider.favoritepost.isEmpty)) {
                    return _buildLoadingState(context);
                  }

                  if (provider.post.isNotEmpty) {
                    post = provider.post;
                  }
                  if (provider.viewedpost.isNotEmpty) {
                    viewed = provider.viewedpost;
                  }
                  if (provider.favoritepost.isNotEmpty) {
                    favorite = provider.favoritepost;
                  }
                  if (provider.post.isEmpty && _currentIndex == 0) {
                    _currentIndex = 1;
                    getPost();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await getPost();
                    },
                    child: IndexedStack(
                      index: _currentIndex,
                      children: [
                        _buildPostsList(
                          context,
                          provider.post,
                          hasMore: provider.hasMoreNew,
                          filter: _filterForTab(0),
                        ),
                        _buildPostsList(
                          context,
                          provider.viewedpost,
                          hasMore: provider.hasMoreViewed,
                          filter: _filterForTab(1),
                        ),
                        _buildPostsList(
                          context,
                          provider.favoritepost,
                          hasMore: provider.hasMoreFavorite,
                          filter: _filterForTab(2),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // ── Backdrop ─────────────────────────────────────
        AnimatedOpacity(
          opacity: _filterDrawerOpen ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 260),
          child: IgnorePointer(
            ignoring: !_filterDrawerOpen,
            child: GestureDetector(
              onTap: () => setState(() => _filterDrawerOpen = false),
              child: Container(color: Colors.black.withOpacity(0.38)),
            ),
          ),
        ),

        // ── Slide-in filter drawer ────────────────────────
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          right: _filterDrawerOpen ? 0 : -drawerWidth,
          top: 0,
          bottom: 0,
          width: drawerWidth,
          child: _buildFilterDrawerPanel(context),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════
  // NEW: Tab navigation row
  // ════════════════════════════════════════════════════════

  Widget _buildNewTabNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildTabDropdown(context),
          const Spacer(),
          _buildFilterToggleButton(context),
        ],
      ),
    );
  }

  /// Pill-shaped dropdown button that shows the active tab.
  /// All 3 tabs are always shown in the popup; the active one has a check.
  Widget _buildTabDropdown(BuildContext context) {
    final List<Map<String, dynamic>> tabItems = [
      {
        'icon': Icons.fiber_new_rounded,
        'label': Translate.t("homeScreen.new"),
        'index': 0,
      },
      {
        'icon': Icons.visibility_outlined,
        'label': Translate.t("homeScreen.viewed"),
        'index': 1,
      },
      {
        'icon': Icons.favorite_border_rounded,
        'label': Translate.t("homeScreen.favorite"),
        'index': 2,
      },
    ];

    final currentItem = tabItems[_currentIndex];

    return PopupMenuButton<int>(
      onSelected: (index) {
        // Update URL so other layout components can sync via query param
        context.go('${RoutePath.home}?tab=$index');
        setState(() {
          _currentIndex = index;
          searchController.text = _activeFilter.search ?? '';
        });
        getPost(load: true);
      },
      color: AppColors.background,
      elevation: 6,
      shadowColor: AppColors.borderLight.withAlpha(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      offset: const Offset(0, 46),
      // ── Popup items ──
      itemBuilder: (context) => tabItems.map((tab) {
        final isSelected = tab['index'] == _currentIndex;
        return PopupMenuItem<int>(
          value: tab['index'] as int,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(20)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tab['icon'] as IconData,
                  size: 17,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tab['label'] as String,
                  style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
      // ── Trigger pill ──
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // color: AppColors.background.withAlpha(16),
          // borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.background.withAlpha(80),
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentItem['icon'] as IconData,
              size: 24,
              color: AppColors.background,
            ),
            const SizedBox(width: 7),
            Text(
              currentItem['label'] as String,
              style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
                color: AppColors.background,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: AppColors.background.withAlpha(80),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildBothFilterPanel(BuildContext context) {
  //   return Padding(
  //     padding: ResponsiveContext(context).screenPadding,
  //     child: searchWidget(
  //       Dropdownlabel: Translate.t("homeScreen.origin"),
  //       searchController: searchController,
  //       origins: origins,
  //       date: date,
  //       onChangedDate: () {
  //         _pickDateRange(context);
  //       },
  //       onChangedOrigin: (value) {
  //         if (value == "All") {
  //           origin = null;
  //         } else {
  //           origin = value;
  //         }
  //         getPost();
  //       },
  //       onChangedSearch: (value) {
  //         search = value;
  //         getPost();
  //       },
  //     ),
  //   );
  // }
  /// Filter toggle button — opens/closes the side drawer
  Widget _buildFilterToggleButton(BuildContext context) {
    // Check whether any filter is currently active
    final bool hasActiveFilter = _activeFilter.hasActiveFilter;

    return GestureDetector(
      onTap: () => setState(() => _filterDrawerOpen = !_filterDrawerOpen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          // color: _filterDrawerOpen
          //     ? AppColors.primary.withAlpha(16)
          //     : hasActiveFilter
          //     ? AppColors.primary.withAlpha(10)
          //     : Colors.transparent,
          // borderRadius: BorderRadius.circular(24),
          // border: Border.all(
          //   color: (_filterDrawerOpen || hasActiveFilter)
          //       ? AppColors.primary
          //       : AppColors.background,
          //   width: 1.3,
          // ),
        ),
        child: Stack(
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: hasActiveFilter ? 28 : 24,
              color: (_filterDrawerOpen || hasActiveFilter)
                  ? AppColors.background
                  : AppColors.background,
            ),
            // const SizedBox(width: 6),
            // Text(
            //   "Filter",
            //   style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
            //     color: (_filterDrawerOpen || hasActiveFilter)
            //         ? AppColors.primary
            //         : AppColors.background,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
            // Active-filter indicator dot
            if (hasActiveFilter) ...[
              Positioned(
                right: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // NEW: Side filter drawer panel
  // ════════════════════════════════════════════════════

  Widget _buildFilterDrawerPanel(BuildContext context) {
    // Local list variables tracking types inside filter collection

    return Material(
      color: AppColors.surfaceLight,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(-6, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drawer Header Section
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderLight, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Filters",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _filterDrawerOpen = false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              // Dropdown field options inside operational scroll container
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isbothtype && isbothpost) ...[
                        Container(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            type ?? "",
                            style: AppTextThemes.getLightTextTheme.bodyMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // POST TYPE DROPDOWN (Sale / Purchase)
                      if (isbothpost) ...[
                        //   _buildDrawerSectionLabel(
                        //   Icons.swap_horiz_rounded,
                        //   "Post Type",
                        // ),
                        const SizedBox(height: 16),
                        CustomDropdownFormField(
                          label: "Post Type",
                          value: selectedPostFilter,
                          items: postTypes,
                          labels: postTypes,
                          onChanged: (val) async {
                            setState(() {
                              selectedPostFilter = val ?? "All";
                              if (val == "Sale") {
                                currentRole = "stocks";
                              } else if (val == "Purchase") {
                                currentRole = "requirements";
                              } else {
                                currentRole = null;
                              }
                            });
                            await _applyDynamicFilterChange("postTypes");
                          },
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                currentRole == 'stocks'
                                    ? "Sale"
                                    : currentRole == 'requirements'
                                    ? "Purchase"
                                    : "",
                                style: AppTextThemes.getLightTextTheme.bodyMedium
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (!isbothtype)
                              Container(
                                padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  type ?? "",
                                  style: AppTextThemes.getLightTextTheme.bodyMedium
                                      ?.copyWith(color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // BUSINESS / PRODUCT LISTING TYPE DROPDOWN
                      if (isbothtype) ...[
                        //   _buildDrawerSectionLabel(
                        //   Icons.business_center_rounded,
                        //   "Business Type",
                        // ),
                        // const SizedBox(height: 10),
                        CustomDropdownFormField(
                          label: "Product Type",
                          value: selectedFilter,
                          items: productTypes,
                          labels: productTypes.map((t) => t == "RCN" ? Translate.t("filter.rcn") : (t == "Kernel" ? Translate.t("filter.kernel") : t)).toList(),
                          onChanged: (val) async {
                            setState(() {
                              selectedFilter = val ?? "All Listings";
                              type = (selectedFilter == "All Listings")
                                  ? null
                                  : selectedFilter;
                            });
                            await _applyDynamicFilterChange("productTypes");
                          },
                        ),
                        // const SizedBox(height: 12),
                      ],
                      // ORIGIN COUNTRY dropdown
                      // _buildDrawerSectionLabel(
                      //   Icons.public_rounded,
                      //   "Origin Country",
                      // ),
                      const SizedBox(height: 16),
                      CustomDropdownFormField(
                        label: "Origin",
                        value: originvalue,
                        items: origins,
                        labels: origins,
                        onChanged: (value) async {
                          setState(() {
                            originvalue = value!.toString();
                            origin = (value == "All") ? null : value;
                          });
                          await _applyDynamicFilterChange("origins");
                        },
                      ),
                      // const SizedBox(height: 12),

                      // CALENDAR PERIOD
                      // _buildDrawerSectionLabel(
                      //   Icons.date_range_rounded,
                      //   "Date Range",
                      // ),
                      const SizedBox(height: 16),
                      DateRangePicker(
                        date: date,
                        onChangedDate: () => _pickDateRange(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Committing Action Buttons inside Drawer Bottom Bar Frame
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            for (final f in _tabFilters) {
                              f.resetAll();
                            }
                            searchController.clear();
                          });
                          _applyDynamicFilterChange("");
                        },
                        child: const Text("Reset"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _filterDrawerOpen = false);
                          getPost(
                            load: true,
                          ); // Triggers network dispatch when closing drawer
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                        ),
                        child: const Text(
                          "Apply",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section label inside the filter drawer
  Widget _buildDrawerSectionLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  /// Removable chip showing an active filter value
  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      deleteIcon: Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
      onDeleted: onRemove,
      backgroundColor: AppColors.primary.withAlpha(14),
      deleteButtonTooltipMessage: '',
      side: BorderSide(color: AppColors.primary.withAlpha(60)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  // ── KEPT (commented out) ─────────────────────────────────

  // Widget _buildTypeFilterSection(BuildContext context) {
  //   return Padding(
  //     padding: ResponsiveContext(context).screenPadding,
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: searchbarwidget(
  //             searchController: searchController,
  //             onChangedSearch: (value) {
  //               search = value;
  //               getPost();
  //             },
  //           ),
  //         ),
  //         HGap(context.spacing8),
  //         isfilterbutton(
  //           onFilterToggle: () {
  //             setState(() => isFilter = !isFilter);
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildFilterPanel(BuildContext context) {
  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 300),
  //     child: _buildTypeFilterPanel(context),
  //   );
  // }

  // Widget _buildTypeFilterPanel(BuildContext context) {
  //   return Padding(
  //     padding: context.screenPadding,
  //     child: context.switchDevice(
  //       mobile: Row(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Flexible(
  //             child: CustomDropdownFormField(
  //               label: "Origin",
  //               value: originvalue,
  //               items: origins,
  //               labels: origins,
  //               onChanged: (value) {
  //                 setState(() { originvalue = value!.toString(); });
  //                 origin = value == "All" ? null : value;
  //                 getPost();
  //               },
  //             ),
  //           ),
  //           HGap(context.spacing12),
  //           Expanded(
  //             child: DateRangePicker(
  //               date: date,
  //               onChangedDate: () { _pickDateRange(context); },
  //             ),
  //           ),
  //         ],
  //       ),
  //       tablet: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           CustomDropdownFormField(
  //             label: "Origin",
  //             value: originvalue,
  //             items: origins,
  //             labels: origins,
  //             onChanged: (value) {
  //               setState(() { originvalue = value!.toString(); });
  //               origin = value == "All" ? null : value;
  //               getPost();
  //             },
  //           ),
  //           HGap(context.spacing12),
  //           Expanded(
  //             child: DateRangePicker(
  //               date: date,
  //               onChangedDate: () { _pickDateRange(context); },
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ════════════════════════════════════════════════════════
  // OLD TAB BAR — COMMENTED OUT (replaced by _buildNewTabNavigation)
  // ════════════════════════════════════════════════════════

  // Widget _buildStylishTabBar(BuildContext context) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       border: Border(
  //         bottom: BorderSide(color: AppColors.borderLight, width: 1),
  //       ),
  //     ),
  //     margin: EdgeInsets.zero,
  //     padding: EdgeInsets.zero,
  //     child: TabBar(
  //       controller: _tab,
  //       indicator: UnderlineTabIndicator(
  //         borderSide: BorderSide(color: AppColors.primary, width: 3),
  //         insets: const EdgeInsets.symmetric(horizontal: 16),
  //       ),
  //       labelColor: AppColors.primary,
  //       unselectedLabelColor: AppColors.textSecondary,
  //       labelStyle: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
  //         color: AppColors.primary,
  //         fontWeight: FontWeight.w600,
  //         letterSpacing: 0.3,
  //       ),
  //       unselectedLabelStyle: AppTextThemes.getLightTextTheme.labelLarge?.copyWith(
  //         color: AppColors.textSecondary,
  //         fontWeight: FontWeight.w500,
  //       ),
  //       splashFactory: NoSplash.splashFactory,
  //       overlayColor: MaterialStateProperty.all(Colors.transparent),
  //       tabs: [
  //         _buildTab(context, Icons.fiber_new, Translate.t("homeScreen.new")),
  //         _buildTab(context, Icons.visibility_outlined, Translate.t("homeScreen.viewed")),
  //         _buildTab(context, Icons.favorite_border, Translate.t("homeScreen.favorite")),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildTab(BuildContext context, IconData icon, String label) {
  //   return Tab(
  //     child: context.switchDevice(
  //       mobile: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(icon, size: context.iconSizeSmall),
  //           HGap(context.spacing4),
  //           ResponsiveText(label, mobileSize: 16),
  //         ],
  //       ),
  //       tablet: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(icon, size: context.iconSizeMedium),
  //           HGap(context.spacing4),
  //           ResponsiveText(label, mobileSize: 18),
  //         ],
  //       ),
  //       desktop: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(icon, size: context.iconSizeLarge),
  //           HGap(context.spacing4),
  //           ResponsiveText(label, mobileSize: 20),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ════════════════════════════════════════════════════════
  // REST OF HOME SCREEN (unchanged from original)
  // ════════════════════════════════════════════════════════

  Widget _buildLoadingState(BuildContext context) {
    return ListView(
      children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: context.screenPadding,
            child: MarketplaceListingCardSkeleton(),
          ),
      ],
    );
  }

  Widget _buildPostsList(
    BuildContext context,
    List<dynamic> posts, {
    bool hasMore = false,
    _HomeTabFilterState? filter,
  }) {
    List<dynamic> filteredPosts = posts.where((element) {
      // ── expiry filter ──────────────────────────────
      final expireStr = element['expiredate'] ?? element['deliverydate'];
      if (expireStr == null || expireStr.isEmpty) return false;
      try {
        final expireDate = DateTime.parse(expireStr).toUtc();
        final now = DateTime.now().toUtc();
        if (expireDate.isBefore(now)) return false;
      } catch (_) {
        return false;
      }

      if (filter == null) return true;

      // ── post_type (Sale / Purchase) ─────────────────
      if (filter.currentRole != null &&
          element['post_type']?.toString() != filter.currentRole) {
        return false;
      }

      // ── product type (RCN / Kernel) ─────────────────
      final apiType = (filter.type == null || filter.type == 'All Listings')
          ? null
          : filter.type;
      if (apiType != null && element['type']?.toString() != apiType) {
        return false;
      }

      // ── origin ──────────────────────────────────────
      if (filter.origin != null &&
          element['origin']?.toString() != filter.origin) {
        return false;
      }

      // ── date range (expiredate) ──────────────────────
      if (filter.startDate != null && filter.endDate != null) {
        final d = DateTime.tryParse(
          element['expiredate']?.toString() ??
              element['deliverydate']?.toString() ??
              '',
        );
        final from = DateTime.tryParse(filter.startDate!);
        final to = DateTime.tryParse(filter.endDate!);
        if (d != null && from != null && to != null) {
          if (d.isBefore(from) || d.isAfter(to)) return false;
        }
      }

      // ── search (merchantname / user_name) ───────────
      if (filter.search != null && filter.search!.isNotEmpty) {
        final q = filter.search!.toLowerCase();
        final name = (element['merchantname'] ?? element['user_name'] ?? '')
            .toString()
            .toLowerCase();
        if (!name.contains(q)) return false;
      }

      return true;
    }).toList();

    if (!isLoading && filteredPosts.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await getPost();
      },
      child: _buildAdaptiveGrid(context, filteredPosts, hasMore),
    );
  }

  void showCompleteProfilePopup(
    BuildContext context,
    String message,
    String button,
    String path,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
                splashRadius: 20,
              ),
            ],
          ),
          // content: Text(message),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.pop();
                  context.push(path);
                },
                child: Text(button),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdaptiveGrid(
    BuildContext context,
    List<dynamic> filteredPosts,
    bool hasMore,
  ) {
    final spacing = context.gridSpacing;

    Future<void> handleNavigation(dynamic item) async {
      try {
        final isMerchant = item["post_type"] == "stocks";
        final path = isMerchant
            ? RoutePath.viewscreen
            : RoutePath.sellerviewscreen;
        if (!mounted) return;
        if (!iscomplete) {
          context.push(path, extra: item['_id']);
          await action(id: item['_id'], action: "viewed");
          // getPost(
          //   load: true,
          //   refreshDynamicFilters: false,
          //   suppressLoading: true,
          // );
        }
      } catch (e) {
        debugPrint('handleNavigation error: $e');
      }
    }

    Widget buildCard(dynamic item) {
      bool like = (item['favorite'] as List?)?.contains(userId) ?? false;
      return Postview(
        like: like,
        refresh: refresh,
        key: ValueKey(item['_id']),
        item: item,
        userId: userId,
        ontap: () async {
          await getPost();
        },
        ontaplike: (value) async {
          await action(id: item['_id'], action: "favorite", status: value);
          await getPost(
            load: true,
            refreshDynamicFilters: false,
            suppressLoading: true,
          );
        },
        ontapview: () => handleNavigation(item),
      );
    }

    if (!context.isTablet && !context.isDesktop) {
      return ListView.separated(
        controller: _scrollController,
        // padding: context.screenPadding,
        itemCount: filteredPosts.length,
        cacheExtent: 1000,
        separatorBuilder: (_, __) => SizedBox(height: 0),
        itemBuilder: (context, index) {
          // if (index >= filteredPosts.length) {
          //   return const MarketplaceListingCardSkeleton();
          // }
          return buildCard(filteredPosts[index]);
        },
      );
    }

    final columns = context.switchValue(mobile: 1, tablet: 2, desktop: 3);

    return GridView.builder(
      controller: _scrollController,
      padding: context.screenPadding,
      cacheExtent: 1000,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: context.switchValue(
          mobile: 1.0,
          tablet: 2.4,
          desktop: 2,
        ),
        crossAxisSpacing: spacing * 0.3,
        mainAxisSpacing: spacing * 0.3,
      ),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        // if (index >= filteredPosts.length) {
        //   return const MarketplaceListingCardSkeleton();
        // }
        return buildCard(filteredPosts[index]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await getPost();
      },
      child: Center(
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
    );
  }

  Widget _buildStylishTabBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: DefaultTabController(
        length: 3,
        child: TabBar(
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: AppColors.primary, width: 3),
            insets: const EdgeInsets.symmetric(horizontal: 16),
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: AppTextThemes.getLightTextTheme.labelLarge
              ?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
          splashFactory: NoSplash.splashFactory,
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          tabs: [
            _buildTab(context, Icons.fiber_new, Translate.t("homeScreen.new")),
            _buildTab(
              context,
              Icons.visibility_outlined,
              Translate.t("homeScreen.viewed"),
            ),
            _buildTab(
              context,
              Icons.favorite_border,
              Translate.t("homeScreen.favorite"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, IconData icon, String label) {
    return Tab(
      child: context.switchDevice(
        // Mobile: Icon + text in row
        mobile: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.iconSizeSmall),
            const SizedBox(width: 10),
            Text(label, style: AppTextThemes.getLightTextTheme.labelLarge),
          ],
        ),
        // Tablet: Icon + text, more spacing
        tablet: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.iconSizeMedium),
            const SizedBox(width: 10),
            Text(label, style: AppTextThemes.getLightTextTheme.labelLarge),
          ],
        ),
        // Desktop: Icon + text, generous spacing
        desktop: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.iconSizeLarge),
            const SizedBox(width: 10),
            Text(label, style: AppTextThemes.getLightTextTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

// ==================== Post Card Widget ====================

class Postview extends StatefulWidget {
  final dynamic item;
  final String userId;
  final bool? refresh;
  final bool? like;
  final Function(bool)? ontaplike;
  final Function()? ontapview;
  final Function()? ontap;

  const Postview({
    super.key,
    required this.item,
    required this.like,
    this.refresh,
    this.ontap,
    required this.userId,
    this.ontaplike,
    this.ontapview,
  });

  @override
  State<Postview> createState() => _PostviewState();
}

class _PostviewState extends State<Postview>
    with SingleTickerProviderStateMixin {
  final Function(dynamic) formatToKg = Formatters.formatToKg;
  final Function(dynamic) formatToMoney = Formatters.formatTomoney;
  final Function(dynamic) _formatDate = Formatters.formatDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildCardForRole() {
    final isMerchantPost = widget.item["post_type"] == "stocks";
    return MarketplaceListingCard(
      posttype: widget.item['post_type'] ?? "",
      name:
          '${isMerchantPost ? widget.item["merchantname"] : widget.item["user_name"]}',
      company: '',
      title:
          "${widget.item['type'] == 'Kernel' ? widget.item['grade'] ?? '' : widget.item['yearOfCrop'] ?? widget.item['yearofcrop'] ?? ''} ${widget.item['type'] == 'Kernel' ? Translate.t('filter.kernel') : Translate.t('filter.rcn')} - ${widget.item['origin'] ?? ''}",
      quantity: isMerchantPost
          ? formatToKg(widget.item['availableqty'] ?? 0)
          : formatToKg(widget.item['requiredqty'] ?? 0),
      qtylabel: isMerchantPost
          ? Translate.t("homeScreen.available_stock")
          : Translate.t("homeScreen.required_stock"),
      qtyavailablelabel: isMerchantPost
          ? Translate.t("homeScreen.available_from")
          : Translate.t("homeScreen.required_from"),
      currency: widget.item['currency'] ?? '',
      isrcn: widget.item['type'] == "RCN",
      high: widget.item['high'] ?? false,
      location: "${widget.item['location']}",
      availableFrom: _formatDate(
        widget.item['fromdate'] ??
            widget.item['orderDate'] ??
            widget.item['created_on'] ??
            'N/A',
      ),
      unit: widget.item['priceunit'] ?? 'kg',
      availableUntil: _formatDate(
        widget.item['expiredate'] ?? widget.item['deliverydate'] ?? 'N/A',
      ),
      pricePerUnit: isMerchantPost
          ? '${formatToMoney((widget.item['sellingprice']) ?? 0)}'
          : '${formatToMoney((widget.item['expectedprice']) ?? 0)}',
      liked: widget.like ?? false,
      onLike: widget.ontaplike,
      onTap: widget.ontapview,
      onShare: widget.ontapview,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildCardForRole();
  }
}

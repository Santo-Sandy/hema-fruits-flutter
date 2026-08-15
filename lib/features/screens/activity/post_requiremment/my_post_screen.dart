import 'package:hema_fruits/core/constants/app_assets.dart';
import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/core/providers/swap_user_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/repositories/post_repository.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/auth_service/auth_service.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/Responsive/responsivea_context.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/filters_dynamc.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/features/layouts/skeleton_loader.dart';
import 'package:hema_fruits/features/screens/activity/post_requiremment/newPost/newPost.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/activity_page_controls.dart';
import 'package:hema_fruits/shared/widgets/custom_input.dart';
import 'package:hema_fruits/shared/widgets/custom.dart';
import 'package:hema_fruits/shared/widgets/filter_widgets.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:flutter/material.dart' hide SearchBar;
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MyPostAndResponse extends StatefulWidget {
  final String? type;
  final bool showInlineFilters;
  final ActivityFilterController? filterController;
  final int? filterPageIndex;
  final ActivitySortController? sortController;
  final int? sortPageIndex;

  const MyPostAndResponse({
    super.key,
    this.type,
    this.showInlineFilters = true,
    this.filterController,
    this.filterPageIndex,
    this.sortController,
    this.sortPageIndex,
  });

  @override
  State<MyPostAndResponse> createState() => _MyPostAndResponse();
}

class _MyPostAndResponse extends State<MyPostAndResponse> {
  final TextEditingController searchController = TextEditingController();
  String searchfilter = "";
  Map<String, dynamic> userData = {};
  String userId = "";
  String user = "";
  bool isFilter = false;
  bool _isUserDataCached = false;
  String selectedFilter = "All Listings";
  String date = Translate.t("homeScreen.select_date");
  String? type;
  String? startDate;
  String? endDate;
  String? origin;
  String? status;
  List<Map<String, dynamic>> items = [];
  String? grade;
  String? Role;
  String selectedgrade = "All";
  String selectedOrigin = "All";
  String selectedstatus = "All";
  Map<String, dynamic> Settings = {};
  List<String> origins = [
    "All",
    "India",
    "Vietnam",
    "Ivory Coast",
    "Nigeria",
    "Brazil",
  ];
  List<String> postTypes = ["All", "Sale", "Purchase"];
  List<String> productTypes = ["All Listings", "RCN", "Kernel"];

  List<String> grades = [
    "All",
    "W180",
    "W240",
    "W320",
    "W450",
    "W500",
    "Broken BB",
    "Broken LP",
  ];
  List<String> statuses = ["All", "Active", "Closed"];
  String? currentRole;
  bool isbothtype = true;
  bool isbothpost = true;
  bool posting = false;
  String _productType = "";
  String _sortBy = "Newest";
  String selectedPostFilter = "All"; // All / Sale / Purchase
  String? _postTypeRole; // null / "processor" / "buyer"

  @override
  void initState() {
    super.initState();

    _applyRouteType(widget.type);

    initialization();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerFilterDrawer();
    });
  }

  void _applyRouteType(String? routeType) {
    if (routeType == "RCN" || routeType == "Kernel") {
      type = routeType;
      selectedFilter = routeType ?? "All Listings";
      return;
    }

    type = null;
    selectedFilter = "All Listings";
  }

  @override
  void didUpdateWidget(covariant MyPostAndResponse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      setState(() {
        _applyRouteType(widget.type);
        origin = null;
        grade = null;
        status = null;
        searchfilter = "";
        selectedOrigin = "All";
        selectedgrade = "All";
        selectedstatus = "All";
        startDate = null;
        endDate = null;
        date = "Select Date";
      });
      getPost();
      _syncFilterIndicator();
    }
    if (oldWidget.filterController != widget.filterController ||
        oldWidget.filterPageIndex != widget.filterPageIndex) {
      if (oldWidget.filterController != null &&
          oldWidget.filterPageIndex != null) {
        oldWidget.filterController!.unregister(oldWidget.filterPageIndex!);
      }
      _registerFilterDrawer();
    }
    if (oldWidget.sortController != widget.sortController ||
        oldWidget.sortPageIndex != widget.sortPageIndex) {
      if (oldWidget.sortController != null && oldWidget.sortPageIndex != null) {
        oldWidget.sortController!.unregister(oldWidget.sortPageIndex!);
      }
      _registerSortDrawer();
    }
  }

  @override
  void dispose() {
    if (widget.filterController != null && widget.filterPageIndex != null) {
      widget.filterController!.unregister(widget.filterPageIndex!);
    }
    if (widget.sortController != null && widget.sortPageIndex != null) {
      widget.sortController!.unregister(widget.sortPageIndex!);
    }
    searchController.dispose();
    super.dispose();
  }

  void _registerFilterDrawer() {
    if (widget.filterController == null || widget.filterPageIndex == null) {
      return;
    }
    widget.filterController!.register(
      widget.filterPageIndex!,
      _showFilterDrawer,
    );
    _syncFilterIndicator();
    _registerSortDrawer();
  }

  void _registerSortDrawer() {
    if (widget.sortController == null || widget.sortPageIndex == null) {
      return;
    }
    widget.sortController!.register(widget.sortPageIndex!, _showSortDrawer);
    _syncSortIndicator();
  }

  bool get _hasActiveFilters {
    return selectedFilter != "All Listings" ||
        origin != null ||
        status != null ||
        grade != null ||
        startDate != null;
  }

  void _syncFilterIndicator() {
    if (widget.filterController == null || widget.filterPageIndex == null) {
      return;
    }
    widget.filterController!.setPageHasActiveFilter(
      widget.filterPageIndex!,
      _hasActiveFilters,
    );
  }

  void _syncSortIndicator() {
    if (widget.sortController == null || widget.sortPageIndex == null) {
      return;
    }
    widget.sortController!.setPageHasActiveFilter(
      widget.sortPageIndex!,
      _sortBy != "Newest",
    );
  }

  Future<void> initialization() async {
    try {
      // Cache user data once during initialization
      userData = await SecureStorageService.getUserData();
      userId = userData['_id'] ?? '';
      _isUserDataCached = true;

      final swap = context.read<SwapUserProvider>();

      final role = swap.swapedUser;
      final producttype = swap.productType;
      if (producttype != "Both") {
        _productType = producttype;
        isbothtype = false;
        setState(() {
          type = producttype;
        });

        selectedFilter = producttype;
        if (widget.type == null) {
          selectedFilter = producttype;
        }
      } else {
        isbothtype = true;
      }
      if (role == "both") {
        isbothpost = true;
        currentRole = null;
        selectedPostFilter = "All";
      } else {
        currentRole = role == "buyer" ? "stocks" : "requirements";
        isbothpost = false;
        selectedPostFilter = currentRole ?? "All";
      }

      await getPost();
      if (!mounted) return;
    } catch (e) {}
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

  /// Validates user data (profile, points) - only fetches when needed
  Future<bool> _validateUserData() async {
    try {
      // Refresh user data specifically for validation
      final freshUserData = await SecureStorageService.getUserData();
      await getUser(freshUserData['_id']);

      // Update cached data after validation
      userData = await SecureStorageService.getUserData();
      return true;
    } catch (e) {
      debugPrint("Error validating user data: $e");
      return false;
    }
  }

  /// Show loading dialog during navigation
  void _showLoadingDialog(String? message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(message ?? Translate.t("loading.please_wait")),
            ),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  void _hideLoadingDialog() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
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
                  Translate.t("popup.complete_profile"),
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
          content: Text(message),
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

  void showSubscriptionLimitDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: AppColors.accent,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                Translate.t("popup.credit_limit_title"),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              Text(
                Translate.t("popup.credit_limit_desc", {
                  "point": Settings["PostDetectionPoint"].toString(),
                  "ptype": Translate.t("popup.type_post"),
                }),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    context.push(RoutePath.creditpayment);
                    Navigator.pop(context);
                  },
                  child: Text(
                    Translate.t("popup.buy_points"),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(Translate.t("popup.maybe_later")),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> getPost({bool refreshDynamicFilters = true}) async {
    try {
      // Use cached userId if available, otherwise fetch
      if (!_isUserDataCached || userId.isEmpty) {
        userData = await SecureStorageService.getUserData();
        userId = userData['_id'] ?? '';
        _isUserDataCached = true;
      }

      final request = FilterRequest(userId: userId);
      final filterPayloads = _handleFilter(request);

      await context.read<MyPostProvider>().fetch(
        userId: userId,
        endpoint: "/dataset/data/Marketplace",
        filterPayload: filterPayloads,
      );
      if (refreshDynamicFilters) {
        _refreshDynamicFilters();
      }
      await loadSettings();
    } catch (e) {}
  }

  Future<void> _applyDynamicFilterChange(String excludedFilter) async {
    await getPost(refreshDynamicFilters: false);
    _refreshDynamicFilters(excludedFilter: excludedFilter);
  }

  void filter(String excludedFilter) {
    _refreshDynamicFilters(excludedFilter: excludedFilter);
  }

  void _refreshDynamicFilters({String? excludedFilter}) {
    if (!mounted) return;

    final provider = context.read<MyPostProvider>();
    final posts = provider.post;
    final filters = FiltersDynamic.getFilters(excludedFilter ?? "", [
      _originsFromPosts(posts),
      _gradesFromPosts(posts),
      _typesFromPosts(posts),
      _postTypesFromPosts(posts),
    ]);

    setState(() {
      if (excludedFilter != "origins") {
        origins = List<String>.from(filters[0]);
      }
      if (excludedFilter != "grades") {
        grades = List<String>.from(filters[1]);
      }
      if (excludedFilter != "productTypes") {
        productTypes = List<String>.from(filters[2]);
      }
      if (excludedFilter != "postTypes") {
        postTypes = List<String>.from(filters[3]);
        if (_postTypeRole == "stocks") {
          selectedPostFilter = "Sale";
        } else if (_postTypeRole == "requirements") {
          selectedPostFilter = "Purchase";
        }
      }
      if (excludedFilter != "statuses") {
        statuses = ["All", ..._statusesFromPosts(posts)];
      }
      _keepSelectedFilterValues();
    });
  }

  void _keepSelectedFilterValues() {
    if (!origins.contains(selectedOrigin)) {
      origins = [...origins, selectedOrigin];
    }
    if (!grades.contains(selectedgrade)) {
      grades = [...grades, selectedgrade];
    }
    if (!statuses.contains(selectedstatus)) {
      statuses = [...statuses, selectedstatus];
    }
    if (!productTypes.contains(selectedFilter)) {
      productTypes = [...productTypes, selectedFilter];
    }
    if (!postTypes.contains(selectedPostFilter)) {
      postTypes = [...postTypes, selectedPostFilter];
    }
  }

  List<String> _originsFromPosts(List<dynamic> posts) {
    return posts
        .where((post) => post["origin"] != null)
        .map<String>((post) => post["origin"].toString())
        .toSet()
        .toList();
  }

  List<String> _gradesFromPosts(List<dynamic> posts) {
    return posts
        .where(
          (post) =>
              post["grade"] != null &&
              post["grade"] != "" &&
              post["grade"] != "RCN",
        )
        .map<String>((post) => post["grade"].toString())
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

  List<String> _statusesFromPosts(List<dynamic> posts) {
    return posts
        .where((post) => post["status"] != null)
        .map<String>((post) => post["status"].toString())
        .toSet()
        .toList();
  }

  void showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Delete Post",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Are you sure you want to delete this post?"),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await deletePost(id);
                    },
                    child: const Text("Delete"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> deletePost(String id) async {
    ApiDioPutService deletepost = ApiDioPutService();

    await deletepost.getdata(
      endpoint: "entities/post/$id",
      data: {"isDeleted": true, "status": "closed"},
    );
    await PostRepository.instance.deletePost(id);
    getPost();
  }

  void _openProductSelector(BuildContext context) {
    // Determine which options to show based on isbothtype and isbothpost
    final List<Map<String, dynamic>> options = [];

    if (isbothtype && isbothpost) {
      options.addAll([
        {
          'label': '${Translate.t("filter.rcn")} - Sale',
          'role': 'processor',
          'type': 'RCN',
          'icon': Icons.sell,
        },
        {
          'label': '${Translate.t("filter.kernel")} - Sale',
          'role': 'processor',
          'type': 'Kernel',
          'icon': Icons.sell_outlined,
        },
        {
          'label': '${Translate.t("filter.multiple")} - Sale',
          'role': 'processor',
          'type': 'Multiple',
          'icon': Icons.sell_outlined,
        },
        {
          'label': '${Translate.t("filter.rcn")} - Purchase',
          'role': 'buyer',
          'type': 'RCN',
          'icon': Icons.shopping_bag,
        },
        {
          'label': '${Translate.t("filter.kernel")} - Purchase',
          'role': 'buyer',
          'type': 'Kernel',
          'icon': Icons.shopping_cart_outlined,
        },
        {
          'label': '${Translate.t("filter.multiple")} - Purchase',
          'role': 'buyer',
          'type': 'Multiple',
          'icon': Icons.shopping_cart_outlined,
        },
      ]);
    } else if (isbothtype) {
      // role is fixed, only type varies
      final role =
          _postTypeRole ?? (currentRole == 'stocks' ? 'processor' : 'buyer');
      options.addAll([
        {
          'label': Translate.t("filter.rcn"),
          'role': role,
          'type': 'RCN',
          'icon': Icons.agriculture,
        },
        {
          'label': Translate.t("filter.kernel"),
          'role': role,
          'type': 'Kernel',
          'icon': Icons.inventory,
        },
        {
          'label': Translate.t("filter.multiple"),
          'role': role,
          'type': 'Multiple',
          'icon': Icons.list_alt,
        },
      ]);
    } else if (isbothpost) {
      // type is fixed, only role varies
      final fixedType = _productType.isNotEmpty
          ? _productType
          : (type ?? 'RCN');
      options.addAll([
        {
          'label': 'Sale $fixedType',
          'role': 'processor',
          'type': fixedType,
          'icon': Icons.agriculture,
        },
        {
          'label': 'Purchase $fixedType',
          'role': 'buyer',
          'type': fixedType,
          'icon': Icons.agriculture_outlined,
        },
      ]);
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Translate.t("button.select"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...options.map(
                (opt) => ListTile(
                  leading: Icon(opt['icon'] as IconData),
                  title: Text(opt['label'] as String),
                  onTap: () {
                    context.pop();
                    // _showLoadingDialog(Translate.t("loading.opening_post"));
                    context
                        .push(
                          RoutePath.newPost,
                          extra: [
                            opt['role'].toString(),
                            opt['type'].toString(),
                            "posts",
                            (opt['role'] as String).toLowerCase() == "buyer"
                                ? "requirements"
                                : "stocks",
                          ],
                        )
                        .then((_) {
                          // _hideLoadingDialog();
                          getPost();
                        });
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _handleFilter(FilterRequest request) {
    return request.getMyRequirementPost(
      type: type,
      grade: grade,
      posttype: _postTypeRole,
      origin: origin,
      status: status,
      fromDate: startDate,
      toDate: endDate,
    );
  }

  void _updateFilter(String filterName) {
    setState(() {
      grade = null;
      origin = null;
      status = null;
      startDate = null;
      endDate = null;
      date = "Select Date";
      selectedgrade = 'All';
      selectedOrigin = "All";
      selectedFilter = filterName;
    });

    switch (filterName) {
      case "All Listings":
        type = null;
        break;
      case "RCN":
        type = 'RCN';
        break;
      case "Kernel":
        type = "Kernel";
        break;
      default:
        type = '';
    }
    _applyDynamicFilterChange("productTypes");
    _syncFilterIndicator();
  }

  String _formatUtcIso(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  Future<void> _pickDateRange(
    BuildContext context, [
    VoidCallback? refreshDrawer,
  ]) async {
    final pickerContext = ContextManager().currentContext ?? context;

    showCustomDateRangePicker(
      pickerContext,
      dismissible: true,
      minimumDate: DateTime.now().subtract(const Duration(days: 3000)),
      maximumDate: DateTime.now().add(const Duration(days: 3000)),
      backgroundColor: Colors.white,
      primaryColor: AppColors.success,
      onApplyClick: (start, end) {
        setState(() {
          endDate = _formatUtcIso(end.add(const Duration(days: 1)));
          startDate = _formatUtcIso(start);
          date =
              "${DateFormat('dd-MM-yyyy').format(start)} - ${DateFormat('dd-MM-yyyy').format(end)}";
        });
        _applyDynamicFilterChange("");
        _syncFilterIndicator();
        refreshDrawer?.call();
      },
      onCancelClick: () {
        setState(() {
          endDate = null;
          startDate = null;
          date = "Select Date";
        });
        _applyDynamicFilterChange("");
        _syncFilterIndicator();
        refreshDrawer?.call();
      },
    );
  }

  Future<void> _openDateRangePickerFromDrawer([
    VoidCallback? refreshDrawer,
  ]) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    _pickDateRange(ContextManager().currentContext ?? context, refreshDrawer);
  }

  void _resetAdvancedFilters() {
    setState(() {
      selectedPostFilter = "All";
      selectedFilter = "All Listings";
      selectedstatus = "All";
      type = null;
      _postTypeRole = null;
      grade = null;
      origin = null;
      status = null;
      startDate = null;
      endDate = null;
      date = "Select Date";
      selectedgrade = 'All';
      selectedOrigin = "All";
    });
    _applyDynamicFilterChange("");
    _syncFilterIndicator();
  }

  void _showFilterDrawer() {
    ActivityFilterDrawer.show(
      context: context,
      title: "Filters",
      onReset: _resetAdvancedFilters,
      contentBuilder: (context, refresh) => _buildFilterDrawerContent(refresh),
    );
  }

  void _showSortDrawer() {
    ActivityFilterDrawer.show(
      context: context,
      title: "Sort",
      headerIcon: Icons.swap_vert,
      onReset: () {
        setState(() => _sortBy = "Newest");
        _syncSortIndicator();
      },
      contentBuilder: (context, refresh) => _buildSortDrawerContent(refresh),
    );
  }

  Widget _buildSortDrawerContent([VoidCallback? refreshDrawer]) {
    return ActivityDrawerField(
      icon: Icons.swap_vert,
      label: "Sort By",
      child: Column(
        children: [
          RadioListTile<String>(
            value: "Newest",
            groupValue: _sortBy,
            onChanged: (value) {
              _updateSort(value);
              refreshDrawer?.call();
            },
            title: const Text("Newest first"),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: "Oldest",
            groupValue: _sortBy,
            onChanged: (value) {
              _updateSort(value);
              refreshDrawer?.call();
            },
            title: const Text("Oldest first"),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _updateSort(String? value) {
    if (value == null) return;
    setState(() => _sortBy = value);
    _syncSortIndicator();
  }

  List<dynamic> _sortItems(List<dynamic> source) {
    final items = List<dynamic>.from(source);
    int compareByDate(dynamic a, dynamic b) {
      final left = DateTime.tryParse(a["created_on"]?.toString() ?? "");
      final right = DateTime.tryParse(b["created_on"]?.toString() ?? "");
      final result = (right ?? DateTime(0)).compareTo(left ?? DateTime(0));
      return _sortBy == "Newest" ? result : -result;
    }

    items.sort(compareByDate);
    return items;
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
                await _applyDynamicFilterChange("postTypes");
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
                    type ?? "",
                    style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        if (isbothtype)
          ActivityDrawerField(
            icon: Icons.inventory_2_outlined,
            label: Translate.t("button.select"),
            child: CustomDropdownFormField<String>(
              label: Translate.t("button.select"),
              value: selectedFilter,
              items: productTypes,
              labels: productTypes,
              onChanged: (value) {
                if (value != null) {
                  _updateFilter(value);
                  refreshDrawer?.call();
                }
              },
            ),
          ),
        if (isbothtype) const SizedBox(height: 16),
        ActivityDrawerField(
          icon: Icons.fact_check_outlined,
          label: "Status",
          child: CustomDropdownFormField<String>(
            label: "Status",
            value: selectedstatus,
            items: statuses,
            labels: statuses,
            onChanged: (value) async {
              setState(() {
                selectedstatus = value!;
                status = value == "All" ? null : value;
              });
              await _applyDynamicFilterChange("statuses");
              _syncFilterIndicator();
              refreshDrawer?.call();
            },
          ),
        ),
        const SizedBox(height: 16),
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
                selectedOrigin = value!;
                origin = value == "All" ? null : value;
              });
              await _applyDynamicFilterChange("origins");
              _syncFilterIndicator();
              refreshDrawer?.call();
            },
          ),
        ),
        const SizedBox(height: 16),
        if (type != 'RCN') ...[
          ActivityDrawerField(
            icon: Icons.grade_outlined,
            label: "Grade",
            child: CustomDropdownFormField<String>(
              label: "Grade",
              value: selectedgrade,
              items: grades,
              labels: grades,
              onChanged: (value) async {
                setState(() {
                  selectedgrade = value!;
                  grade = value == "All" ? null : value;
                });
                await _applyDynamicFilterChange("grades");
                _syncFilterIndicator();
                refreshDrawer?.call();
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        ActivityDrawerField(
          icon: Icons.date_range_rounded,
          label: "Date Range",
          child: DateRangePicker(
            date: date,
            onChangedDate: () => _openDateRangePickerFromDrawer(refreshDrawer),
          ),
        ),
        const SizedBox(height: 16),
        ActivityActiveFilters(
          chips: [
            if (isbothpost && selectedPostFilter != "All")
              ActivityActiveFilterChip(
                label: selectedPostFilter,
                onRemove: () {
                  setState(() {
                    selectedPostFilter = "All";
                    _postTypeRole = null;
                  });
                  _applyDynamicFilterChange("");
                  _syncFilterIndicator();
                  refreshDrawer?.call();
                },
              ),
            if (isbothtype && selectedFilter != "All Listings")
              ActivityActiveFilterChip(
                label: selectedFilter,
                onRemove: () {
                  _updateFilter("All Listings");
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
                  _applyDynamicFilterChange("");
                  _syncFilterIndicator();
                  refreshDrawer?.call();
                },
              ),
            if (status != null)
              ActivityActiveFilterChip(
                label: "Status: $status",
                onRemove: () {
                  setState(() {
                    status = null;
                    selectedstatus = "All";
                  });
                  _applyDynamicFilterChange("");
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
                    selectedgrade = "All";
                  });
                  _applyDynamicFilterChange("");
                  _syncFilterIndicator();
                  refreshDrawer?.call();
                },
              ),
            if (startDate != null)
              ActivityActiveFilterChip(
                label: date,
                onRemove: () {
                  setState(() {
                    startDate = null;
                    endDate = null;
                    date = "Select Date";
                  });
                  _applyDynamicFilterChange("");
                  _syncFilterIndicator();
                  refreshDrawer?.call();
                },
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('Mypost', context);
    return SafeArea(
      child: Column(
        children: [
          if (widget.showInlineFilters) ...[
            const SizedBox(height: 8),
            isbothtype
                ? Center(
                    child: FilterButtons(
                      selected: selectedFilter,
                      onFilterChanged: (value) {
                        _updateFilter(value);
                      },
                      onFilterToggle: () {
                        setState(() {
                          grade = null;
                          origin = null;
                          startDate = null;
                          endDate = null;
                          date = "Select Date";
                          selectedgrade = 'All';
                          selectedOrigin = "All";
                          isFilter = !isFilter;
                        });
                        _applyDynamicFilterChange("");
                      },
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        isbothtype
                            ? SizedBox()
                            : Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: CustomDropdownFormField(
                                        label: "Origin",
                                        value: selectedOrigin,
                                        items: origins,
                                        labels: origins,
                                        onChanged: (value) async {
                                          setState(() {
                                            selectedOrigin = value!;
                                            origin = value == "All"
                                                ? null
                                                : value;
                                          });

                                          await _applyDynamicFilterChange(
                                            "origins",
                                          );
                                          _syncFilterIndicator();
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: CustomDropdownFormField(
                                        label: "Status",
                                        value: selectedstatus,
                                        items: statuses,
                                        labels: statuses,
                                        onChanged: (value) async {
                                          setState(() {
                                            selectedstatus = value!;
                                            status = value == "All"
                                                ? null
                                                : value;
                                          });

                                          await _applyDynamicFilterChange(
                                            "statuses",
                                          );
                                          _syncFilterIndicator();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    type != 'RCN'
                                        ? Expanded(
                                            child: CustomDropdownFormField(
                                              label: "Grade",
                                              value: selectedgrade,
                                              items: grades,
                                              labels: grades,
                                              onChanged: (value) async {
                                                setState(() {
                                                  selectedgrade = value!;
                                                  grade = value == "All"
                                                      ? null
                                                      : value;
                                                });

                                                await _applyDynamicFilterChange(
                                                  "grades",
                                                );
                                              },
                                            ),
                                          )
                                        : Expanded(
                                            flex: 2,
                                            child: DateRangePicker(
                                              date: date,
                                              onChangedDate: () {
                                                _pickDateRange(context);
                                              },
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                        type != 'RCN'
                            ? Flexible(
                                child: isfilterbutton(
                                  onFilterToggle: () {
                                    setState(() => isFilter = !isFilter);
                                  },
                                ),
                              )
                            : SizedBox(),
                      ],
                    ),
                  ),
            const SizedBox(height: 8),
          ],
          if (widget.showInlineFilters && isFilter)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isbothtype
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: CustomDropdownFormField(
                                label: "Origin",
                                value: selectedOrigin,
                                items: origins,
                                labels: origins,
                                onChanged: (value) async {
                                  setState(() {
                                    selectedOrigin = value!;
                                    origin = value == "All" ? null : value;
                                  });

                                  await _applyDynamicFilterChange("origins");
                                  _syncFilterIndicator();
                                },
                              ),
                            ),
                            Expanded(
                              child: CustomDropdownFormField(
                                label: "Status",
                                value: selectedstatus,
                                items: statuses,
                                labels: statuses,
                                onChanged: (value) async {
                                  setState(() {
                                    selectedstatus = value!;
                                    status = value == "All" ? null : value;
                                  });

                                  await _applyDynamicFilterChange("statuses");
                                  _syncFilterIndicator();
                                },
                              ),
                            ),

                            type != 'RCN'
                                ? Expanded(
                                    child: CustomDropdownFormField(
                                      label: "Grade",
                                      value: selectedgrade,
                                      items: grades,
                                      labels: grades,
                                      onChanged: (value) async {
                                        setState(() {
                                          selectedgrade = value!;
                                          grade = value == "All" ? null : value;
                                        });

                                        await _applyDynamicFilterChange(
                                          "grades",
                                        );
                                      },
                                    ),
                                  )
                                : Expanded(
                                    flex: 2,
                                    child: DateRangePicker(
                                      date: date,
                                      onChangedDate: () {
                                        _pickDateRange(context);
                                      },
                                    ),
                                  ),
                          ],
                        )
                      : SizedBox(),
                  const SizedBox(height: 10),
                  type != 'RCN'
                      ? Row(
                          children: [
                            Expanded(
                              child: DateRangePicker(
                                date: date,
                                onChangedDate: () {
                                  _pickDateRange(context);
                                },
                              ),
                            ),
                          ],
                        )
                      : SizedBox(),
                ],
              ),
            ),
          Expanded(child: _buildPostRequirementTab()),
        ],
      ),
    );
  }

  void showeditpopup(Map<String, dynamic> item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(Translate.t("popup.edit_post")),
          content: Text(Translate.t("popup.to_edit")),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(Translate.t("popup.no")),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // _showLoadingDialog(Translate.t("loading.opening_post"));

                      // Push and await result
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NewPostScreen(
                            isEdit: true,
                            existingData: item,
                            role: item["post_type"] == 'stocks'
                                ? 'processor'
                                : 'buyer',
                            type: item["type"] ?? "RCN",
                            collectionName: item["post_type"] == 'stocks'
                                ? "stocks"
                                : "requirements",
                            queryType: "posts",
                          ),
                        ),
                      );

                      // _hideLoadingDialog();

                      // Ensure widget still exists
                      if (!context.mounted) return;

                      await getPost();
                    },
                    child: Text(Translate.t("popup.yes")),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostRequirementTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: posting
            ? () {}
            : () async {
                // _showLoadingDialog(Translate.t("loading.validating_profile"));
                setState(() {
                  posting = true;
                });
                try {
                  // Validate user data only when needed
                  await _validateUserData();
                  int points = int.tryParse(userData['points'].toString()) ?? 0;

                  // _hideLoadingDialog();

                  if (userData['points'] == null
                  // &&
                  //     (userData['natureOfBusiness'] != 'Agent' ||
                  //         userData['city'] == null ||
                  //         userData['city'] == '')
                  ) {
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
                    return;
                  }
                  if (points < Settings['PostDetectionPoint']) {
                    showSubscriptionLimitDrawer(context);
                    return;
                  }
                  // Both false → role and type are fixed, go directly
                  if (!isbothtype && !isbothpost) {
                    final role =
                        _postTypeRole ??
                        (currentRole == 'stocks' ? 'processor' : 'buyer');
                    // _showLoadingDialog(Translate.t("loading.opening_post"));
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NewPostScreen(
                          role: role,
                          type: _productType,
                          queryType: "posts",
                          collectionName: role.toLowerCase() == "buyer"
                              ? "requirements"
                              : "stocks",
                        ),
                      ),
                    )
                    // .then((_) =>
                    // _hideLoadingDialog()
                    // )
                    ;
                    return;
                  }
                  _openProductSelector(context);
                } catch (e) {
                  // _hideLoadingDialog();
                  debugPrint("Error in FAB: $e");
                } finally {
                  setState(() {
                    posting = false;
                  });
                }
              },
        backgroundColor: AppColors.accent,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: AppColors.background, size: 28),
      ),
      body: Consumer<MyPostProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.post.isEmpty) {
            return const MyPostCardSkeleton();
          }

          if (provider.post.isEmpty) {
            return Center(
              child: RefreshIndicator(
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
                        style: AppTextThemes.getLightTextTheme.titleLarge
                            ?.copyWith(color: AppColors.textHintLight),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final sortedPosts = _sortItems(
            provider.post.where((e) {
              if (type != null && e['type']?.toString() != type) return false;
              if (_postTypeRole != null &&
                  e['post_type']?.toString() != _postTypeRole)
                return false;
              if (origin != null && e['origin']?.toString() != origin)
                return false;
              if (status != null &&
                  e['status']?.toString().toLowerCase() !=
                      status!.toLowerCase())
                return false;
              if (grade != null && e['grade']?.toString() != grade)
                return false;
              if (startDate != null && endDate != null) {
                final d = DateTime.tryParse(e['created_on']?.toString() ?? '');
                final from = DateTime.tryParse(startDate!);
                final to = DateTime.tryParse(endDate!);
                if (d != null && from != null && to != null) {
                  if (d.isBefore(from) || d.isAfter(to)) return false;
                }
              }
              return true;
            }).toList(),
          );

          Widget buildCard(Map<String, dynamic> item) {
            final role = item["post_type"] == 'stocks' ? "processor" : "buyer";
            final remainingEditCount =
                int.tryParse('${item['remainingeditCount'] ?? 0}') ?? 0;
            return MyPostCard(
              posttype: item['post_type'],
              quantity: Formatters.formatToKg(
                item['requiredqty'] ?? item['availableqty'] ?? "0",
              ),
              postlabel: item['requiredqty'] != null
                  ? Translate.t("activity.required_quantity")
                  : Translate.t("activity.available_quantity"),
              isrcn: item['type'] == 'RCN',
              onPressed: () {
                showDeleteDialog(context, item['_id']);
              },
              status: item["status"]?.toString() ?? "",
              statusColor: AppColors.primary,
              statusBgColor: AppColors.primarySubtle,
              icon: Icons.delete,
              iconColor: AppColors.error,
              title: item['type'] == 'Multiple'
                  ? "Multiple Option Post - ${item['origin']}"
                  : '${item['type'] == 'Kernel' ? "${item['grade']} Kernel" : "${item['yearOfCrop'] ?? item['yearofcrop']} RCN"} - ${item['origin']}',
              id: item['type'] == 'Multiple'
                  ? "Origin / Products"
                  : "Origin / ${item['type'] == 'Kernel' ? "Grade" : "Year Of Crop"}",
              postedDate: Formatters.formatDate(
                item["created_on"]?.toString() ?? "",
              ),
              metadataIcon: Icons.visibility,
              editcount: remainingEditCount,
              primaryAction: '',
              secondaryAction: Translate.t("activity.edit"),
              onPrimaryAction: item["offlineQueueId"] != null
                  ? () {
                      if (item['availableqty'] != null) {
                        context.push(
                          RoutePath.postofflineSeller,
                          extra: [
                            '${item["_id"]}',
                            [item],
                          ],
                        );
                      } else {
                        context.push(
                          RoutePath.postofflineBuyer,
                          extra: [
                            '${item["_id"]}',
                            [item],
                          ],
                        );
                      }
                    }
                  : () {
                      // _showLoadingDialog(Translate.t("loading.loading"));
                      role == 'buyer'
                          ? context.push(
                              RoutePath.postBuyer,
                              extra: '${item["_id"]}',
                            )
                          // .then((_) => _hideLoadingDialog())
                          : context.push(
                              RoutePath.postSeller,
                              extra: '${item["_id"]}',
                            )
                      // .then((_) => _hideLoadingDialog())
                      ;
                    },
              onSecondaryAction: () {
                if (remainingEditCount > 0) {
                  // _showLoadingDialog(Translate.t("loading.opening_post"));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NewPostScreen(
                        isEdit: true,
                        existingData: item,
                        role: role,
                        type: item["type"] ?? "RCN",
                        collectionName: role.toLowerCase() == "buyer"
                            ? "requirements"
                            : "stocks",
                        queryType: "posts",
                      ),
                    ),
                  ).then((_) {
                    // _hideLoadingDialog();
                    getPost();
                  });
                }
              },
            );
          }

          final columns = context.switchValue(mobile: 1, tablet: 2, desktop: 3);
          return RefreshIndicator(
            onRefresh: () async => getPost(),
            child: MediaQuery.of(context).size.width < 900 && !context.isDesktop
                ? ListView.separated(
                    itemCount: sortedPosts.length,
                    cacheExtent: 1000,
                    separatorBuilder: (_, __) => SizedBox(height: 0),
                    itemBuilder: (context, index) {
                      final item = Map<String, dynamic>.from(
                        sortedPosts[index],
                      );
                      return buildCard(item);
                    },
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: context.switchValue(
                        mobile: 1.0,
                        tablet: 3,
                        desktop: 2,
                      ),
                      crossAxisSpacing: context.h(2),
                      mainAxisSpacing: context.v(2),
                    ),
                    itemCount: sortedPosts.length,
                    padding: context.screenPadding,
                    cacheExtent: 1000,
                    itemBuilder: (context, index) {
                      final item = Map<String, dynamic>.from(
                        sortedPosts[index],
                      );
                      return buildCard(item);
                    },
                  ),
          );
        },
      ),
    );
  }
}

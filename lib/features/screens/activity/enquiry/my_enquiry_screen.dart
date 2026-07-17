import 'dart:async';

import 'package:cashew_marketplace/core/constants/app_assets.dart';
import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/Responsive/responsivea_context.dart';
import 'package:cashew_marketplace/core/utils/apptoaster.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/filters_dynamc.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/core/utils/currency.dart';
import 'package:cashew_marketplace/features/layouts/skeleton_loader.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/activity_page_controls.dart';
import 'package:cashew_marketplace/shared/widgets/custom_input.dart';
import 'package:cashew_marketplace/shared/widgets/filter_widgets.dart';
import 'package:custom_date_range_picker/custom_date_range_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum EnquiryStatus { pending, confirmed, rejected }

enum EnquiryCategory { bidding, response }

class EnquiryItem {
  final String id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final String product;
  final String date;
  final EnquiryStatus status;
  final String productType;
  final String nutcount;
  final String outturn;
  final String grade;
  final String moistureContent;
  final String yearOfCrop;
  final String pricePerKg;
  final String quantity;
  final String? currency;
  final String totalQuantity;
  final String totalPrice;
  final String? remark;
  final String? buyerRemark;
  final EnquiryCategory category;
  final String currentRole;
  final Map<String, dynamic> rawData;

  const EnquiryItem({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.product,
    required this.date,
    required this.status,
    required this.productType,
    required this.nutcount,
    required this.outturn,
    required this.grade,
    required this.moistureContent,
    required this.yearOfCrop,
    required this.pricePerKg,
    required this.quantity,
    this.currency,
    required this.totalQuantity,
    required this.totalPrice,
    required this.category,
    required this.currentRole,
    required this.rawData,
    this.remark,
    this.buyerRemark,
  });
}

class MyEnquiryScreen extends StatefulWidget {
  final String? type;
  final int? initialTab;
  final bool showInlineFilters;
  final ActivityFilterController? filterController;
  final int? filterPageIndex;
  final ActivitySortController? sortController;
  final int? sortPageIndex;

  const MyEnquiryScreen({
    super.key,
    this.type,
    this.initialTab,
    this.showInlineFilters = true,
    this.filterController,
    this.filterPageIndex,
    this.sortController,
    this.sortPageIndex,
  });

  @override
  State<MyEnquiryScreen> createState() => _MyEnquiryScreenState();
}

class _MyEnquiryScreenState extends State<MyEnquiryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late TextEditingController searchController;

  // State
  Map<String, dynamic>? userData;
  String userId = '';
  bool isbothtype = true;
  bool isbothpost = true;
  String? currentRole;

  // Filters
  bool isFilter = false;
  String selectedFilter = 'All Listings';
  String selectedPostFilter = "All";
  String? _postTypeRole;
  String date = Translate.t("homeScreen.select_date");
  String? type;
  String? startDate;
  bool _isFromDashboard = false;
  String? endDate;
  String? status;
  String? search;
  String statusvalue = 'All';
  bool isinit = true;
  bool is_init = true;
  Timer? _debounce;
  String _sortBy = "Newest";

  // Data
  List<String> statuses = ['All', 'Not viewed', 'Confirmed', 'Rejected'];
  String selectedOrigin = 'All';
  List<String> postTypes = ["All", "Sale", "Purchase"];
  List<String> productTypes = ["All Listings", "RCN", "Kernel"];
  final Function(dynamic) formatToKg = Formatters.formatToKg;
  final Function(dynamic) formatToMoney = Formatters.formatTomoney;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    searchController = TextEditingController();

    _applyRouteType(widget.type);
    is_init = false;

    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getenquires();
      _registerFilterDrawer();
    });
  }

  void _applyRouteType(String? routeType) {
    if (routeType == "RCN" || routeType == "Kernel") {
      _isFromDashboard = true;
      type = routeType;
      selectedFilter = routeType ?? "All Listings";
      return;
    }

    _isFromDashboard = false;
    type = null;
    selectedFilter = "All Listings";
  }

  @override
  void didUpdateWidget(covariant MyEnquiryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      setState(() {
        _applyRouteType(widget.type);
        selectedPostFilter = "All";
        _postTypeRole = null;
        search = null;
        status = null;
        statusvalue = "All";
        selectedOrigin = "All";
        startDate = null;
        endDate = null;
        date = "Select Date";
      });
      getenquires();
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final role = context.watch<SwapUserProvider>().swapedUser;
    final producttype = context.watch<SwapUserProvider>().productType;

    if (producttype == 'Both') {
      isbothtype = true;
    } else {
      isbothtype = false;
      type = producttype;
      selectedFilter = producttype;
      if (widget.type == null) {
        selectedFilter = producttype;
      }
    }
    _isFromDashboard = false;

    if (role == "both") {
      isbothpost = true;
      currentRole = null;
      selectedPostFilter = "All";
    } else {
      currentRole = role == "buyer" ? "stocks" : "requirements";
      isbothpost = false;
      selectedPostFilter = currentRole ?? "All";
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
    _debounce?.cancel();
    _tabController.dispose();
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
        selectedPostFilter != "All" ||
        status != null ||
        startDate != null;
  }

  void _onSearchChanged(String? value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => search = value);
      getenquires();
    });
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

  Future<void> getenquires({bool refreshDynamicFilters = true}) async {
    await _fetchEnquiries(refreshDynamicFilters: refreshDynamicFilters);
  }

  Future<void> _fetchEnquiries({bool refreshDynamicFilters = true}) async {
    userData = await SecureStorageService.getUserData();
    userId = userData?['_id'] ?? '';

    final request = FilterRequest(userId: userId);
    final endpoint = 'dataset/data/responses';
    final apiType = (type == null || type == "All Listings") ? null : type;
    final filterPayload = request.getBuyerEnquiry(
      type: apiType,
      posttype: _postTypeRole,
      status: status,
      search: search,
      fromDate: startDate,
      toDate: endDate,
    );

    await context.read<EnquiryProvider>().fetch(
      userId: userId,
      endpoint: endpoint,
      filterPayload: filterPayload,
    );

    if (refreshDynamicFilters) {
      _refreshDynamicFilters();
    }
  }

  Future<void> _applyDynamicFilterChange(String excludedFilter) async {
    await _fetchEnquiries(refreshDynamicFilters: false);
    _refreshDynamicFilters(excludedFilter: excludedFilter);
  }

  void _refreshDynamicFilters({String? excludedFilter}) {
    if (!mounted) return;

    final enquiries = context.read<EnquiryProvider>().enquries;
    final filters = FiltersDynamic.getFilters(excludedFilter ?? "", [
      <String>[],
      <String>[],
      _typesFromEnquiries(enquiries),
      _postTypesFromEnquiries(enquiries),
    ]);

    setState(() {
      if (excludedFilter != "productTypes") {
        productTypes = List<String>.from(filters[2]);
      }
      if (excludedFilter != "postTypes") {
        postTypes = List<String>.from(filters[3]);
        if (_postTypeRole == "stock_quotes") {
          selectedPostFilter = "Sale";
        } else if (_postTypeRole == "quotes") {
          selectedPostFilter = "Purchase";
        }
      }
      if (excludedFilter != "statuses") {
        statuses = ["All", ..._statusesFromEnquiries(enquiries)];
      }
      _keepSelectedFilterValues();
      isinit = false;
    });
  }

  List<String> _typesFromEnquiries(List<dynamic> enquiries) {
    return enquiries
        .where((enquiry) => enquiry["type"] != null)
        .map<String>((enquiry) => enquiry["type"].toString())
        .toSet()
        .toList();
  }

  List<String> _postTypesFromEnquiries(List<dynamic> enquiries) {
    return enquiries
        .where((enquiry) => enquiry["post_type"] != null)
        .map<String>((enquiry) {
          final value = enquiry["post_type"].toString();
          return value == "stock_quotes" ? "Sale" : "Purchase";
        })
        .toSet()
        .toList();
  }

  List<String> _statusesFromEnquiries(List<dynamic> enquiries) {
    return enquiries
        .where((enquiry) => enquiry["status"] != null)
        .map<String>((enquiry) => enquiry["status"].toString())
        .toSet()
        .toList();
  }

  void _keepSelectedFilterValues() {
    if (!productTypes.contains(selectedFilter)) {
      productTypes = [...productTypes, selectedFilter];
    }
    if (!postTypes.contains(selectedPostFilter)) {
      postTypes = [...postTypes, selectedPostFilter];
    }
    if (!statuses.contains(statusvalue)) {
      statuses = [...statuses, statusvalue];
    }
    if (!statuses.contains(selectedOrigin)) {
      statuses = [...statuses, selectedOrigin];
    }
  }

  void _updateProductFilter(String filterName) {
    setState(() {
      selectedFilter = filterName;
      type = switch (filterName) {
        'All Listings' => null,
        'RCN' => 'RCN',
        'Kernel' => 'Kernel',
        _ => null,
      };
      search = null;
      status = null;
      selectedOrigin = 'All';
      startDate = null;
      endDate = null;
      date = 'Select Date';
    });
    _applyDynamicFilterChange("productTypes");
    _syncFilterIndicator();
  }

  void _updateDateRange(DateTime start, DateTime end) {
    setState(() {
      startDate = start.toUtc().toIso8601String();
      endDate = end.add(const Duration(hours: 6)).toUtc().toIso8601String();
      date =
          '${DateFormat('dd-MM-yyyy').format(start)} - ${DateFormat('dd-MM-yyyy').format(end)}';
    });
    _applyDynamicFilterChange("");
    _syncFilterIndicator();
  }

  void _clearDateRange() {
    setState(() {
      startDate = null;
      endDate = null;
      date = 'Select Date';
    });
    _applyDynamicFilterChange("");
    _syncFilterIndicator();
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
      maximumDate: DateTime.now(),
      backgroundColor: Colors.white,
      primaryColor: AppColors.primary,
      onApplyClick: (start, end) {
        _updateDateRange(start, end.add(const Duration(hours: 18)));
        refreshDrawer?.call();
      },
      onCancelClick: () {
        _clearDateRange();
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

  void _resetFilters() {
    setState(() {
      status = null;
      statusvalue = 'All';
      selectedOrigin = 'All';
      selectedPostFilter = "All";
      type = null;
      selectedFilter = "All Listings";
      _postTypeRole = null;
      startDate = null;
      endDate = null;
      date = 'Select Date';
    });
    _applyDynamicFilterChange("");
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
        setState(() => _sortBy = "Newest");
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

  List<Map<String, dynamic>> _sortVisibleItems(
    List<Map<String, dynamic>> source,
  ) {
    final items = List<Map<String, dynamic>>.from(source);
    int compareByDate(Map<String, dynamic> a, Map<String, dynamic> b) {
      final left = DateTime.tryParse(
        (a['rawData']?['created_on'] ?? '').toString(),
      );
      final right = DateTime.tryParse(
        (b['rawData']?['created_on'] ?? '').toString(),
      );
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
        if (isbothpost) ...[
          ActivityDrawerField(
            icon: Icons.swap_horiz_rounded,
            label: "Post Type",
            child: CustomDropdownFormField<String>(
              label: "Post Type",
              value: selectedPostFilter,
              items: postTypes,
              labels: postTypes,
              onChanged: (value) async {
                setState(() {
                  selectedPostFilter = value ?? "All";
                  if (value == "Sale") {
                    _postTypeRole = "stock_quotes";
                  } else if (value == "Purchase") {
                    _postTypeRole = "quotes";
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
                  _updateProductFilter(value);
                  refreshDrawer?.call();
                }
              },
            ),
          ),
        if (isbothtype) const SizedBox(height: 16),
        ActivityDrawerField(
          icon: Icons.fact_check_outlined,
          label: Translate.t("filter.status"),
          child: CustomDropdownFormField<String>(
            label: Translate.t("filter.status"),
            value: isbothtype ? selectedOrigin : statusvalue,
            items: statuses,
            labels: statuses,
            onChanged: (value) async {
              setState(() {
                if (isbothtype) {
                  selectedOrigin = value!.toString();
                } else {
                  statusvalue = value!.toString();
                }
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
            if (isbothtype && selectedFilter != "All Listings")
              ActivityActiveFilterChip(
                label: selectedFilter,
                onRemove: () {
                  _updateProductFilter("All Listings");
                  refreshDrawer?.call();
                },
              ),
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
            if (status != null)
              ActivityActiveFilterChip(
                label: "Status: $status",
                onRemove: () {
                  setState(() {
                    status = null;
                    statusvalue = "All";
                    selectedOrigin = "All";
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

  EnquiryStatus _mapStatus(String? status) {
    return switch (status?.toLowerCase()) {
      'confirmed' => EnquiryStatus.confirmed,
      'rejected' => EnquiryStatus.rejected,
      _ => EnquiryStatus.pending,
    };
  }

  List<Map<String, dynamic>> _getFilteredItems(
    List<dynamic> data,
    int tabIndex,
  ) {
    try {
      final items = data.map<Map<String, dynamic>>((item) {
        return {'item': _mapToEnquiryItem(item), 'rawData': item};
      }).toList();

      return switch (tabIndex) {
        1 =>
          items
              .where((e) => e['item'].category == EnquiryCategory.bidding)
              .toList(),
        2 =>
          items
              .where((e) => e['item'].category == EnquiryCategory.response)
              .toList(),
        _ => items,
      };
    } catch (e) {
      debugPrint('Error mapping items: $e');
      return [];
    }
  }

  EnquiryItem _mapToEnquiryItem(Map<String, dynamic> item) {
    return item['post_type'] == "stock_quotes"
        ? _mapBuyerEnquiry(item)
        : _mapSellerEnquiry(item);
  }

  EnquiryItem _mapBuyerEnquiry(Map<String, dynamic> item) {
    final isKernel = _isKernel(item['type'] ?? item['type']);

    return EnquiryItem(
      id: item['_id'] ?? '',
      product: isKernel
          ? '${item['grade'] ?? ''} Kernel - ${item['origin'] ?? ''}'
          : '${item['yearOfCrop'] ?? ''} RCN - ${item['origin'] ?? ''}',
      name: '${item["merchant_name"] ?? "Unknown"}',
      company: '${item['merchant_companyName'] ?? 'Unknown'}',
      email: '${item['merchant_email'] ?? item['email'] ?? ""}',
      phone: '${item['merchant_phone'] ?? item['phone'] ?? ""}',
      date: Formatters.formatDate(item['created_on']?.toString() ?? ''),
      status: _mapStatus(item['status']),
      productType: isKernel ? 'Kernel' : 'RCN',
      currentRole: item['enquiry_type'] == 'Quotes' ? 'processor' : 'buyer',
      nutcount: isKernel ? '' : (item['nutCount']?.toString() ?? ''),
      outturn: isKernel ? '' : (item['outTurn']?.toString() ?? ''),
      yearOfCrop: isKernel ? '' : (item['yearOfCrop']?.toString() ?? ''),
      grade: isKernel ? (item['grade']?.toString() ?? '') : '',
      moistureContent: isKernel
          ? (item['moistureContent']?.toString() ?? '')
          : '',
      pricePerKg: formatToMoney(item['expectedPrice'] ?? 0),
      totalQuantity: formatToKg(item['total_quantity'] ?? 0),
      currency: item['currency'] ?? '',
      quantity: formatToKg(item['quantity'] ?? 0),
      totalPrice: formatToMoney(item['price'] ?? 0),
      category: item['type'] == 'bidding'
          ? EnquiryCategory.bidding
          : EnquiryCategory.response,
      remark: item['remark'],
      buyerRemark: item['merchant_remarks'],
      rawData: item,
    );
  }

  EnquiryItem _mapSellerEnquiry(Map<String, dynamic> item) {
    // final responseDetails = _extractMap(item['response_details']);
    // final responseUserDetails = _extractMap(item['user_response_details'][0]);
    final isKernel = _isKernel(item['type']);

    return EnquiryItem(
      id: item['_id'] ?? '',
      product: isKernel
          ? '${item['origin'] ?? ''} - ${item['grade'] ?? ''} Kernel'
          : '${item['origin'] ?? ''} - ${item['yearOfCrop'] ?? ''} RCN',
      name: '${item['buyer_name'] ?? "Unknown"}',
      company: '${item['buyer_companyName'] ?? 'Unknown'}',
      email: '${item['buyer_email'] ?? item['email'] ?? ""}',
      phone: '${item['buyer_phone'] ?? item['phone'] ?? ""}',
      date: Formatters.formatDate(item['created_on']?.toString() ?? ''),
      status: _mapStatus(item['status']),
      productType: isKernel ? 'Kernel' : 'RCN',
      currentRole: item['post_type'] == 'quotes' ? 'processor' : 'buyer',
      nutcount: isKernel ? '' : (item['nutCount']?.toString() ?? ''),
      outturn: isKernel ? '' : (item['outTurn']?.toString() ?? ''),
      yearOfCrop: isKernel ? '' : (item['yearOfCrop']?.toString() ?? ''),
      grade: isKernel ? (item['grade']?.toString() ?? '') : '',
      moistureContent: isKernel
          ? (item['moistureContent']?.toString() ?? '')
          : '',
      currency: item['currency'] ?? '',
      pricePerKg: formatToMoney(
        item['priceperKg'] ?? item['expectedPrice'] ?? 0,
      ),
      totalQuantity: formatToKg(item['total_quantity'] ?? 0),
      quantity: formatToKg(item['quantity'] ?? 0),
      totalPrice: formatToMoney(item['price'] ?? 0),
      category: item['type'] == 'bidding'
          ? EnquiryCategory.bidding
          : EnquiryCategory.response,
      remark: item['remarks'],
      buyerRemark: item['buyer_remarks'] ?? '',
      rawData: item,
    );
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

  bool _isKernel(dynamic type) => type?.toString().toLowerCase() == 'kernel';

  // Widget _buildSearchBar() {
  //   return Padding(
  //     padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
  //     child: searchbarwidget(
  //       searchController: searchController,
  //       onChangedSearch: _onSearchChanged,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('Enquiries', context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // if (!widget.showInlineFilters || isbothtype) _buildSearchBar(),
          if (widget.showInlineFilters) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: isbothtype
                  ? FilterButtons(
                      selected: selectedFilter,
                      onFilterChanged: (value) {
                        _updateProductFilter(value);
                      },
                      onFilterToggle: () {
                        setState(() {
                          isFilter = !isFilter;
                          status = null;
                          selectedOrigin = 'All';
                          startDate = null;
                          endDate = null;
                          date = 'Select Date';
                        });

                        _applyDynamicFilterChange("");
                      },
                    )
                  : Row(
                      children: [
                        // Expanded(
                        //   child: searchbarwidget(
                        //     searchController: searchController,
                        //     onChangedSearch: _onSearchChanged,
                        //   ),
                        // ),
                        // const SizedBox(width: 8),
                        isfilterbutton(
                          onFilterToggle: () {
                            setState(() => isFilter = !isFilter);
                          },
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 5),
          ],
          if (widget.showInlineFilters && isFilter)
            isbothtype
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomDropdownFormField(
                            label: Translate.t("filter.status"),
                            value: selectedOrigin,
                            items: statuses,
                            labels: statuses,
                            onChanged: (value) async {
                              setState(() {
                                selectedOrigin = value!.toString();
                                status = value == "All" ? null : value;
                              });
                              await _applyDynamicFilterChange("statuses");
                              _syncFilterIndicator();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DateRangePicker(
                            date: date,
                            onChangedDate: () => _pickDateRange(context),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomDropdownFormField(
                          label: "Status",
                          value: statusvalue,
                          onChanged: (value) async {
                            setState(() {
                              statusvalue = value!.toString();
                            });
                            if (value == "All") {
                              status = null;
                            } else {
                              status = value;
                            }
                            await _applyDynamicFilterChange("statuses");
                            _syncFilterIndicator();
                          },
                          items: statuses,
                          labels: statuses,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
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
          Expanded(
            child: Consumer<EnquiryProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return const EnquiryCardCompactSkeleton();
                      },
                    ),
                  );
                }
                if (provider.enquries.isEmpty) {
                  return _buildEmptyState(Translate.t("enquiry.no"));
                }
                final visibleItems = _sortVisibleItems(
                  _getFilteredItems(
                    provider.enquries.where((e) {
                      final apiType = (type == null || type == 'All Listings')
                          ? null
                          : type;
                      if (apiType != null && e['type']?.toString() != apiType)
                        return false;
                      if (_postTypeRole != null &&
                          e['post_type']?.toString() != _postTypeRole)
                        return false;
                      if (status != null &&
                          e['status']?.toString().toLowerCase() !=
                              status!.toLowerCase())
                        return false;
                      if (startDate != null && endDate != null) {
                        final d = DateTime.tryParse(
                          e['created_on']?.toString() ?? '',
                        );
                        final from = DateTime.tryParse(startDate!);
                        final to = DateTime.tryParse(endDate!);
                        if (d != null && from != null && to != null) {
                          if (d.isBefore(from) || d.isAfter(to)) return false;
                        }
                      }
                      if (search != null && search!.isNotEmpty) {
                        final q = search!.toLowerCase();
                        final name =
                            (e['merchantname'] ??
                                    e['merchant_name'] ??
                                    e['buyer_name'] ??
                                    '')
                                .toString()
                                .toLowerCase();
                        if (!name.contains(q)) return false;
                      }
                      return true;
                    }).toList(),
                    _tabController.index,
                  ),
                );
                if (visibleItems.isEmpty) {
                  return _buildEmptyState('No enquiries in this category');
                }
                Widget buildCard(int index) {
                  final item = visibleItems[index]['item'] as EnquiryItem;
                  final rawData =
                      visibleItems[index]['rawData'] as Map<String, dynamic>;
                  return EnquiryCardCompact(
                    like:
                        (item.rawData['post_favorite'] as List?)?.contains(
                          userId,
                        ) ??
                        false,
                    onLike: (value) async {
                      await action(
                        id: item.rawData['post_id'],
                        action: "favorite",
                        status: value,
                      );
                      // await getPost(
                      //   load: true,
                      //   refreshDynamicFilters: false,
                      //   suppressLoading: true,
                      // );
                    },
                    onTap: () {},
                    item: item,
                    posttype: rawData['post_type']?.toString(),
                    currentRole: item.rawData['enquiry_type'] != 'stocks'
                        ? 'processor'
                        : 'buyer',
                  );
                }

                if (!context.isTablet && !context.isDesktop) {
                  return ListView.separated(
                    itemCount: visibleItems.length,
                    padding: context.screenPadding,
                    cacheExtent: 1000,
                    separatorBuilder: (_, __) => SizedBox(height: context.v(8)),
                    itemBuilder: (context, index) => buildCard(index),
                  );
                }

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: context.switchValue(
                      mobile: 1,
                      tablet: 2,
                      desktop: 3,
                    ),
                    childAspectRatio: context.switchValue(
                      mobile: 1.25,
                      tablet: 1.4,
                      desktop: 2,
                    ),
                    crossAxisSpacing: context.h(8),
                    mainAxisSpacing: context.v(8),
                  ),
                  itemCount: visibleItems.length,
                  padding: context.screenPadding,
                  cacheExtent: 1000,
                  itemBuilder: (context, index) => buildCard(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class EnquiryCardCompact extends StatefulWidget {
  final EnquiryItem item;
  final String currentRole;
  final String? posttype;
  final bool? like;
  final Function(bool)? onLike;
  final Function()? onTap;

  const EnquiryCardCompact({
    super.key,
    required this.item,
    required this.currentRole,
    required this.like,
    required this.onLike,
    this.onTap,
    this.posttype,
  });

  @override
  State<EnquiryCardCompact> createState() => _EnquiryCardCompactState();
}

class _EnquiryCardCompactState extends State<EnquiryCardCompact> {
  late bool isLiked;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  final Function(dynamic) formatToKg = Formatters.formatToKg;

  final Function(dynamic) formatToMoney = Formatters.formatTomoney;

  final Function(dynamic) _formatDate = Formatters.formatDate;

  Future<void> _toggleLike() async {
    {
      if (!isLiked == true) {
        setState(() => isLiked = !isLiked);
        widget.onLike?.call(isLiked);
        AppToast.showFavoriteToast(context, "Added to favorite");
      } else {
        setState(() => isLiked = !isLiked);
        widget.onLike?.call(isLiked);
        // final shouldRemove = await FavoriteDialog.showUnFavoriteDialog(context);
        AppToast.showFavoriteToast(context, "Removed from favorite");
        // if (shouldRemove == true) {
        // remove favorite
        // } else {}
      }
    }

    if (isLiked) {
      _likeAnimationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    isLiked = widget.like ?? false;
    final compact = !context.isTablet && !context.isDesktop;
    final titleSize = compact ? 13.0 : 14.0;
    final isStock = widget.posttype == "stock_quotes";
    final cardBg = widget.posttype == null
        ? AppColors.surfaceLight
        : isStock
        ? AppColors.sellerCardBg
        : AppColors.buyerCardBg;
    final isMerchantPost = widget.item.rawData["post_post_type"] == "stocks";
    final isrcn = widget.item.rawData['type'] == "RCN";
    final title =
        "${widget.item.rawData['type'] == 'Kernel' ? widget.item.rawData['post_grade'] : (widget.item.rawData['post_yearOfCrop'] ?? widget.item.rawData['post_yearofcrop'])} "
        "${widget.item.rawData['type']} - ${widget.item.rawData['post_origin']}";
    final quantity = isMerchantPost
        ? formatToKg(widget.item.rawData['post_availableqty'] ?? 0)
        : formatToKg(widget.item.rawData['post_requiredqty'] ?? 0);
    final qtyavailablelabel = isMerchantPost
        ? Translate.t("homeScreen.available_from")
        : Translate.t("homeScreen.required_from");
    final currency = widget.item.rawData['post_currency'] ?? '';
    final availableFrom = _formatDate(
      widget.item.rawData['post_created_on'] ?? 'N/A',
    );
    final unit = widget.item.rawData['post_priceunit'] ?? 'kg';

    final pricePerUnit = isMerchantPost
        ? '${formatToMoney(widget.item.rawData['post_sellingprice'] ?? 0)}'
        : '${formatToMoney(widget.item.rawData['post_expectedprice'] ?? 0)}';
    final res = widget.item.rawData;
    return GestureDetector(
      // onTap: () => context.push(RoutePath.myEnquiryView, extra: widget.item),
      onTap: () => res['post_type'] == 'stock_quotes'
          ? context.push(
              RoutePath.buyerResponseviewscreen,
              extra: ['${res['stockId'] ?? res['post_id']}', '${res['_id']}'],
            )
          : context.push(
              RoutePath.sellerResponseviewscreen,
              extra: [
                '${res['requirementId'] ?? res['post_id']}',
                '${res['_id']}',
              ],
            ),
      child: Container(
        margin: EdgeInsets.only(bottom: context.v(6)),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // _buildCardForRole(widget.item.rawData),
            Stack(
              children: [
                // Main Content
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Header Row: Title, Like, Share
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.beige,
                                width: 1,
                              ),
                              color: Colors.white, // optional
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                isrcn
                                    ? AppAssets.iconRcn
                                    : AppAssets.iconKernel,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          // Title & Quantity
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: AppTextThemes
                                                .getLightTextTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                            maxLines: 2,
                                            // overflow: TextOverflow.ellipsis,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Text(
                                              //   widget.item.product,
                                              //   style: AppTextThemes.getLightTextTheme.titleSmall
                                              //       ?.copyWith(
                                              //         color: AppColors.textPrimaryLight,
                                              //         fontWeight: FontWeight.w700,
                                              //         fontSize: titleSize,
                                              //       ),
                                              //   maxLines: 1,
                                              //   overflow: TextOverflow.ellipsis,
                                              // ),
                                              Text(
                                                "${Translate.t("enquiry.enquired")}: ${widget.item.date}",
                                                style: AppTextThemes
                                                    .getLightTextTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: AppColors
                                                          .textSecondaryLight,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // GestureDetector(
                                    //   onTap: _toggleLike,
                                    //   child: Container(
                                    //     padding: const EdgeInsets.all(8),
                                    //     decoration: BoxDecoration(
                                    //       borderRadius: BorderRadius.circular(
                                    //         8,
                                    //       ),
                                    //     ),
                                    //     child: Icon(
                                    //       isLiked
                                    //           ? Icons.favorite
                                    //           : Icons.favorite_outline,
                                    //       color: isLiked
                                    //           ? AppColors.error
                                    //           : AppColors.textSecondary,
                                    //       size: 20,
                                    //     ),
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (widget.posttype != null) ...[
                                _EnquiryPostTypeBadge(
                                  posttype: widget.posttype!,
                                ),
                                const SizedBox(width: 4),
                                _buildSmallStatusBadge(widget.item.status),
                              ],
                            ],
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              // '${widget.pricePerUnit} / ${widget.unit}',
                              '${getCurrencySymbol(currency)} ${pricePerUnit} / ${unit ?? Translate.t("homeScreen.kg")}',
                              style: AppTextThemes.getLightTextTheme.labelLarge
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 1),

            // Content
            Padding(
              padding: EdgeInsets.all(compact ? 10 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                quantity,
                                style: AppTextThemes.getLightTextTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                qtyavailablelabel,
                                style: AppTextThemes.getLightTextTheme.labelMedium
                                    ?.copyWith(
                                      color: AppColors.textHintDark,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                availableFrom,
                                style: AppTextThemes.getLightTextTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactTile(
                          icon: Icons.scale_outlined,
                          label: Translate.t('enquiry.quoted_quantity'),
                          // label: widget.currentRole == 'processor'
                          //     ? Translate.t("enquiry.available_quantity")
                          //     : Translate.t("enquiry.required_quantity"),
                          value: widget.item.quantity,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactTile(
                          icon: Icons.local_offer_outlined,
                          label: Translate.t("enquiry.Price"),
                          value:
                              '${getCurrencySymbol(widget.item.currency)} ${widget.item.pricePerKg}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactTile(
                          icon: Icons.calculate_outlined,
                          label: Translate.t("enquiry.total"),
                          value:
                              '${getCurrencySymbol(widget.item.currency)} ${widget.item.totalPrice}',
                          // isHighlight: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatusBadge(EnquiryStatus status) {
    final (label, color) = switch (status) {
      EnquiryStatus.confirmed => ('Confirmed', AppColors.success),
      EnquiryStatus.rejected => ('Rejected', AppColors.error),
      EnquiryStatus.pending => ('Not Viewed', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCompactTile({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlight
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isHighlight
                    ? AppColors.primary
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
              color: isHighlight
                  ? AppColors.primary
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _EnquiryPostTypeBadge extends StatelessWidget {
  final String posttype;
  const _EnquiryPostTypeBadge({required this.posttype});

  @override
  Widget build(BuildContext context) {
    final isStock = posttype == 'stock_quotes';
    final color = isStock ? AppColors.buyerCardAccent : AppColors.merchantColor;
    final label = isStock ? 'Sale' : 'Purchase';
    final icon = isStock
        ? Icons.storefront_outlined
        : Icons.shopping_cart_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

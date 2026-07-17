import 'dart:async';
import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/filter_request.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/Responsive/responsivea_context.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
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
import 'package:shimmer/shimmer.dart';

class RequirementResponsesPage extends StatefulWidget {
  final String? initialType;
  final String? type;

  const RequirementResponsesPage({super.key, this.type, this.initialType});

  @override
  State<RequirementResponsesPage> createState() =>
      _RequirementResponsesPageState();
}

class _RequirementResponsesPageState extends State<RequirementResponsesPage> {
  Map<String, dynamic> userData = {};
  String userId = "";
  String user = "";
  String _currentRole = "";
  String _productType = "Both";
  ResponseService responseService = ResponseService();
  late final ActivityFilterController _filterController;
  late final ActivitySortController _sortController;
  bool isFilter = false;
  bool isboth = true;
  String selectedFilter = "All Listings";
  String selectedPostFilter = "All";
  String? _postTypeRole;
  String _sortBy = "Newest";
  String date = Translate.t("homeScreen.select_date");
  String? type;
  String? startDate;
  String? endDate;
  bool _isFromDashboard = false;
  String? origin;
  String? status;
  String? search;
  List<Map<String, dynamic>> items = [];
  String? grade;
  String selectedgrade = "All";
  String selectedOrigin = "All";
  String selectedStatus = "All";
  Timer? _debounce;
  bool showActions = true;
  bool is_init = false;
  bool is_initrole = false;
  int responsecounnt = 0;
  Function(dynamic) formatToKg = Formatters.formatToKg;
  Function(dynamic) formatToMoney = Formatters.formatTomoney;
  TextEditingController searchController = TextEditingController();
  List<String> origins = [
    "All",
    "India",
    "Vietnam",
    "Ivory Coast",
    "Nigeria",
    "Brazil",
  ];

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
  List<String> statuses = ["All", "confirmed", "rejected", 'not viewed'];
  List<String> postTypes = ["All", "Sale", "Purchase"];
  List<String> productTypes = [];

  @override
  void initState() {
    super.initState();

    _filterController = ActivityFilterController()..setActivePage(0);
    _sortController = ActivitySortController()..setActivePage(0);
    productTypes = _defaultProductTypes();
    _applyRouteType(widget.type);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerToolbarDrawers();
    });
  }

  void _applyRouteType(String? routeType) {
    if (routeType == "RCN" || routeType == "Kernel") {
      _isFromDashboard = true;
      type = routeType;
      selectedFilter = routeType == "RCN"
          ? Translate.t("filter.rcn")
          : Translate.t("filter.kernel");
      return;
    }

    _isFromDashboard = false;
    type = null;
    selectedFilter = Translate.t("filter.all_listings");
  }

  @override
  void didUpdateWidget(covariant RequirementResponsesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      setState(() {
        _applyRouteType(widget.type);
        selectedOrigin = "All";
        selectedgrade = "All";
        selectedStatus = "All";
        origin = null;
        grade = null;
        status = null;
        search = null;
        startDate = null;
        endDate = null;
        date = Translate.t("homeScreen.select_date");
      });
      getResponse();
      _syncFilterIndicator();
    }
  }

  void _registerToolbarDrawers() {
    _filterController.register(0, _showFilterDrawer);
    _sortController.register(0, _showSortDrawer);
    _syncFilterIndicator();
    _syncSortIndicator();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final swap = context.read<SwapUserProvider>();
    _currentRole = swap.swapedUser;
    final producttype = swap.productType;
    if (producttype != "Both") {
      _productType = producttype;
      isboth = false;
      if (widget.type == null) {
        type = producttype;
        selectedFilter = producttype == "RCN"
            ? Translate.t("filter.rcn")
            : Translate.t("filter.kernel");
      }
    } else {
      isboth = true;
    }
    getResponse();
  }

  void getDropdownvalues() {
    _refreshDynamicFilters();
  }

  void _refreshDynamicFilters({String? excludedFilter}) {
    final List<dynamic> response = context
        .read<ResponseProvider>()
        .responseForPost;
    setState(() {
      if (excludedFilter != "statuses") {
        statuses = ["All", ..._statusesFromResponses(response)];
      }
      if (excludedFilter != "grades") {
        grades = ["All", ..._gradesFromResponses(response)];
      }
      if (excludedFilter != "origins") {
        origins = ["All", ..._originsFromResponses(response)];
      }
      if (excludedFilter != "postTypes") {
        postTypes = ["All", ..._postTypesFromResponses(response)];
        if (_postTypeRole == "stock_quotes") {
          selectedPostFilter = "Sale";
        } else if (_postTypeRole == "quotes") {
          selectedPostFilter = "Purchase";
        }
      }
      if (excludedFilter != "productTypes") {
        productTypes = [
          Translate.t("filter.all_listings"),
          ..._productTypesFromResponses(response),
        ];
      }
      _keepSelectedFilterValues();
    });
  }

  List<String> _defaultProductTypes() {
    return [
      Translate.t("filter.all_listings"),
      Translate.t("filter.rcn"),
      Translate.t("filter.kernel"),
    ];
  }

  List<String> _statusesFromResponses(List<dynamic> response) {
    return response
        .where((item) => item['status'] != null)
        .map<String>((item) => item['status'].toString())
        .toSet()
        .toList();
  }

  List<String> _gradesFromResponses(List<dynamic> response) {
    return response
        .where((item) => item['grade'] != null && item['grade'] != "")
        .map<String>((item) => item['grade'].toString())
        .toSet()
        .toList();
  }

  List<String> _originsFromResponses(List<dynamic> response) {
    return response
        .where((item) => item['origin'] != null)
        .map<String>((item) => item['origin'].toString())
        .toSet()
        .toList();
  }

  List<String> _postTypesFromResponses(List<dynamic> response) {
    return response
        .where((item) => item['post_type'] != null)
        .map<String>((item) {
          final value = item['post_type'].toString();
          return value == "stock_quotes" ? "Sale" : "Purchase";
        })
        .toSet()
        .toList();
  }

  List<String> _productTypesFromResponses(List<dynamic> response) {
    return response
        .where((item) => item['type'] != null)
        .map<String>((item) {
          final value = item['type'].toString();
          if (value == "RCN") return Translate.t("filter.rcn");
          if (value == "Kernel") return Translate.t("filter.kernel");
          return value;
        })
        .toSet()
        .toList();
  }

  void _keepSelectedFilterValues() {
    if (!statuses.contains(selectedStatus)) {
      statuses = [...statuses, selectedStatus];
    }
    if (!grades.contains(selectedgrade)) {
      grades = [...grades, selectedgrade];
    }
    if (!origins.contains(selectedOrigin)) {
      origins = [...origins, selectedOrigin];
    }
    if (!postTypes.contains(selectedPostFilter)) {
      postTypes = [...postTypes, selectedPostFilter];
    }
    if (!productTypes.contains(selectedFilter)) {
      productTypes = [...productTypes, selectedFilter];
    }
  }

  Future<void> onConfirm(String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you want to confirm this quote?"),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await responseService.setStatus(
                          endpoint: "confirm/response/$id",
                          data: {
                            "status": "confirmed",
                            "buyer_remarks": "Quote confirmed by buyer",
                          },
                        );

                        await getResponse();
                        getDropdownvalues();

                        Navigator.pop(context);
                      } catch (e) {
                        // Add proper logging / error handling
                        debugPrint("Confirm failed: $e");
                      }
                    },
                    child: const Text("OK"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> onReject(String id) async {
    TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Remark"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: remarkController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      "Please provide the reason for rejecting the Quote..",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      String remark = remarkController.text;

                      if (remark.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Remark is required")),
                        );
                        return;
                      }

                      await responseService.setStatus(
                        endpoint: "confirm/response/$id",
                        data: {"status": "rejected", "buyer_remarks": remark},
                      );
                      await getResponse();
                      getDropdownvalues();
                      Navigator.pop(context);
                    },
                    child: const Text("Submit"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> getResponse() async {
    userData = await SecureStorageService.getUserData();
    userId = userData['_id'];

    if (userId.isEmpty) {
      userData = await SecureStorageService.getUserData();
      userId = userData['_id'] ?? '';
    }
    final request = FilterRequest(userId: userId, user: "userId");

    final filterPayload = request.getSellerResponse(
      search: search,
      type: type,
      posttype: _postTypeRole,
      status: status,
      grade: grade,
      fromDate: startDate,
      toDate: endDate,
    );
    if (mounted) {
      await context.read<ResponseProvider>().getResponseData(
        userId: userId,
        endpoint: "dataset/data/responses",
        filterPayload: filterPayload,
      );
      if (!is_init) {
        getDropdownvalues();
        is_init = true;
      }
    }
  }

  Future<void> _updateFilter(String filterName) async {
    setState(() {
      selectedOrigin = 'All';
      selectedgrade = 'All';
      selectedStatus = 'All';
      origin = null;
      grade = null;
      status = null;
      search = null;
      startDate = null;
      endDate = null;
      date = 'Select Date';
      selectedFilter = filterName;
    });

    if (filterName == Translate.t("filter.all_listings")) {
      type = null;
    } else if (filterName == Translate.t("filter.rcn")) {
      type = "RCN";
    } else if (filterName == Translate.t("filter.kernel")) {
      type = "Kernel";
    }

    await getResponse();
    _syncFilterIndicator();
  }

  bool get _hasActiveFilters {
    return selectedPostFilter != "All" ||
        type != null ||
        status != null ||
        grade != null ||
        origin != null ||
        search != null ||
        startDate != null;
  }

  void _syncFilterIndicator() {
    _filterController.setPageHasActiveFilter(0, _hasActiveFilters);
  }

  void _syncSortIndicator() {
    _sortController.setPageHasActiveFilter(0, _sortBy != "Newest");
  }

  void _resetFilters() {
    setState(() {
      selectedPostFilter = "All";
      _postTypeRole = null;
      selectedOrigin = "All";
      selectedgrade = "All";
      selectedStatus = "All";
      origin = null;
      grade = null;
      status = null;
      search = null;
      searchController.clear();
      startDate = null;
      endDate = null;
      date = Translate.t("homeScreen.select_date");
      if (widget.type != null) {
        _applyRouteType(widget.type);
      } else if (_productType != "Both") {
        type = _productType;
        selectedFilter = _productType == "RCN"
            ? Translate.t("filter.rcn")
            : Translate.t("filter.kernel");
      } else {
        _applyRouteType(null);
      }
    });
    getResponse();
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

  List<dynamic> _sortResponses(List<dynamic> source) {
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
        ActivityDrawerField(
          icon: Icons.swap_horiz_rounded,
          label: "Post Type",
          child: CustomDropdownFormField<String>(
            label: "Post Type",
            value: selectedPostFilter,
            items: const ["All", "Sale", "Purchase"],
            labels: const ["All", "Sale", "Purchase"],
            onChanged: (value) {
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
              getResponse();
              _syncFilterIndicator();
              refreshDrawer?.call();
            },
          ),
        ),
        const SizedBox(height: 24),
        if (isboth)
          ActivityDrawerField(
            icon: Icons.inventory_2_outlined,
            label: Translate.t("button.select"),
            child: CustomDropdownFormField<String>(
              label: Translate.t("button.select"),
              value: selectedFilter,
              items: [
                Translate.t("filter.all_listings"),
                Translate.t("filter.rcn"),
                Translate.t("filter.kernel"),
              ],
              labels: [
                Translate.t("filter.all_listings"),
                Translate.t("filter.rcn"),
                Translate.t("filter.kernel"),
              ],
              onChanged: (value) {
                if (value == null) return;
                _updateFilter(value);
                refreshDrawer?.call();
              },
            ),
          ),
        if (isboth) const SizedBox(height: 24),
        ActivityDrawerField(
          icon: Icons.search_rounded,
          label: "Search",
          child: searchbarwidget(
            searchController: searchController,
            onChangedSearch: (value) {
              search = value;
              getResponse();
              _syncFilterIndicator();
            },
          ),
        ),
        const SizedBox(height: 24),
        ActivityDrawerField(
          icon: Icons.fact_check_outlined,
          label: "Status",
          child: CustomDropdownFormField<String>(
            label: "Status",
            value: selectedStatus,
            items: statuses,
            labels: statuses,
            onChanged: (value) {
              setState(() {
                selectedStatus = value ?? "All";
                status = value == "All"
                    ? null
                    : value == "not viewed"
                    ? "processing"
                    : value;
              });
              getResponse();
              _syncFilterIndicator();
              refreshDrawer?.call();
            },
          ),
        ),
        const SizedBox(height: 24),
        if (type != "RCN")
          ActivityDrawerField(
            icon: Icons.workspace_premium_outlined,
            label: "Grade",
            child: CustomDropdownFormField<String>(
              label: "Grade",
              value: selectedgrade,
              items: grades,
              labels: grades,
              onChanged: (value) {
                setState(() {
                  selectedgrade = value ?? "All";
                  grade = value == "All" ? null : value;
                });
                getResponse();
                _syncFilterIndicator();
                refreshDrawer?.call();
              },
            ),
          ),
        if (type != "RCN") const SizedBox(height: 24),
        ActivityDrawerField(
          icon: Icons.public_rounded,
          label: "Origin",
          child: CustomDropdownFormField<String>(
            label: "Origin",
            value: selectedOrigin,
            items: origins,
            labels: origins,
            onChanged: (value) {
              setState(() {
                selectedOrigin = value ?? "All";
                origin = value == "All" ? null : value;
              });
              getResponse();
              _syncFilterIndicator();
              refreshDrawer?.call();
            },
          ),
        ),
        const SizedBox(height: 24),
        ActivityDrawerField(
          icon: Icons.date_range_rounded,
          label: "Date Range",
          child: DateRangePicker(
            date: date,
            onChangedDate: () => _openDateRangePickerFromDrawer(refreshDrawer),
          ),
        ),
      ],
    );
  }

  String _formatUtcIso(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  Future<void> _pickDateRange(
    BuildContext context, [
    VoidCallback? refreshDrawer,
  ]) async {
    showCustomDateRangePicker(
      context,
      dismissible: true,
      minimumDate: DateTime.now().subtract(const Duration(days: 3000)),
      maximumDate: DateTime.now().add(const Duration()),
      backgroundColor: Colors.white,
      primaryColor: AppColors.success,
      onApplyClick: (start, end) {
        setState(() {
          endDate = _formatUtcIso(end);
          startDate = _formatUtcIso(start);
          date =
              "${DateFormat('dd-MM-yyyy').format(start)} - ${DateFormat('dd-MM-yyyy').format(end)}";
        });
        getResponse();
        _syncFilterIndicator();
        refreshDrawer?.call();
      },
      onCancelClick: () {
        setState(() {
          endDate = null;
          startDate = null;
          date = "Select Date";
        });
        getResponse();
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

  @override
  void dispose() {
    _filterController.dispose();
    _sortController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('response', context);
    showActions = status == 'new' || status == 'processing';
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(color: AppColors.primaryDark),
          child: ActivityPageToolbar(
            selectedPage: 0,
            pages: const [
              ActivityPageOption(
                value: 0,
                label: "Responses",
                icon: Icons.mark_email_read_outlined,
              ),
            ],
            filterController: _filterController,
            sortController: _sortController,
            onPageChanged: (_) {},
          ),
        ),
        Expanded(
          child: Consumer<ResponseProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const OfferCardSkeleton();
              }

              if (provider.responseForPost.isEmpty) {
                return Center(child: Text(Translate.t("activity.no")));
              }
              responsecounnt = provider.responseForPost.length;
              final visibleResponses = _sortResponses(provider.responseForPost);

              Widget buildCard(dynamic item) {
                final isStock = item['post_type'] == 'stock_quotes';
                final cardBg = isStock
                    ? AppColors.sellerCardBg
                    : AppColors.buyerCardBg;
                return item['post_type'] == 'stock_quotes'
                    ? buildOfferCard(
                        cardBg: cardBg,
                        isStock: isStock,
                        pricelabel: Translate.t("response.quoted_price"),
                        quantitylabel: Translate.t("response.quoted_stock"),
                        onconfirm: () => onConfirm(item['_id']),
                        onreject: () => onReject(item['_id']),
                        onview: () {
                          context
                              .push(
                                RoutePath.myResponseBuyerpost,
                                extra: [
                                  '${item["requirementId"]}',
                                  '${item["_id"]}',
                                ],
                              )
                              .then((_) {
                                getResponse();
                              });
                        },
                        showActions:
                            item['status'] == 'processing' ||
                            item['status'] == 'new' ||
                            item['status'] == 'viewed',
                        title:
                            '${item['grade'] == 'RCN' ? item['product_yearofcrop']?.toString() : item['grade']} ${item['grade'] == 'RCN' ? item['type'] ?? '' : ''}',
                        name:
                            '${item['merchantname'] ?? Translate.t("common.unknown")}',
                        grade: '${item['grade'] ?? item['type']}',
                        status: '${item['status']}',
                        statusColor: item['status'] == 'new'
                            ? AppColors.warning
                            : item['status'] == 'confirmed'
                            ? AppColors.success
                            : AppColors.error,
                        offerPrice: '${formatToMoney(item['priceperKg'])} /kg',
                        quantity:
                            "${formatToKg(item['confirmedKg'] ?? item['quantity'])}",
                        currency: getCurrencySymbol(item['currency']),
                        totalValue: '${formatToMoney(item['priceINR'])}',
                      )
                    : buildOfferCard(
                        cardBg: cardBg,
                        isStock: !isStock,
                        pricelabel: Translate.t("response.quoted_price"),
                        quantitylabel: Translate.t("response.quoted_stock"),
                        onconfirm: () => onConfirm(item['_id']),
                        onreject: () => onReject(item['_id']),
                        onview: () {
                          context
                              .push(
                                RoutePath.myResponseSellerpost,
                                extra: ['${item["stockId"]}', '${item["_id"]}'],
                              )
                              .then((_) {
                                getResponse();
                              });
                        },
                        title:
                            '${item['product_grade'] ?? "${item['product_yearOfCrop']} ${item['type']}"}',
                        name: '${item['buyer_name'] ?? "User name"}',
                        grade:
                            '${item['product_grade'] ?? item['product_type']}',
                        status: '${item['status']}',
                        statusColor: item['status'] == 'processing'
                            ? AppColors.warning
                            : item['status'] == 'confirmed'
                            ? AppColors.success
                            : AppColors.error,
                        showActions:
                            item['status'] == 'processing' ||
                            item['status'] == 'new' ||
                            item['status'] == 'viewed',
                        offerPrice:
                            '${formatToMoney(item['expectedPrice'])} /kg',
                        quantity:
                            "${formatToKg(item['product_confirmkg'] ?? item['quantity'])}",
                        currency: getCurrencySymbol(item['currency']),
                        totalValue: '${formatToMoney(item['price'])}',
                      );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => getResponse(),
                      child: !context.isTablet && !context.isDesktop
                          ? ListView.separated(
                              itemCount: visibleResponses.length,
                              padding: context.screenPadding,
                              cacheExtent: 1000,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: context.v(8)),
                              itemBuilder: (context, index) =>
                                  buildCard(visibleResponses[index]),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: context.switchValue(
                                      mobile: 1,
                                      tablet: 2,
                                      desktop: 3,
                                    ),
                                    childAspectRatio: context.switchValue(
                                      mobile: 1.0,
                                      tablet: 1.1,
                                      desktop: 1.8,
                                    ),
                                    crossAxisSpacing: context.h(8),
                                    mainAxisSpacing: context.v(8),
                                  ),
                              itemCount: visibleResponses.length,
                              padding: context.screenPadding,
                              cacheExtent: 1000,
                              itemBuilder: (context, index) =>
                                  buildCard(visibleResponses[index]),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Summary statistics card
  // Widget _buildSummaryRowCard({required int numberOfresponse}) {
  //   return Padding(
  //     padding: EdgeInsets.symmetric(horizontal: 20),
  //     child: Container(
  //       padding: EdgeInsets.all(24),
  //       decoration: BoxDecoration(
  //         color: AppColors.primarySubtle,
  //         borderRadius: BorderRadius.circular(24),
  //         border: Border.all(color: AppColors.primary.withAlpha(20), width: 1),
  //       ),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(
  //             'TOTAL RESPONSES',
  //             style: AppTextThemes.getLightTextTheme.labelMedium?.copyWith(
  //               color: AppColors.textSecondaryLight,
  //               letterSpacing: 0.8,
  //             ),
  //           ),
  //           Text(
  //             '${numberOfresponse} Offers',
  //             style: AppTextThemes.getLightTextTheme.titleMedium,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildSummaryColumnCard({required int numberOfresponse}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withAlpha(20), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Responses: ',
              style: AppTextThemes.getLightTextTheme.labelMedium?.copyWith(
                color: AppColors.textSecondaryLight,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${numberOfresponse}',
              style: AppTextThemes.getLightTextTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Widget to display an offer card with professional design
  /// Shows company info, offer details, and action buttons
  Widget buildOfferCard({
    required String title,
    required String name,
    required String grade,
    required String status,
    required String quantity,
    required String currency,
    required String pricelabel,
    required String quantitylabel,
    required Color statusColor,
    required Function()? onconfirm,
    required Function()? onreject,
    required Function()? onview,
    required String offerPrice,
    required String totalValue,
    bool showActions = true,
    Color? cardBg,
    bool? isStock,
  }) {
    return InkWell(
      onTap: onview,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg ?? AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildOfferHeader(
              title: title,
              name: name,
              status: status,
              statusColor: statusColor,
              grade: grade,
              isStock: isStock,
            ),

            Divider(
              color: AppColors.borderLight,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),

            _buildOfferDetails(
              quantitylabel: quantitylabel,
              quantity: quantity,
              pricelabel: pricelabel,
              offerPrice: offerPrice,
              totalValue: totalValue,
              currency: currency,
            ),

            Divider(
              color: AppColors.borderLight,
              height: 1,
              indent: 16,
              endIndent: 16,
            ),

            _buildOfferActions(
              onview: onview,
              onreject: onreject,
              onconfirm: onconfirm,
              showActions: showActions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferHeader({
    required String title,
    required String name,
    required String status,
    required Color statusColor,
    required String grade,
    bool? isStock,
  }) {
    final badgeColor = isStock == true
        ? AppColors.buyerCardAccent
        : AppColors.merchantColor;
    final badgeLabel = isStock == true ? 'Sale' : 'Purchase';
    final badgeIcon = isStock == true
        ? Icons.storefront_outlined
        : Icons.shopping_cart_outlined;
    return Padding(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MediaQuery.sizeOf(context).width < 600
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.split(" ")[0],
                              style: AppTextThemes.getLightTextTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.textPrimaryLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '($title)',
                              style: AppTextThemes.getLightTextTheme.titleSmall
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isStock != null) ...[
                              const SizedBox(height: 4),
                              _buildPostTypeBadge(
                                badgeLabel,
                                badgeIcon,
                                badgeColor,
                              ),
                            ],
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: AppTextThemes.getLightTextTheme.titleSmall
                                      ?.copyWith(
                                        color: AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w700,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '($title)',
                                  style: AppTextThemes.getLightTextTheme.titleSmall
                                      ?.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            if (isStock != null) ...[
                              const SizedBox(height: 4),
                              _buildPostTypeBadge(
                                badgeLabel,
                                badgeIcon,
                                badgeColor,
                              ),
                            ],
                          ],
                        ),

                  _buildStatusBadge(status: status, statusColor: statusColor),
                ],
              ),
            ),
          ),

          // const SizedBox(width: 8),

          // _buildGradeBadge(grade: grade),
        ],
      ),
    );
  }

  Widget _buildPostTypeBadge(String label, IconData icon, Color color) {
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

  Widget _buildStatusBadge({
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildGradeBadge({required String grade}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        grade,
        style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildOfferDetails({
    required String quantitylabel,
    required String quantity,
    required String pricelabel,
    required String offerPrice,
    required String totalValue,
    required String currency,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: _buildDetailItem(
              icon: Icons.inventory_2_outlined,
              label: quantitylabel,
              value: quantity,
              valueColor: AppColors.primary,
            ),
          ),

          Container(
            height:
                MediaQuery.sizeOf(context).width < 600 ||
                    MediaQuery.sizeOf(context).width > 1024
                ? 50
                : 20,
            width: 1,
            color: AppColors.borderLight,
            margin: const EdgeInsets.symmetric(horizontal: 5),
          ),

          Expanded(
            child: _buildDetailItem(
              icon: Icons.local_offer_outlined,
              label: pricelabel,
              value: '$currency $offerPrice',
              valueColor: AppColors.primary,
            ),
          ),

          Container(
            height:
                MediaQuery.sizeOf(context).width < 600 ||
                    MediaQuery.sizeOf(context).width > 1024
                ? 50
                : 20,
            width: 1,
            color: AppColors.borderLight,
            margin: const EdgeInsets.symmetric(horizontal: 5),
          ),

          Expanded(
            child: _buildDetailItem(
              icon: Icons.calculate_outlined,
              label: Translate.t("response.total"),
              value: '${currency} ${totalValue}',
              valueColor: AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return MediaQuery.sizeOf(context).width < 900 ||
            MediaQuery.sizeOf(context).width > 1224
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${label}: ',
                    style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
                  overflow: TextOverflow.ellipsis,
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
  }

  Widget _buildOfferActions({
    required Function()? onview,
    required Function()? onreject,
    required Function()? onconfirm,
    required bool showActions,
  }) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Flexible(
          //   child: Container(
          //     width: 100,
          //     height: 40,
          //     child: ElevatedButton.icon(
          //       onPressed: onview,
          //       icon: const Icon(Icons.visibility_outlined, size: 16),
          //       label: Text(
          //         Translate.t("button.view"),
          //         style: AppTextThemes.getLightTextTheme.labelMedium!.copyWith(
          //           color: AppColors.accent,
          //         ),
          //       ),

          //       style: ElevatedButton.styleFrom(
          //         backgroundColor: AppColors.surfaceLight,
          //         foregroundColor: AppColors.accent,
          //         padding: const EdgeInsets.symmetric(
          //           vertical: 5,
          //           horizontal: 10,
          //         ),
          //         shape: RoundedRectangleBorder(
          //           borderRadius: BorderRadius.circular(10),
          //           side: BorderSide(color: AppColors.accent, width: 1.5),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          if (showActions) ...[
            Flexible(
              child: Container(
                width: 150,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onreject,
                  icon: const Icon(Icons.close_outlined, size: 16),
                  label: Text(
                    Translate.t("button.reject"),
                    style: AppTextThemes.getLightTextTheme.labelMedium!.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          if (showActions) ...[
            Flexible(
              child: Container(
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Shimmer.fromColors(
                          direction: ShimmerDirection.rtl,
                          baseColor: AppColors.primary,
                          highlightColor: AppColors.primaryLight,
                          child: Container(color: AppColors.primary),
                        ),
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: onconfirm,
                      icon: const Icon(Icons.check_outlined, size: 16),
                      label: Text(
                        Translate.t("button.confirm"),
                        style: AppTextThemes.getLightTextTheme.labelMedium!
                            .copyWith(color: AppColors.background),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // important
                        shadowColor:
                            Colors.transparent, // remove default shadow
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

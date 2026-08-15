import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/providers/user_provider.dart';
import 'package:hema_fruits/core/repositories/report_repository.dart';
import 'package:hema_fruits/core/repositories/response_repository.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/core/utils/currency.dart';
import 'package:hema_fruits/features/layouts/skeleton_loader.dart';
import 'package:hema_fruits/features/screens/view_screen/view_screen_safety.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/custom.dart';
import 'package:hema_fruits/shared/widgets/response_list_widget.dart';
import 'package:hema_fruits/shared/widgets/view_card_widget.dart';
import 'package:hema_fruits/shared/widgets/view_screen_widget.dart';
import 'package:hema_fruits/shared/widgets/zoomable_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellerResponseViewScreen extends StatefulWidget {
  final List<String> index;
  const SellerResponseViewScreen({required this.index, super.key});

  @override
  State<SellerResponseViewScreen> createState() =>
      _SellerResponseViewScreenState();
}

class _SellerResponseViewScreenState extends State<SellerResponseViewScreen> {
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController remarksController;

  Map<String, dynamic> enquiry = {};
  List<dynamic> responses = [];
  List<String> stockImages = [];
  List<Map<String, dynamic>> uploadedImages = [];
  Map<String, dynamic> responseviewer = {};
  List<String> quickreports = [];
  Map stock_user = {};
  Map<String, dynamic> Settings = {};

  double price = 0.0;
  dynamic userData;
  String available = '';
  String post_id = '';
  String response_id = '';
  bool _isLoadingResponse = true;
  bool _isLoadingResponses = false;
  bool isloadingprofile = true;

  final _formatToKg = Formatters.formatToKg;
  final _formatToMoney = Formatters.formatTomoney;
  ResponseService responseService = ResponseService();

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController();
    priceController = TextEditingController();
    remarksController = TextEditingController();
    final routeIds = safeRoutePair(widget.index);
    post_id = routeIds[0];
    response_id = routeIds[1];
    _initializeData();
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  // ── data loading ─────────────────────────────────────────────────────────────
  Future<void> loaduser() async {
    try {
      final provider = context.read<UserProfProvider>();

      await provider.fetch(
        userId: enquiry['buyerId']?.toString() ?? '',
        endpoint: "entities/filter/users",
        filterPayload: {
          "filter": [
            {
              "clause": "AND",
              "conditions": [
                {
                  "column": "_id",
                  "operator": "EQUALS",
                  "value": enquiry['buyerId']?.toString() ?? '',
                },
              ],
            },
          ],
        },
      );

      if (!mounted) return;

      if (provider.post.isNotEmpty) {
        setState(() {
          stock_user = provider.post.first;
        });
      }
    } catch (e) {
      debugPrint('loaduser error: $e');
    } finally {
      setState(() {
        isloadingprofile = false;
      });
    }
  }

  Future<void> _initializeData() async {
    if (post_id.isEmpty) return;
    try {
      userData = await SecureStorageService.getUserData();
      if (!mounted) return;

      final provider = Provider.of<PostProvider>(context, listen: false);
      // final uid = userData['_id'] as String? ?? '';

      // Seed from cache (instant feedback)
      // final cached =
      //     PostViewUtils.findById(provider.post, post_id) ??
      //     PostViewUtils.findById(provider.viewedpost, post_id);
      // if (cached != null) {
      //   setState(() {
      //     enquiry = cached;
      //   });
      //   await _loadResponses();
      // }

      // Fetch single full record
      try {
        stock_user = context.read<PostProvider>().postList(post_id);
      } catch (e) {
        debugPrintStack();
      }

      setState(() {
        isloadingprofile = false;
      });
      await provider.getSinglePost(endpoint: 'post', id: post_id);
      if (!mounted) return;

      final fresh = PostViewUtils.findById(provider.singlepost, post_id);
      if (fresh != null) {
        setState(() {
          enquiry = fresh;
        });
        final freshId = fresh['_id']?.toString() ?? '';
        if (freshId.isNotEmpty) {
          await action(id: freshId, action: "viewed");
        }
        if (stock_user.isEmpty) {
          await loaduser();
        }
        // loaduser();
        await _loadResponses();
      }
    } catch (e) {
      debugPrint('SellerViewScreen._initializeData error: $e');
    }
  }

  Future<void> action({
    required String id,
    required String action,
    bool? status,
  }) async {
    try {
      String endpoint = "capitalmarket/requirements/$id/$action";
      await context.read<PostProvider>().action(
        endpoint,
        status,
        id,
        action,
        userData['_id'],
      );
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  void loadSettings() async {
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

  Future<void> _loadResponses() async {
    if (_isLoadingResponses || enquiry.isEmpty) return;

    setState(() {
      _isLoadingResponse = true;
      _isLoadingResponses = true;
    });
    try {
      final uid = userData?['_id']?.toString() ?? '';
      final enquiryId = enquiry['_id']?.toString() ?? '';
      if (uid.isEmpty || enquiryId.isEmpty) {
        setState(() {
          _isLoadingResponses = false;
          _isLoadingResponse = false;
        });
        return;
      }

      final postService = PostService();
      final response = await postService.loadResponse(
        endpoint: 'dataset/data/post_response',
        data: {
          'filter': [
            {
              'clause': 'AND',
              'conditions': [
                {'column': 'userId', 'operator': 'EQUALS', 'value': uid},
                {
                  'column': 'requirementId',
                  'operator': 'EQUALS',
                  'value': enquiryId,
                },
              ],
            },
          ],
        },
      );

      if (!mounted) return;
      await ResponseRepository.instance.clearMyResponses(enquiryId);
      await ResponseRepository.instance.saveMyResponses(
        List<Map<String, dynamic>>.from(extractResponseList(response)),
        enquiryId,
      );
      setState(() {
        responses = extractResponseList(response);
        responseviewer = findResponseById(responses, response_id);
        _isLoadingResponses = false;
        _isLoadingResponse = false;
      });
    } catch (e) {
      debugPrint('SellerViewScreen._loadResponses error: $e');
      if (mounted) {
        setState(() {
          _isLoadingResponses = false;
          _isLoadingResponse = false;
        });
      }
    } finally {
      loadSettings();
      quickreport();
      setState(() {
        responses = ResponseRepository.instance.getMyResponses(
          enquiry['_id']?.toString() ?? '',
        );
        responseviewer = findResponseById(responses, response_id);
        _isLoadingResponses = false;
      });
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
  // ── actions ──────────────────────────────────────────────────────────────────

  Future<void> onConfirm(String id) async {
    await responseService.setStatus(
      endpoint: 'confirm/stock_quotes/$id',
      data: {'status': 'confirmed'},
    );
    _loadResponses();
  }

  Future<void> onReject(String id) async {
    await showRejectRemarkDialog(
      context,
      onConfirm: (remark) => responseService.setStatus(
        endpoint: 'confirm/stock_quotes/$id',
        data: {'status': 'rejected', 'buyer_remarks': remark},
      ),
    );
    _loadResponses();
  }

  Future<void> onReport(String reason) async {
    try {
      final postService = ApiDioPostService();
      await postService.getdata(
        endpoint: "entities/reports",
        data: {
          "reason": reason.trim(),
          "requirementId": "${enquiry['_id']}",
          "merchantId": userData?['_id']?.toString() ?? '',
          "type": "Requirement",
        },
      );
    } catch (e) {
      debugPrintStack();
    }
  }

  Future<void> onBlock(String reason) async {
    try {
      final postService = ApiDioPostService();
      await postService.getdata(
        endpoint: "entities/blocked",
        data: {
          "userId": userData?['_id']?.toString() ?? '',
          "block_id": enquiry['buyerId'],
          "reason": reason,
        },
      );
      context.pop();
    } catch (e) {
      debugPrintStack();
    }
  }

  Future<void> _postAction({
    required String id,
    required String action,
    bool? status,
  }) async {
    try {
      await context.read<PostProvider>().action(
        'capitalmarket/requirements/$id/$action',
        status,
        id,
        action,
        userData['_id'],
      );
    } catch (e) {
      debugPrint('SellerViewScreen._postAction error: $e');
    }
  }

  Future<void> _submitQuote() async {
    if (quantityController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final points = (userData?['points'] as int?) ?? 0;

    final int requiredPoints =
        int.tryParse(Settings['EnquiresDetectionPoint']?.toString() ?? '') ?? 0;

    if (points <= requiredPoints) {
      showSubscriptionLimitSheet(
        context,
        dpoint: requiredPoints,
        ptype: Translate.t("popup.type_enquiry"),
      );
      return;
    }

    try {
      final uid = userData?['_id']?.toString() ?? '';
      if (uid.isEmpty) throw Exception('User ID not found');

      await PostService().dynamicPost(
        collectionName: 'quotes',
        queryType: 'enquiries',
        data: {
          '_id': 'SEQ|QUOTE',
          "quantity":
              int.tryParse(
                quantityController.text.replaceAll(',', '').trim(),
              ) ??
              0,
          "priceperKg":
              int.tryParse(priceController.text.replaceAll(',', '').trim()) ??
              0,
          "priceINR": price.toInt(),
          'remarks': remarksController.text.trim(),
          'requirementId': enquiry['_id']?.toString() ?? '',
          'userId': uid,
          'status': 'processing',
          'buyerId': enquiry['buyerId']?.toString() ?? '',
          'type': enquiry['type']?.toString() ?? '',
          'is_merchant_status_viewed': false,
          'is_buyer_viewed_status': false,
          'isStatusViewed': false,
        },
      );

      quantityController.clear();
      priceController.clear();
      remarksController.clear();
      setState(() => price = 0.0);
      await _initializeData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote submitted successfully')),
        );
      }
    } catch (e) {
      debugPrint('SellerViewScreen._submitQuote error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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

  void _showMakeOfferDrawer() async {
    // BUG FIX: null-safe points check (was: `userData['points'] as int <= 14 || userData['points'] == null`)
    // await getUser(userData?['_id']);
    userData = await SecureStorageService.getUserData();
    final points = (userData?['points'] as int?) ?? 0;
    final city = userData?['natureOfBusiness'];
    if (userData?['points'] == null &&
        (userData?['natureOfBusiness'] != 'Agent' || city == null)) {
      showCompleteProfilePopup(
        context,
        city == null
            ? Translate.t("popup.profile_update")
            : Translate.t("popup.business_profile_update"),
        city == null
            ? Translate.t("popup.go_to_profile")
            : Translate.t("popup.go_to_business_profile"),
        city == null ? RoutePath.personalInfo : RoutePath.businessInfo,
      );
      return;
    }
    final int requiredPoints =
        int.tryParse(Settings['EnquiresDetectionPoint']?.toString() ?? '') ?? 0;

    if (points <= requiredPoints) {
      showSubscriptionLimitSheet(
        context,
        dpoint: requiredPoints,
        ptype: Translate.t("popup.type_enquiry"),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // const SizedBox(height: 16),
                    // Text(
                    //   'Make a Quote',
                    //   style: AppTextThemes.getLightTextTheme.headlineMedium
                    //       ?.copyWith(color: AppColors.textPrimaryLight),
                    // ),
                  ],
                ),
              ),
              MakeOfferForm(
                maxQuantity: available,
                quantityController: quantityController,
                priceController: priceController,
                currency: getCurrencySymbol(enquiry['currency'] ?? ""),
                remarksController: remarksController,
                negotiatePrice: enquiry['lowerbit'] ?? false,
                minQuantity: PostViewUtils.getString(
                  enquiry['minimumqty'],
                  fallback: '0',
                ),
                sellingprice: PostViewUtils.getString(
                  enquiry['expectedprice'],
                  fallback: '0',
                ),
                onTotalChanged: (v) => setState(() => price = v),
                onTap: () {
                  _submitQuote();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null || dateValue.toString().isEmpty) {
        return 'N/A';
      }
      final dateTime = DateTime.parse(dateValue.toString()).toLocal();
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return 'N/A';
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case "new":
        return AppColors.warning;
      case "approved":
        return AppColors.success;
      case "rejected":
        return AppColors.error;
      default:
        return AppColors.textTertiaryLight;
    }
  }

  Map<String, dynamic>? getUserById(List<dynamic> list, String id) {
    try {
      return list.firstWhere((element) => element["_id"] == id);
    } catch (e) {
      return null;
    }
  }

  int _parseInt(dynamic value, {int defaultValue = 0}) {
    try {
      if (value == null) return defaultValue;
      if (value is int) return value;
      return int.parse(value.toString());
    } catch (e) {
      return defaultValue;
    }
  }

  String _getString(dynamic value, {String defaultValue = 'N/A'}) {
    try {
      if (value == null) return defaultValue;
      return value.toString().trim();
    } catch (e) {
      return defaultValue;
    }
  }

  Widget _buildResponseHistory(ScrollController scrollController) {
    if (_isLoadingResponses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (responses.isEmpty) {
      return Center(
        child: Text(
          Translate.t("view.no_response"),
          style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    return FilteredResponseHistory(
      // scrollController: scrollController,
      isLoading: _isLoadingResponses,
      responses: responses,
      itemBuilder: (context, res) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            color: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.borderLight, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ResponseItem(
                img: ResponseNameResolver.getimage(responseviewer),
                onconfirm: () => onConfirm(res['_id'] ?? ""),
                onreject: () => onReject(res['_id'] ?? ""),
                onview: () {
                  context.pop();
                  context
                      .push(
                        RoutePath.sellerResponseviewscreen,
                        extra: [
                          '${res['requirementId'] ?? ""}',
                          '${res['_id'] ?? ""}',
                        ],
                      )
                      .then((_) {
                        _initializeData();
                      });
                },
                showActions: false,
                currency: getCurrencySymbol(
                  safeMap(res['response_details'] ?? "")['currency'] ?? "",
                ),
                isrejected: (res['status']?.toLowerCase() ?? "") == "rejected",
                avatar: Icons.person,
                avatarBg: AppColors.accent,
                senderName: res['merchantname'] ?? "",
                timestamp: _formatDate(res['created_on'] ?? ""),
                enquiriesRemark:
                    '${res['remarks'] ?? res['remark'] ?? "No Remarks"}',
                responseRemark:
                    res['buyer_remarks']?.toString() ?? "No Remarks",
                status: _getString(
                  res['status'] ?? "",
                  defaultValue: "unknown",
                ).toUpperCase(),
                statusColor: getStatusColor(
                  _getString(res['status'], defaultValue: "unknown"),
                ),
                quantity: Formatters.formatToKg(res['supplyQtyKg'] ?? ""),

                price: Formatters.formatTomoney(res['priceperKg'] ?? "0"),
                total: Formatters.formatTomoney(res['priceINR'] ?? "0"),
                totalColor: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getFirstFromList(dynamic list, {required String defaultValue}) {
    try {
      if (list is List && list.isNotEmpty) {
        return list[0].toString();
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  void _showResponseHistoryDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Translate.t("view.view_all"),
                    style: AppTextThemes.getLightTextTheme.headlineMedium
                        ?.copyWith(color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 16),
                  Flexible(child: _buildResponseHistory(scrollController)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZoomablePages(
        child: SingleChildScrollView(
          child: Consumer<PostProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    children: [
                      isloadingprofile
                          ? TradeHeadersSkeleton()
                          : _buildTradeHeader(provider),
                      const SizedBox(height: 16),
                      const ViewScreenSkeleton(),
                    ],
                  ),
                );
              }

              if (provider.singlepost.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Post not found',
                          style: AppTextThemes.getLightTextTheme.bodyLarge
                              ?.copyWith(color: AppColors.textPrimaryLight),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Go Back',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              enquiry = provider.singlepost.first;
              available =
                  '${PostViewUtils.parseInt(enquiry['requiredqty'] ?? "0") - PostViewUtils.parseInt(enquiry['confirmedKg'] ?? "0")}';

              final minimumqty =
                  PostViewUtils.parseInt(available) >
                      PostViewUtils.parseInt(enquiry['minimumqty'] ?? "0")
                  ? '${enquiry['minimumqty'] ?? "0"}'
                  : available;

              final rawImages = (enquiry['images'] ?? []);
              if (rawImages is List) {
                uploadedImages = rawImages
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
                stockImages = uploadedImages
                    .map((e) => e['storage_name']?.toString() ?? '')
                    .where((s) => s.isNotEmpty)
                    .toList();
              }

              final isKernel = enquiry['type'] == 'Kernel';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        isloadingprofile
                            ? TradeHeadersSkeleton()
                            : _buildTradeHeader(provider),
                        // const SizedBox(height: 16),
                        _buildProductDetailsCard(),
                        const SizedBox(height: 8),
                        if (!isKernel) ...[
                          PostTwoColumnCards(
                            availableLabel: Translate.t("view.PURCHASED"),
                            availableValue: _formatToKg(
                              enquiry['confirmedKg'] ?? '0',
                            ),
                            minimumQtyValue: _formatToKg(minimumqty),
                          ),
                          const SizedBox(height: 8),
                          PostDeliveryLocationCard(
                            label: Translate.t("view.PURCHASED"),
                            location: PostViewUtils.getString(
                              '${enquiry['location'] ?? ""} ${enquiry['pincode'] ?? ""}',
                            ),
                            confirmedKg: _formatToKg(
                              enquiry['confirmedKg'] ?? '0',
                            ),
                          ),
                          const SizedBox(height: 8),
                          PostDatesSection(
                            postedDate: PostViewUtils.formatDate(
                              enquiry['orderDate'],
                            ),
                            untilDate: PostViewUtils.formatDate(
                              enquiry['deliverydate'],
                            ),
                          ),
                        ],
                        if (stockImages.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ImageCardViewer(imageUrls: stockImages),
                          ),
                        const SizedBox(height: 8),
                        // MediaQuery.sizeOf(context).width < 900
                        !_isLoadingResponse
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ).copyWith(bottom: 8),
                                child: Card(
                                  elevation: 2,
                                  color: AppColors.surfaceLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: AppColors.borderLight,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: ResponseItem(
                                      img: ResponseNameResolver.getimage(
                                        responseviewer,
                                      ),
                                      onview: () {
                                        context
                                            .push(RoutePath.profile)
                                            .then((_) => _initializeData());
                                      },
                                      onconfirm: () => onConfirm(
                                        responseviewer['_id'] ?? '',
                                      ),
                                      onreject: () =>
                                          onReject(responseviewer['_id'] ?? ''),
                                      currency: getCurrencySymbol(
                                        responseviewer.isNotEmpty
                                            ? safeMap(
                                                responseviewer['response_details'],
                                              )['currency']
                                            : "",
                                      ),
                                      showActions: false,
                                      noview: true,

                                      isrejected:
                                          responseviewer['status'] ==
                                              "rejected" ||
                                          responseviewer['status'] ==
                                              "Rejected",
                                      avatar: Icons.person,
                                      avatarBg: AppColors.accent,
                                      senderName:
                                          responseviewer['merchantname'],
                                      timestamp: _formatDate(
                                        responseviewer['created_on'],
                                      ),
                                      enquiriesRemark:
                                          '${responseviewer['remarks'] ?? responseviewer['remark'] ?? "No Remarks"}',
                                      responseRemark:
                                          responseviewer['buyer_remarks']
                                              ?.toString() ??
                                          "No Remarks",
                                      status: _getString(
                                        responseviewer['status'],
                                        defaultValue: "unknown",
                                      ).toUpperCase(),
                                      statusColor: getStatusColor(
                                        _getString(
                                          responseviewer['status'],
                                          defaultValue: "unknown",
                                        ),
                                      ),

                                      quantity: Formatters.formatToKg(
                                        responseviewer['quantity'] ?? '0',
                                      ),
                                      price: Formatters.formatTomoney(
                                        responseviewer['expectedPrice'] ?? '0',
                                      ),
                                      total: Formatters.formatTomoney(
                                        responseviewer['price'] ?? '0',
                                      ),
                                      totalColor: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : OrderCardSkeleton(),
                        // : SizedBox(),
                        PostActionButtons(
                          labelmessage: enquiry['lowerbit'] ?? false
                              ? Translate.t("button.bidding")
                              : Translate.t("button.Interested"),
                          isMyPost: false,
                          noresponse: false,
                          onInterested: _showMakeOfferDrawer,
                          onResponseHistory: _showResponseHistoryDrawer,
                        ),
                        responses.isEmpty
                            // MediaQuery.sizeOf(context).width < 900
                            ? Center(
                                child: Text(
                                  "No Response",
                                  style: AppTextThemes
                                      .getLightTextTheme
                                      .titleSmall!
                                      .copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                ),
                              )
                            : SizedBox(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // responses.isEmpty
                  //     ? MediaQuery.sizeOf(context).width < 900
                  //           ? SizedBox()
                  //           : Expanded(
                  //               child: Center(
                  //                 child: Text(
                  //                   "No Response",
                  //                   style: AppTextThemes
                  //                       .getLightTextTheme
                  //                       .titleSmall!
                  //                       .copyWith(
                  //                         color: AppColors.textSecondaryLight,
                  //                       ),
                  //                 ),
                  //               ),
                  //             )
                  //     : MediaQuery.sizeOf(context).width < 900
                  //     ? SizedBox()
                  //     : Expanded(
                  //         child: Padding(
                  //           padding: const EdgeInsets.symmetric(
                  //             horizontal: 16,
                  //             vertical: 12,
                  //           ),
                  //           child: Column(
                  //             mainAxisSize: MainAxisSize.min,
                  //             children: [
                  //               Container(
                  //                 width: 40,
                  //                 height: 5,
                  //                 decoration: BoxDecoration(
                  //                   color: AppColors.borderLight,
                  //                   borderRadius: BorderRadius.circular(10),
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 16),
                  //               Text(
                  //                 Translate.t("view.view_all"),
                  //                 style: AppTextThemes
                  //                     .getLightTextTheme
                  //                     .headlineMedium
                  //                     ?.copyWith(
                  //                       color: AppColors.textPrimaryLight,
                  //                     ),
                  //               ),
                  //               const SizedBox(height: 16),
                  //               Flexible(
                  //                 child: !_isLoadingResponse
                  //                     ? Padding(
                  //                         padding: const EdgeInsets.symmetric(
                  //                           horizontal: 16,
                  //                         ).copyWith(bottom: 8),
                  //                         child: Card(
                  //                           elevation: 2,
                  //                           color: AppColors.surfaceLight,
                  //                           shape: RoundedRectangleBorder(
                  //                             borderRadius:
                  //                                 BorderRadius.circular(12),
                  //                             side: BorderSide(
                  //                               color: AppColors.borderLight,
                  //                               width: 1,
                  //                             ),
                  //                           ),
                  //                           child: Padding(
                  //                             padding: const EdgeInsets.all(16),
                  //                             child: ResponseItem(
                  //                               img:
                  //                                   ResponseNameResolver.getimage(
                  //                                     responseviewer,
                  //                                   ),
                  //                               onconfirm: () => onConfirm(
                  //                                 responseviewer['_id'],
                  //                               ),
                  //                               onreject: () => onReject(
                  //                                 responseviewer['_id'],
                  //                               ),

                  //                               onview: () {
                  //                                 context
                  //                                     .push(RoutePath.profile)
                  //                                     .then(
                  //                                       (_) =>
                  //                                           _initializeData(),
                  //                                     );
                  //                               },
                  //                               currency: getCurrencySymbol(
                  //                                 safeMap(
                  //                                       responseviewer['response_details'],
                  //                                     )['currency'] ??
                  //                                     "",
                  //                               ),
                  //                               showActions: false,
                  //                               noview: true,

                  //                               isrejected:
                  //                                   responseviewer['status'] ==
                  //                                       "rejected" ||
                  //                                   responseviewer['status'] ==
                  //                                       "Rejected",
                  //                               avatar: Icons.person,
                  //                               avatarBg: AppColors.accent,
                  //                               senderName:
                  //                                   responseviewer['merchantname'],
                  //                               timestamp: _formatDate(
                  //                                 responseviewer['created_on'],
                  //                               ),
                  //                               enquiriesRemark:
                  //                                   '${responseviewer['remarks'] ?? responseviewer['remark'] ?? "No Remarks"}',
                  //                               responseRemark:
                  //                                   responseviewer['buyer_remarks']
                  //                                       ?.toString() ??
                  //                                   "No Remarks",
                  //                               status: _getString(
                  //                                 responseviewer['status'],
                  //                                 defaultValue: "unknown",
                  //                               ).toUpperCase(),
                  //                               statusColor: getStatusColor(
                  //                                 _getString(
                  //                                   responseviewer['status'],
                  //                                   defaultValue: "unknown",
                  //                                 ),
                  //                               ),
                  //                               quantity: Formatters.formatToKg(
                  //                                 responseviewer['quantity'],
                  //                               ),
                  //                               price: Formatters.formatTomoney(
                  //                                 responseviewer['expectedPrice'],
                  //                               ),
                  //                               total: Formatters.formatTomoney(
                  //                                 responseviewer['price'],
                  //                               ),
                  //                               totalColor: AppColors.primary,
                  //                             ),
                  //                           ),
                  //                         ),
                  //                       )
                  //                     : OrderCardSkeleton(),
                  //               ),
                  //             ],
                  //           ),
                  //         ),
                  //       ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── sub-widgets ──────────────────────────────────────────────────────────────

  Widget _buildTradeHeader(PostProvider provider) {
    String header = "View Screen";
    if (stock_user.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_ios),
            ),
          ),
          Expanded(child: Container()),
        ],
      ); // or shimmer/header skeleton
    }

    header = "${stock_user["user_name"] ?? stock_user['name']}";

    return TradeHeaders(
      isMyPost: false,
      tradeId: header,
      onReport: (reason) {
        onReport(reason);
      },
      onBlock: (String reason) {
        onBlock(reason);
      },
      reportReasons: quickreports,
      email: stock_user['email'] ?? "",
      phone: stock_user['phone'] ?? "",
      imageUrl: stock_user['profilePicture'] ?? "",
      count:
          "${(enquiry["viewed"] != null ? enquiry["viewed"].length : 0) ?? 0} views",
      onTap: () {
        context.push(
          RoutePath.userProfile,
          extra: [stock_user['userId'] ?? "", stock_user],
        );
        // showDialog(
        //   context: context,
        //   builder: (_) => ProfileDialog(
        //     name: stock_user["merchantname"],
        //     email: stock_user['email'],
        //     phone: stock_user['phone'],
        //     company: stock_user['companyName'],
        //     imageUrl: stock_user['profilePicture'],
        //     onViewProfile: () {
        //       context.push(RoutePath.userProfile, extra: stock_user['userid']);
        //     },
        //   ),
        // );
      },
    );
  }

  Widget _buildProductDetailsCard() {
    final list = List<Map<String, dynamic>>.from(enquiry['biddings'] ?? []);

    final currentPrice = list.isEmpty
        ? 0
        : list
              .map((e) => int.tryParse(e['price'].toString()) ?? 0)
              .reduce((a, b) => a > b ? a : b);
    final uid = userData?['_id']?.toString() ?? '';

    if (enquiry['type'] == 'Multiple') {
      final postedRaw = enquiry['orderDate'] ?? enquiry['created_on'] ?? "";
      final expireRaw = enquiry['deliverydate'] ?? enquiry['expiredate'] ?? "";
      return ProductCardMultiple(
        products: enquiry['products'] ?? [],
        shipmentmethod: enquiry['shippingmethod'] ?? "",
        shipmenttype: enquiry['shipmenttype'] ?? "",
        isgst: enquiry['priceincludegst'] ?? false,
        isMypost: false,
        negotiatePrice: enquiry['negotiateprice'] ?? false,
        quantity: _formatToKg(available),
        postedDate: PostViewUtils.formatDate(postedRaw),
        expireDate: PostViewUtils.formatDate(expireRaw),
        minimumOrder: _formatToKg(enquiry['minimumqty']),
        stockLocation: '${enquiry['location'] ?? ""} ${enquiry['pincode'] ?? ""}',
        currency: getCurrencySymbol(enquiry['currency'] ?? ""),
        location: PostViewUtils.getString('${enquiry['origin']}'),
        onbiddinglist: () {
          showBiddings(context, list);
        },
      );
    }

    if (enquiry['type'] == 'Kernel') {
      final postedRaw = enquiry['orderDate'] ?? enquiry['created_on'] ?? "";
      final expireRaw = enquiry['deliverydate'] ?? enquiry['expiredate'] ?? "";
      return ProductCardKernel(
        shipmentmethod: enquiry['shippingmethod'] ?? "",
        shipmenttype: enquiry['shipmenttype'] ?? "",
        isgst: enquiry['priceincludegst'] ?? false,
        isavailablestock: false,
        isMypost: false,
        unit: enquiry['priceunit'] ?? "Kg",
        negotiatePrice: enquiry['lowerbit'] ?? false,
        initialprice: _formatToMoney(
          enquiry['initialprice'] ?? enquiry['sellingprice'] ?? "0",
        ),
        confirmedKg: PostViewUtils.parseInt(
          enquiry['confirmedKg'] ?? "0",
        ).toString(),
        location: PostViewUtils.getString(
          '${enquiry['flag'] ?? ""}  ${enquiry['origin'] ?? ""}',
        ),
        moistureContent: PostViewUtils.getString(
          enquiry['moistureContent'] ?? "0",
        ),
        currency: getCurrencySymbol(enquiry['currency'] ?? ""),
        isliked: ((enquiry['favorite'] ?? []) as List?)?.contains(uid) ?? false,
        onLike: (v) =>
            _postAction(id: enquiry['_id'], action: 'favorite', status: !v),
        description: enquiry['description']?.toString() ?? '',
        productName: '${enquiry['grade'] ?? ""}',
        quantity: _formatToKg(available),
        originGrade: 'Origin / Grade',
        postedDate: PostViewUtils.formatDate(postedRaw),
        expireDate: PostViewUtils.formatDate(expireRaw),
        availablelabel: 'REQUIRED',
        availableStock: _formatToKg(available),
        minimumOrder: _formatToKg(enquiry['minimumqty'] ?? "0"),
        stockLocation:
            '${enquiry['location'] ?? ""} ${enquiry['pincode'] ?? ""}',
        pricePerKg: currentPrice == 0
            ? _formatToMoney(enquiry['expectedprice'] ?? "")
            : _formatToMoney(currentPrice),
        onbiddinglist: () {
          showBiddings(context, list);
        },
      );
    }

    final productType = enquiry['type'] == 'Kernel'
        ? '${PostViewUtils.getString(enquiry['grade'], fallback: '')} ${Translate.t("filter.kernel")}'
        : '${Translate.t("filter.rcn")} (${PostViewUtils.getString(enquiry['yearOfCrop'], fallback: '')})';

    return PostMainHeaderCard(
      shipmentmethod: enquiry['shippingmethod'] ?? "",
      shipmenttype: enquiry['shipmenttype'] ?? "",
      isgst: enquiry['priceincludegst'] ?? false,
      isMyPost: false,
      negotiatePrice: enquiry['lowerbit'] ?? false,
      unit: enquiry['priceunit'] ?? "Kg",
      isLiked: ((enquiry['favorite'] ?? []) as List?)?.contains(uid) ?? false,
      onLike: (v) =>
          _postAction(id: enquiry['_id'], action: 'favorite', status: v),
      origin: PostViewUtils.getString(
        '${enquiry['flag'] ?? ""}  ${enquiry['origin'] ?? ""}',
      ),
      productType: productType,
      initialprice: _formatToMoney(
        enquiry['initialprice'] ?? enquiry['sellingprice'] ?? "",
      ),
      requiredQty: PostViewUtils.getString(_formatToKg(available)),
      currency: getCurrencySymbol(enquiry['currency'] ?? ""),
      description: PostViewUtils.getString(enquiry['description'] ?? ""),
      budgetPrice: PostViewUtils.getString(
        currentPrice == 0
            ? _formatToMoney(enquiry['expectedprice'] ?? "")
            : _formatToMoney(currentPrice),
      ),
      confirmedKg: PostViewUtils.parseInt(
        enquiry['confirmedKg'] ?? "",
      ).toString(),
      outTurn: PostViewUtils.getString(enquiry['outTurn'] ?? ""),
      moistureContent: PostViewUtils.getString(
        enquiry['moistureContent'] ?? "",
        fallback: '0',
      ),
      nutCount: PostViewUtils.getString(enquiry['nutCount'] ?? ""),
      onbiddinglist: () {
        showBiddings(context, list);
      },
    );
  }

  void showBiddings(BuildContext context, List<Map<String, dynamic>> biddings) {
    final sortedBiddings = List<Map<String, dynamic>>.from(biddings)
      ..sort((a, b) => (b['price'] as int).compareTo(a['price'] as int));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * .7,
          child: Column(
            children: [
              const SizedBox(height: 5),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bidding History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: sortedBiddings.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final bid = sortedBiddings[index];
                    final image = bid['profile'] ?? "";
                    final formattedDate = DateFormat('dd MMM yyyy hh:mm a')
                        .format(DateTime.parse(bid['date'] ?? "").toLocal())
                        .toLowerCase();
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.primary,
                        backgroundImage: image != null
                            ? image.startsWith('http')
                                  ? CachedNetworkImageProvider(image)
                                  : CachedNetworkImageProvider(
                                      '${AppConfig.imageurl}$image',
                                    )
                            : null,
                        child: image != null
                            ? null
                            : Text(
                                (bid['name'] ?? 'Unknown')[0],
                                style: AppTextThemes
                                    .getLightTextTheme
                                    .titleMedium!
                                    .copyWith(),
                              ),
                      ),
                      title: Text(
                        bid['name'] ?? 'Unknown',
                        style: AppTextThemes.getLightTextTheme.titleMedium!
                            .copyWith(),
                      ),
                      subtitle: Text(
                        formattedDate,
                        style: AppTextThemes.getLightTextTheme.labelMedium,
                      ),
                      trailing: Text(
                        '₹${Formatters.formatTomoney(bid['price'] ?? "0")}',
                        style: AppTextThemes.getLightTextTheme.titleLarge!
                            .copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _safeDateFormat(dynamic value) {
    try {
      if (value == null || value.toString().isEmpty) return '';
      return DateFormat('yyyy-MM-dd').format(DateTime.parse(value.toString()));
    } catch (_) {
      return '';
    }
  }
}

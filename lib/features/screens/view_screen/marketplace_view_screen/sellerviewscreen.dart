import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/config/app_config.dart';
import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/providers/language_provider.dart';
import 'package:cashew_marketplace/core/providers/user_provider.dart';
import 'package:cashew_marketplace/core/repositories/report_repository.dart';
import 'package:cashew_marketplace/core/repositories/response_repository.dart';
import 'package:cashew_marketplace/core/repositories/settings_repository.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/offline_queue_service.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/core/utils/currency.dart';
import 'package:cashew_marketplace/features/layouts/skeleton_loader.dart';
import 'package:cashew_marketplace/features/screens/view_screen/view_screen_safety.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/custom.dart';
import 'package:cashew_marketplace/shared/widgets/view_card_widget.dart';
import 'package:cashew_marketplace/shared/widgets/response_list_widget.dart';
import 'package:cashew_marketplace/shared/widgets/view_screen_widget.dart';
import 'package:cashew_marketplace/shared/widgets/zoomable_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellerViewScreen extends StatefulWidget {
  final String index;
  const SellerViewScreen({this.index = "", super.key});

  @override
  State<SellerViewScreen> createState() => _SellerViewScreenState();
}

class _SellerViewScreenState extends State<SellerViewScreen> {
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController remarksController;

  Map<String, dynamic> enquiry = {};
  List<dynamic> responses = [];
  List<String> stockImages = [];
  List<String> quickreports = [];
  List<Map<String, dynamic>> uploadedImages = [];
  Map stock_user = {};
  Map<String, dynamic> Settings = {};

  double price = 0.0;
  dynamic userData;
  String available = '';
  bool _isLoadingResponses = false;
  bool isloadingprofile = true;

  final _formatToKg = Formatters.formatToKg;
  final _formatToMoney = Formatters.formatTomoney;
  ResponseService responseService = ResponseService();

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeData();
    quantityController = TextEditingController();
    priceController = TextEditingController();
    remarksController = TextEditingController();
    OfflineQueueService.onQueueFlushed.addListener(_loadResponses);
  }

  @override
  void dispose() {
    OfflineQueueService.onQueueFlushed.removeListener(_loadResponses);
    quantityController.dispose();
    priceController.dispose();
    remarksController.dispose();
    super.dispose();
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

  // ── data loading ─────────────────────────────────────────────────────────────
  Future<void> loaduser() async {
    try {
      final provider = context.read<UserProfProvider>();

      await provider.fetch(
        userId: enquiry['userid']?.toString() ?? '',
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
          stock_user = provider.post[0];
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
    try {
      final provider = Provider.of<PostProvider>(context, listen: false);
      try {
        stock_user = provider.postList(widget.index);
      } catch (e) {
        debugPrintStack();
      }

      setState(() {
        isloadingprofile = false;
      });
      await provider.getSinglePost(endpoint: 'post', id: widget.index);
      if (!mounted) return;

      final fresh = PostViewUtils.findById(provider.singlepost, widget.index);
      if (fresh != null) {
        setState(() {
          enquiry = fresh;
        });
        if (stock_user.isEmpty) {
          await loaduser();
        }
        userData = await SecureStorageService.getUserData();
        if (!mounted) return;

        // final uid = userData['_id'] as String? ?? '';

        // Seed from cache (instant feedback)
        // final cached =
        //     PostViewUtils.findById(provider.post, widget.index) ??
        //     PostViewUtils.findById(provider.viewedpost, widget.index);
        // if (cached != null) {
        //   setState(() {
        //     enquiry = cached;
        //   });
        //   await _loadResponses();
        // }

        // Fetch single full record

        // action(id: fresh['_id'], action: "viewed");
        // loaduser();
      }
      _loadResponses();
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

  Future<void> _loadResponses() async {
    if (_isLoadingResponses || enquiry.isEmpty) return;

    setState(() => _isLoadingResponses = true);
    try {
      final uid = userData?['_id']?.toString() ?? '';
      final enquiryId = enquiry['_id']?.toString() ?? '';
      if (uid.isEmpty || enquiryId.isEmpty) {
        setState(() => _isLoadingResponses = false);
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
      await ResponseRepository.instance.clearMyResponses(
        enquiry['_id']?.toString() ?? '',
      );
      await ResponseRepository.instance.saveMyResponses(
        List<Map<String, dynamic>>.from(extractResponseList(response)),
        enquiry['_id']?.toString() ?? '',
      );
      setState(() {
        responses = extractResponseList(response);
        _isLoadingResponses = false;
      });
      loadSettings();
      quickreport();
    } catch (e) {
      debugPrint('SellerViewScreen._loadResponses error: $e');
      if (mounted) setState(() => _isLoadingResponses = false);
    } finally {
      try {
        final response = ResponseRepository.instance.getMyResponses(
          enquiry['_id'].toString(),
        );

        setState(() {
          responses = response;
          _isLoadingResponses = false;
        });
      } catch (e) {
        debugPrintStack();
        setState(() {
          _isLoadingResponses = false;
        });
      }
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

      final pendingId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
      final pendingResponse = <String, dynamic>{
        '_id': pendingId,
        'offlineQueueId': pendingId,
        'requirementId': enquiry['_id']?.toString() ?? '',
        'userId': uid,
        'merchantname': userData?['name']?.toString() ?? '',
        'buyerId': enquiry['buyerId']?.toString() ?? '',
        'type': enquiry['type']?.toString() ?? '',
        'quantity':
            int.tryParse(quantityController.text.replaceAll(',', '').trim()) ??
            0,
        'expectedPrice':
            int.tryParse(priceController.text.replaceAll(',', '').trim()) ?? 0,
        'price': price.toInt(),
        'remarks': remarksController.text.trim(),
        'status': 'pending',
        'created_on': DateTime.now().toIso8601String(),
      };
      setState(() => responses = [pendingResponse, ...responses]);
      await ResponseRepository.instance.addMyResponse(
        pendingResponse,
        enquiry['_id']?.toString() ?? '',
      );

      await PostService().dynamicPost(
        collectionName: 'quotes',
        queryType: 'enquiries',
        data: {
          "_id": "SEQ|QUOTE",
          "quantity":
              int.tryParse(
                quantityController.text.replaceAll(',', '').trim(),
              ) ??
              0,
          "expectedPrice":
              int.tryParse(priceController.text.replaceAll(',', '').trim()) ??
              0,
          "price": price.toInt(),
          "remarks": remarksController.text.trim(),
          "requirementId": enquiry['_id']?.toString() ?? '',
          "userId": uid,
          "status": 'new',
          "buyerId": enquiry['buyerId']?.toString() ?? '',
          "type": enquiry['type']?.toString() ?? '',
          "is_merchant_status_viewed": false,
          "is_buyer_viewed_status": false,
          "isStatusViewed": false,
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

  // ── sheet helpers ────────────────────────────────────────────────────────────
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
                remarksController: remarksController,
                currency: getCurrencySymbol(enquiry['currency'] ?? ""),
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

  String _getString(dynamic value, {String defaultValue = 'N/A'}) {
    try {
      if (value == null) return defaultValue;
      return value.toString().trim();
    } catch (e) {
      return defaultValue;
    }
  }

  Widget _buildResponseHistory(ScrollController? scrollController) {
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
                onconfirm: () => onConfirm(res['_id']),
                onreject: () => onReject(res['_id']),
                onview: () {
                  context.pop();
                  context
                      .push(
                        RoutePath.sellerResponseviewscreen,
                        extra: ['${res['requirementId']}', '${res['_id']}'],
                      )
                      .then((_) {
                        _initializeData();
                      });
                },
                currency: getCurrencySymbol(
                  safeMap(res['response_details'])['currency'] ?? "",
                ),
                showActions: false,
                isrejected:
                    res['status'] == "rejected" || res['status'] == "Rejected",
                avatar: Icons.person,
                avatarBg: AppColors.accent,
                senderName: res['merchantname'],
                timestamp: _formatDate(res['created_on']),
                enquiriesRemark:
                    '${res['remarks'] ?? res['remark'] ?? "No Remarks"}',
                responseRemark:
                    res['buyer_remarks']?.toString() ?? "No Remarks",
                status: _getString(
                  res['status'],
                  defaultValue: "unknown",
                ).toUpperCase(),
                statusColor: getStatusColor(
                  _getString(res['status'], defaultValue: "unknown"),
                ),
                quantity: Formatters.formatToKg(res['quantity']),
                price: " ${Formatters.formatTomoney(res['expectedPrice'])}",
                total: " ${Formatters.formatTomoney(res['price'])}",
                totalColor: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
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
                      const ViewScreenSkeleton(),
                    ],
                  ),
                );
              }
              // Resolve enquiry: prefer singlepost, fall back to list cache
              enquiry = (provider.singlepost.isNotEmpty)
                  ? provider.singlepost.first
                  : PostViewUtils.findById(provider.post, widget.index) ??
                        PostViewUtils.findById(
                          provider.viewedpost,
                          widget.index,
                        ) ??
                        enquiry;

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

              available =
                  '${PostViewUtils.parseInt(enquiry['requiredqty']) - PostViewUtils.parseInt(enquiry['confirmedKg'])}';

              final minimumqty =
                  PostViewUtils.parseInt(available) >
                      PostViewUtils.parseInt(enquiry['minimumqty'])
                  ? '${enquiry['minimumqty']}'
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

                children: [
                  Expanded(
                    child: Column(
                      children: [
                        isloadingprofile
                            ? TradeHeadersSkeleton()
                            : _buildTradeHeader(provider),
                        // const SizedBox(height: 5),
                        _buildProductDetailsCard(),
                        const SizedBox(height: 5),
                        if (!isKernel) ...[
                          PostTwoColumnCards(
                            availableLabel: Translate.t("view.PURCHASED"),
                            availableValue: _formatToKg(
                              enquiry['confirmedKg'] ?? '0',
                            ),
                            minimumQtyValue: _formatToKg(minimumqty),
                          ),
                          const SizedBox(height: 5),
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
                        PostActionButtons(
                          labelmessage: enquiry['lowerbit'] ?? false
                              ? Translate.t("button.bidding")
                              : Translate.t("button.Interested"),
                          isMyPost: false,
                          noresponse: false,
                          onInterested: _showMakeOfferDrawer,
                          onResponseHistory: _showResponseHistoryDrawer,
                        ),
                        const SizedBox(height: 16),
                        // if (MediaQuery.sizeOf(context).width < 900)
                        CompactResponseList(
                          title: Translate.t("button.my_History"),
                          isMypost: false,
                          responses: responses,
                          isLoading: _isLoadingResponses,
                          mode: ResponseFieldMode.sellerRequirement,
                          onConfirm: onConfirm,
                          onReject: onReject,
                          onReload: _loadResponses,
                          onView: (refId, responseId) => context
                              .push(
                                RoutePath.sellerResponseviewscreen,
                                extra: [refId, responseId],
                              )
                              .then((_) => _initializeData()),
                        ),
                        const SizedBox(height: 24),
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
                  //         child: CompactResponseList(
                  //           title: Translate.t("button.my_History"),
                  //           isMypost: false,
                  //           responses: responses,
                  //           isLoading: _isLoadingResponses,
                  //           mode: ResponseFieldMode.sellerRequirement,
                  //           onConfirm: onConfirm,
                  //           onReject: onReject,
                  //           onReload: _loadResponses,
                  //           onView: (refId, responseId) => context
                  //               .push(
                  //                 RoutePath.sellerResponseviewscreen,
                  //                 extra: [refId, responseId],
                  //               )
                  //               .then((_) => _initializeData()),
                  //         ),
                  //       ),
                  // Expanded(
                  //     flex: 1,
                  //     child: Padding(
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 16,
                  //         vertical: 12,
                  //       ),
                  //       child: Column(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Container(
                  //             width: 40,
                  //             height: 5,
                  //             decoration: BoxDecoration(
                  //               color: AppColors.borderLight,
                  //               borderRadius: BorderRadius.circular(10),
                  //             ),
                  //           ),
                  //           const SizedBox(height: 16),
                  //           Text(
                  //             Translate.t("view.view_all"),
                  //             style: AppTextThemes
                  //                 .getLightTextTheme
                  //                 .headlineMedium
                  //                 ?.copyWith(
                  //                   color: AppColors.textPrimaryLight,
                  //                 ),
                  //           ),
                  //           const SizedBox(height: 16),
                  //           Flexible(child: _buildResponseHistory(null)),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
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
      email: stock_user['email']?.toString() ?? '',
      phone: stock_user['phone']?.toString() ?? '',
      imageUrl: stock_user['profilePicture']?.toString() ?? '',
      count: "${(enquiry["viewed"] as List?)?.length ?? 0} views",
      onTap: () {
        context
            .push(
              RoutePath.userProfile,
              extra: [stock_user['userId'], stock_user],
            )
            .then((_) {
              _initializeData();
            });
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

    if (enquiry['type'] == 'Kernel') {
      final postedRaw = enquiry['orderDate'] ?? enquiry['created_on'];
      final expireRaw = enquiry['deliverydate'] ?? enquiry['expiredate'];
      return ProductCardKernel(
        shipmentmethod: enquiry['shippingmethod'] ?? "",
        shipmenttype: enquiry['shipmenttype'] ?? "",
        isgst: enquiry['priceincludegst'] ?? false,
        negotiatePrice: enquiry['lowerbit'] ?? false,
        isavailablestock: false,
        isMypost: false,
        unit: enquiry['priceunit'] ?? "Kg",
        initialprice: _formatToMoney(
          enquiry['initialprice'] ?? enquiry['sellingprice'],
        ),
        confirmedKg: PostViewUtils.parseInt(enquiry['confirmedKg']).toString(),
        location: PostViewUtils.getString(
          '${enquiry['flag'] ?? ""}  ${enquiry['origin']}',
        ),
        moistureContent: PostViewUtils.getString(enquiry['moistureContent']),
        isliked: (enquiry['favorite'] as List?)?.contains(uid) ?? false,
        onLike: (v) =>
            _postAction(id: enquiry['_id'], action: 'favorite', status: !v),
        description: enquiry['description']?.toString() ?? '',
        productName: '${enquiry['grade']}',
        quantity: _formatToKg(available),
        originGrade: 'Origin / Grade',
        postedDate: PostViewUtils.formatDate(postedRaw),
        expireDate: PostViewUtils.formatDate(expireRaw),
        currency: getCurrencySymbol(enquiry['currency'] ?? ""),
        availablelabel: 'REQUIRED',
        availableStock: _formatToKg(available),
        minimumOrder: _formatToKg(enquiry['minimumqty']),
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
        ? '${PostViewUtils.getString(enquiry['grade'], fallback: '')} Kernel'
        : 'RCN (${PostViewUtils.getString(enquiry['yearOfCrop'], fallback: '')})';

    return PostMainHeaderCard(
      shipmentmethod: enquiry['shippingmethod'] ?? "",
      shipmenttype: enquiry['shipmenttype'] ?? "",
      negotiatePrice: enquiry['lowerbit'] ?? false,
      isgst: enquiry['priceincludegst'] ?? false,
      isMyPost: false,
      unit: enquiry['priceunit'] ?? "Kg",
      initialprice: _formatToMoney(
        enquiry['initialprice'] ?? enquiry['sellingprice'],
      ),
      isLiked: (enquiry['favorite'] as List?)?.contains(uid) ?? false,
      onLike: (v) =>
          _postAction(id: enquiry['_id'], action: 'favorite', status: v),
      origin: PostViewUtils.getString(
        '${enquiry['flag'] ?? ""}  ${enquiry['origin']}',
      ),
      productType: productType,
      requiredQty: PostViewUtils.getString(_formatToKg(available)),
      description: PostViewUtils.getString(enquiry['description']),
      budgetPrice: PostViewUtils.getString(
        currentPrice == 0
            ? _formatToMoney(enquiry['expectedprice'] ?? "")
            : _formatToMoney(currentPrice),
      ),
      confirmedKg: PostViewUtils.parseInt(enquiry['confirmedKg']).toString(),
      outTurn: PostViewUtils.getString(enquiry['outTurn']),
      currency: getCurrencySymbol(enquiry['currency'] ?? ""),
      moistureContent: PostViewUtils.getString(
        enquiry['moistureContent'],
        fallback: '0',
      ),
      nutCount: PostViewUtils.getString(enquiry['nutCount']),
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
                    final image = bid['profile'];
                    final formattedDate = DateFormat('dd MMM yyyy hh:mm a')
                        .format(DateTime.parse(bid['date']).toLocal())
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
                                style: AppTextThemes.getLightTextTheme.titleMedium!
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

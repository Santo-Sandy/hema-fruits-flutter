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
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/features/layouts/skeleton_loader.dart';
import 'package:cashew_marketplace/features/screens/view_screen/view_screen_safety.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/custom.dart';
import 'package:cashew_marketplace/core/utils/currency.dart';
import 'package:cashew_marketplace/shared/widgets/view_card_widget.dart';
import 'package:cashew_marketplace/shared/widgets/response_list_widget.dart';
import 'package:cashew_marketplace/shared/widgets/view_screen_widget.dart';
import 'package:cashew_marketplace/shared/widgets/zoomable_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ViewScreen extends StatefulWidget {
  final String index;
  const ViewScreen({this.index = "", super.key});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController remarksController;

  Map<String, dynamic> item = {};
  List<dynamic> responses = [];
  List<String> stockImages = [];
  List<String> quickreports = [];
  List<Map<String, dynamic>> uploadedImages = [];
  Map stock_user = {};
  Map<String, dynamic> Settings = {};

  String userId = '';
  double price = 0.0;
  dynamic userData;
  String available = '';
  bool _isLoadingResponses = true;
  bool isloadingprofile = true;

  final _formatToKg = Formatters.formatToKg;
  final _formatToMoney = Formatters.formatTomoney;
  final _responseService = ResponseService();

  // ── lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController();
    priceController = TextEditingController();
    remarksController = TextEditingController();
    OfflineQueueService.onQueueFlushed.addListener(_loadResponses);
    _loadPost();
  }

  Future<void> loaduser() async {
    try {
      final provider = context.read<UserProfProvider>();

      await provider.fetch(
        userId: item['userid']?.toString() ?? '',
        endpoint: "entities/filter/users",
        filterPayload: {
          "filter": [
            {
              "clause": "AND",
              "conditions": [
                {
                  "column": "_id",
                  "operator": "EQUALS",
                  "value": item['userid']?.toString() ?? '',
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
          isloadingprofile = false;
        });
      }
    } catch (e) {
      debugPrint('loaduser error: $e');
    } finally {
      setState(() => isloadingprofile = false);
    }
  }

  @override
  void dispose() {
    OfflineQueueService.onQueueFlushed.removeListener(_loadResponses);
    quantityController.dispose();
    priceController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  // ── data loading ────────────────────────────────────────────────────────────

  Future<void> _loadPost() async {
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
      // _resolveItemFromCache(provider, uid);

      final endpoint = 'post';
      await provider.getSinglePost(endpoint: endpoint, id: widget.index);
      userData = await SecureStorageService.getUserData();
      if (!mounted) return;

      final uid = userData?['_id']?.toString() ?? '';
      setState(() => userId = uid);

      if (!mounted) return;
      final fresh = PostViewUtils.findById(provider.singlepost, widget.index);
      if (fresh != null) {
        setState(() {
          item = fresh;
        });
      }
      if (stock_user.isEmpty) {
        await loaduser();
      }
      _loadResponses();
      await action(id: item['_id'], action: "viewed");
      // loaduser();
    } catch (e) {
      debugPrint('BuyerPostView._loadPost error: $e');
    }
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
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }
  // void _resolveItemFromCache(PostProvider provider, String uid) {
  //   final found =
  //       PostViewUtils.findById(provider.post, widget.index) ??
  //       PostViewUtils.findById(provider.viewedpost, widget.index);
  //   if (found != null) {
  //     if (!mounted) return;
  //     setState(() {
  //       item = found;
  //     });
  //   }
  // }

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
      try {
        final settingrepo = SettingsLocalRepository.instance.getAdminSettings();
        setState(() {
          Settings = settingrepo;
        });
      } catch (e) {
        debugPrintStack();
      }
    }
  }

  void _loadResponses() async {
    if (item.isEmpty) return;
    setState(() => _isLoadingResponses = true);

    try {
      final postService = PostService();
      final uid = userData?['_id']?.toString() ?? '';
      final itemId = item['_id']?.toString() ?? '';

      final response = await postService.loadResponse(
        endpoint: 'dataset/data/post_response',
        data: {
          'filter': [
            {
              'clause': 'AND',
              'conditions': [
                {'column': 'userId', 'operator': 'EQUALS', 'value': uid},
                {'column': 'stockId', 'operator': 'EQUALS', 'value': itemId},
              ],
            },
          ],
        },
      );

      if (!mounted) return;
      await ResponseRepository.instance.clearMyResponses(
        item['_id'].toString() ?? '',
      );
      await ResponseRepository.instance.saveMyResponses(
        List<Map<String, dynamic>>.from(extractResponseList(response)),
        item['_id'].toString() ?? '',
      );
      setState(() {
        responses = extractResponseList(response);
      });

      loadSettings();
      quickreport();
    } catch (e) {
      debugPrint('BuyerPostView._loadResponses error: $e');
      if (mounted) setState(() => _isLoadingResponses = false);
    } finally {
      try {
        final response = ResponseRepository.instance.getMyResponses(
          item['_id'].toString() ?? '',
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

  // ── actions ─────────────────────────────────────────────────────────────────

  Future<void> _onConfirm(String id) async {
    await _responseService.setStatus(
      endpoint: 'confirm/quotes/$id',
      data: {'status': 'confirmed'},
    );
    _loadResponses();
  }

  Future<void> _onReject(String id) async {
    await showRejectRemarkDialog(
      context,
      onConfirm: (remark) => _responseService.setStatus(
        endpoint: 'confirm/quotes/$id',
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
        'capitalmarket/stocks/$id/$action',
        status,
        id,
        action,
        userId,
      );
    } catch (e) {
      debugPrint('BuyerPostView._postAction error: $e');
    }
  }

  Future<void> _submitOffer() async {
    final postService = PostService();
    final pendingId = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final pendingResponse = <String, dynamic>{
      '_id': pendingId,
      'offlineQueueId': pendingId,
      'stockId': '${item['_id']}',
      'buyername': userData?['name']?.toString() ?? '',
      'userId': userId,
      'merchantId': '${item['userid']}',
      'type': '${item['type']}',
      'quantity':
          int.tryParse(quantityController.text.replaceAll(',', '').trim()) ?? 0,
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
      item['_id'].toString(),
    );

    await postService.dynamicPost(
      collectionName: 'stock_quotes',
      queryType: 'enquiries',
      data: {
        "_id": "SEQ|STQUOT",
        "quantity":
            int.tryParse(quantityController.text.replaceAll(',', '').trim()) ??
            0,
        "expectedPrice":
            int.tryParse(priceController.text.replaceAll(',', '').trim()) ?? 0,
        "price": price.toInt(),
        "remark": remarksController.text.trim(),
        "source": "Market Place",
        "stockId": "${item['_id']}",
        "status": "processing",
        "userId": userId,
        "merchantId": "${item['userid']}",
        "type": "${item['type']}",
      },
    );
    _loadPost();
    quantityController.clear();
    remarksController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote submitted successfully')),
      );
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

  Future<void> quickreport() async {
    try {
      await context.read<CountryProvider>().fetchReports();
    } catch (e) {
      debugPrintStack();
    } finally {
      setState(() {
        quickreports = ReportRepository.instance.getReports();
      });
    }
  }

  Future<void> onReport(String reason) async {
    try {
      final postService = ApiDioPostService();
      await postService.getdata(
        endpoint: "entities/reports",
        data: {
          "reason": reason.trim(),
          "stockId": "${item['_id']}",
          "buyerId": userId,
          "type": "Stock",
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
        data: {"userId": userId, "block_id": item['userid'], "reason": reason},
      );
      context.pop();
    } catch (e) {
      debugPrintStack();
    }
  }

  void _showMakeOfferDrawer() async {
    // await getUser(userData?['_id']);
    userData = await SecureStorageService.getUserData();
    final points = (userData?['points'] as int?) ?? 0;

    final int requiredPoints =
        int.tryParse(Settings['EnquiresDetectionPoint']?.toString() ?? '') ?? 0;
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
                    //   Translate.t("common.make_an_offer"),
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
                negotiatePrice: item['negotiateprice'] ?? false,
                minQuantity: '${item['minimumqty']}',
                currency: getCurrencySymbol(item['currency']?.toString() ?? ""),
                sellingprice: '${item['sellingprice']}',
                onTotalChanged: (v) => setState(() => price = v),
                onTap: () {
                  _submitOffer();
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
                    Translate.t("button.my_History"),
                    style: AppTextThemes.getLightTextTheme.headlineMedium
                        ?.copyWith(color: AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 16),
                  Flexible(child: _buildResponseHistory()),
                ],
              ),
            );
          },
        );
      },
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

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
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

  String _getString(dynamic value, {String defaultValue = 'N/A'}) {
    try {
      if (value == null) return defaultValue;
      return value.toString().trim();
    } catch (e) {
      return defaultValue;
    }
  }

  Widget _buildResponseHistory() {
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
        final buyerDetails = res['buyer_details'];
        final user =
            (buyerDetails is List &&
                buyerDetails.isNotEmpty &&
                buyerDetails[0] is Map)
            ? buyerDetails[0]['name']?.toString() ?? "user"
            : "user";
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
                onconfirm: () => _onConfirm(res['_id']),
                onreject: () => _onReject(res['_id']),
                onview: () {
                  context.pop();
                  context
                      .push(
                        RoutePath.buyerResponseviewscreen,
                        extra: ['${res['stockId']}', '${res['_id']}'],
                      )
                      .then((_) {
                        _loadPost();
                      });
                },
                showActions: false,
                isrejected:
                    res['status'] == "rejected" || res['status'] == "Rejected",
                avatar: Icons.person,
                avatarBg: AppColors.accent,
                senderName: user,

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
                price: Formatters.formatTomoney(res['expectedPrice']),
                total: Formatters.formatTomoney(res['price']),
                currency: getCurrencySymbol(
                  firstMapValue(res['stock_details'], 'currency'),
                ),
                totalColor: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('viewscreen', context);
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

              item = provider.singlepost.first;

              available =
                  '${PostViewUtils.parseInt(item['availableqty']) - PostViewUtils.parseInt(item['confirmedKg'])}';

              final rawImages = (item['images'] ?? []);
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

              final minimumqty =
                  PostViewUtils.parseInt(available) >
                      PostViewUtils.parseInt(item['minimumqty'])
                  ? '${item['minimumqty']}'
                  : available;

              final isKernel = item['type'] == 'Kernel';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        isloadingprofile
                            ? TradeHeadersSkeleton()
                            : _buildTradeHeader(provider),
                        // const SizedBox(height: 5),
                        Container(
                          width: MediaQuery.sizeOf(context).width < 900
                              ? null
                              : 900,
                          child: Column(
                            children: [
                              _buildProductDetailsCard(),
                              const SizedBox(height: 5),
                              if (!isKernel) ...[
                                PostTwoColumnCards(
                                  availableLabel: Translate.t("view.CONFIRMED"),
                                  availableValue: _formatToKg(
                                    item['confirmedKg'] ?? '0',
                                  ),
                                  minimumQtyValue: _formatToKg(minimumqty),
                                ),
                                const SizedBox(height: 8),
                                PostDeliveryLocationCard(
                                  label: Translate.t("view.CONFIRMED"),
                                  location: PostViewUtils.getString(
                                    '${item['location'] ?? ""} ${item['pincode'] ?? ""}',
                                  ),
                                  confirmedKg: _formatToKg(
                                    item['confirmedKg'] ?? '0',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                PostDatesSection(
                                  postedDate: PostViewUtils.formatDate(
                                    item['fromdate'],
                                  ),
                                  untilDate: PostViewUtils.formatDate(
                                    item['expiredate'],
                                  ),
                                ),
                              ],
                              if (stockImages.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: ImageCardViewer(
                                    imageUrls: stockImages,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              PostActionButtons(
                                labelmessage: item['negotiateprice'] ?? false
                                    ? Translate.t("button.bidding")
                                    : Translate.t("button.Interested"),
                                isMyPost: false,
                                noresponse: false,
                                onInterested: _showMakeOfferDrawer,
                                onResponseHistory: _showResponseHistoryDrawer,
                              ),

                              // const SizedBox(height: 16),
                              // responses.isEmpty &&
                              //         MediaQuery.sizeOf(context).width < 900
                              //     ? Center(
                              //         child: Text(
                              //           "No Response",
                              //           style: AppTextThemes.getLightTextTheme.titleSmall!
                              //               .copyWith(
                              //                 color: AppColors.textSecondaryLight,
                              //               ),
                              //         ),
                              //       )
                              //     : SizedBox(),
                              // const SizedBox(height: 24),
                              // Container(
                              //   width: 40,
                              //   height: 5,
                              //   decoration: BoxDecoration(
                              //     color: AppColors.borderLight,
                              //     borderRadius: BorderRadius.circular(10),
                              //   ),
                              // ),
                              const SizedBox(height: 16),
                              // if (MediaQuery.sizeOf(context).width < 900)
                              CompactResponseList(
                                title: Translate.t("button.my_History"),
                                isMypost: false,
                                responses: responses,
                                isLoading: _isLoadingResponses,
                                mode: ResponseFieldMode.buyerStock,
                                onConfirm: _onConfirm,
                                onReject: _onReject,
                                onReload: _loadPost,
                                onView: (refId, responseId) => context
                                    .push(
                                      RoutePath.buyerResponseviewscreen,
                                      extra: [refId, responseId],
                                    )
                                    .then((_) => _loadPost()),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // responses.isEmpty
                  // ? MediaQuery.sizeOf(context).width < 900
                  // ? SizedBox()
                  //       : Expanded(
                  //           flex: 1,
                  //           child: Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               Center(
                  //                 child: Text(
                  //                   "No Response",
                  //                   style: AppTextThemes
                  //                       .getLightTextTheme
                  //                       .titleSmall!
                  //                       .copyWith(
                  //                         color:
                  //                             AppColors.textSecondaryLight,
                  //                       ),
                  //                 ),
                  //               ),
                  //             ],
                  //           ),
                  //         )
                  // : MediaQuery.sizeOf(context).width < 900
                  // ? SizedBox()
                  // : Expanded(
                  //     child: CompactResponseList(
                  //       title: Translate.t("button.my_History"),
                  //       isMypost: false,
                  //       responses: responses,
                  //       isLoading: _isLoadingResponses,
                  //       mode: ResponseFieldMode.buyerStock,
                  //       onConfirm: _onConfirm,
                  //       onReject: _onReject,
                  //       onReload: _loadPost,
                  //       onView: (refId, responseId) => context
                  //           .push(
                  //             RoutePath.buyerResponseviewscreen,
                  //             extra: [refId, responseId],
                  //           )
                  //           .then((_) => _loadPost()),
                  //     ),
                  //   ),
                  // Expanded(
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
                  //             Translate.t("button.History"),
                  //             style: AppTextThemes
                  //                 .getLightTextTheme
                  //                 .headlineMedium
                  //                 ?.copyWith(
                  //                   color: AppColors.textPrimaryLight,
                  //                 ),
                  //           ),
                  //           const SizedBox(height: 16),
                  //           Flexible(child: _buildResponseHistory()),
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
  Map<String, dynamic>? getUserById(List<dynamic> list, String id) {
    try {
      return list.firstWhere((element) => element["_id"] == id);
    } catch (e) {
      return null;
    }
  }

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
      email: stock_user['email']?.toString() ?? '',
      phone: stock_user['phone']?.toString() ?? '',
      imageUrl: stock_user['profilePicture']?.toString() ?? '',
      count: "${(item["viewed"] as List?)?.length ?? 0} views",
      onReport: (reason) {
        onReport(reason);
      },
      reportReasons: quickreports,
      onBlock: (String reason) {
        onBlock(reason);
      },
      onTap: () {
        context
            .push(
              RoutePath.userProfile,
              extra: ['${stock_user['userId']}', stock_user],
            )
            .then((_) => _loadPost());
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
    final list = List<Map<String, dynamic>>.from(item['biddings'] ?? []);

    final currentPrice = list.isEmpty
        ? 0
        : list
              .map((e) => int.tryParse(e['price'].toString()) ?? 0)
              .reduce((a, b) => a > b ? a : b);
    if (item['type'] == 'Kernel') {
      return ProductCardKernel(
        shipmentmethod: item['shippingmethod'] ?? "",
        shipmenttype: item['shipmenttype'] ?? "",
        isgst: item['priceincludegst'] ?? false,
        isavailablestock: true,
        isMypost: false,
        unit: item['priceunit'] ?? "Kg",
        initialprice: _formatToMoney(
          item['initialprice'] ?? item['sellingprice'] ?? "0",
        ),
        confirmedKg: PostViewUtils.parseInt(item['confirmedKg']).toString(),
        location: PostViewUtils.getString(
          '${item['flag'] ?? ''}  ${item['origin']}',
        ),
        productName: '${item['grade']}',
        negotiatePrice: item['negotiateprice'] ?? false,
        moistureContent: PostViewUtils.getString(
          '${item['moistureContent'] ?? "0"}',
        ),
        isliked: (item['favorite'] as List?)?.contains(userId) ?? false,
        onLike: (v) =>
            _postAction(id: item['_id'] ?? "", action: 'favorite', status: v),
        quantity: _formatToKg(available),
        originGrade: Translate.t("view.originGrade"),
        description: item['description']?.toString() ?? '',
        postedDate: PostViewUtils.formatDate(item['fromdate'] ?? ""),
        expireDate: PostViewUtils.formatDate(item['expiredate'] ?? ""),
        currency: getCurrencySymbol(item['currency']?.toString() ?? ""),
        availablelabel: 'AVAILABLE',
        availableStock: _formatToKg(available),
        minimumOrder: _formatToKg(item['minimumqty'] ?? '0'),
        stockLocation: '${item['location'] ?? ""} ${item['pincode'] ?? ""}',
        pricePerKg: currentPrice == 0
            ? _formatToMoney(item['sellingprice'] ?? "")
            : _formatToMoney(currentPrice),
        onbiddinglist: () {
          showBiddings(context, list);
        },
      );
    }

    return PostMainHeaderCard(
      shipmentmethod: item['shippingmethod'] ?? "",
      shipmenttype: item['shipmenttype'] ?? "",
      isgst: item['priceincludegst'] ?? false,
      negotiatePrice: item['negotiateprice'] ?? false,
      isMyPost: false,
      isLiked: (item['favorite'] as List?)?.contains(userId) ?? false,
      initialprice: _formatToMoney(
        item['initialprice'] ?? item['sellingprice'],
      ),
      unit: item['priceunit'] ?? "Kg",
      onLike: (v) =>
          _postAction(id: item['_id'] ?? '', action: 'favorite', status: v),
      origin: PostViewUtils.getString(
        '${item['flag'] ?? ''}  ${item['origin']}',
      ),
      productType:
          'RCN (${PostViewUtils.getString(item['yearofcrop'], fallback: '')})',
      requiredQty: PostViewUtils.getString(_formatToKg(available)),
      description: PostViewUtils.getString(item['description']),
      budgetPrice: PostViewUtils.getString(
        currentPrice == 0
            ? _formatToMoney(item['sellingprice'] ?? "")
            : _formatToMoney(currentPrice),
      ),
      confirmedKg: PostViewUtils.parseInt(item['confirmedKg']).toString(),
      currency: getCurrencySymbol(item['currency']?.toString() ?? ""),
      outTurn: PostViewUtils.getString(item['outturn']),
      moistureContent: PostViewUtils.getString(
        item['moistureContent'],
        fallback: '0',
      ),
      nutCount: PostViewUtils.getString(_formatToMoney(item['netcount'])),
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

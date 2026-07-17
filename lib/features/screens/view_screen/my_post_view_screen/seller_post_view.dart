import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/config/app_config.dart';
import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/repositories/response_repository.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/core/utils/currency.dart';
import 'package:cashew_marketplace/features/layouts/skeleton_loader.dart';
import 'package:cashew_marketplace/features/screens/activity/post_requiremment/newPost/newPost.dart';
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

class SellerPostView extends StatefulWidget {
  final String index;
  final List<Map<String, dynamic>>? postList;
  const SellerPostView({required this.index, this.postList, super.key});

  @override
  State<SellerPostView> createState() => _SellerPostViewState();
}

class _SellerPostViewState extends State<SellerPostView> {
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController remarksController;

  Map<String, dynamic> enquiry = {};
  List<dynamic> responses = [];
  List<String> stockImages = [];
  List<Map<String, dynamic>> uploadedImages = [];
  Map<String, dynamic> stock_user = {};

  double price = 0.0;
  dynamic userData;
  String available = '';
  bool _isLoadingResponses = false;
  bool _isLoading = true;
  bool _viewUsersLoaded = false;

  final _formatToKg = Formatters.formatToKg;
  final _formatToMoney = Formatters.formatTomoney;
  final _responseService = ResponseService();

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController();
    priceController = TextEditingController();
    remarksController = TextEditingController();
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
                  "value": enquiry['userid']?.toString() ?? '',
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
    }
  }

  Future<void> _initializeData() async {
    try {
      userData = await SecureStorageService.getUserData();
      if (!mounted) return;

      final provider = Provider.of<PostProvider>(context, listen: false);

      // Fetch single full record
      await provider.getSinglePost(endpoint: 'post', id: widget.index);
      if (!mounted) return;

      final fresh = PostViewUtils.findById(provider.singlepost, widget.index);
      if (fresh != null) {
        setState(() {
          enquiry = fresh;
          _isLoading = false;
        });
        if (!_viewUsersLoaded) {
          _viewUsersLoaded = true;
          await loadUsers(enquiry['viewed'] ?? []);
        }
        await loaduser();
        await _loadResponses();
      }
    } catch (e) {
      debugPrint('SellerViewScreen._initializeData error: $e');
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
                {'column': 'merchantId', 'operator': 'EQUALS', 'value': uid},
                {'column': 'stockId', 'operator': 'EQUALS', 'value': enquiryId},
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
      });
    } catch (e) {
      debugPrint('SellerViewScreen._loadResponses error: $e');
      if (mounted) setState(() => _isLoadingResponses = false);
    } finally {
      responses = ResponseRepository.instance.getMyResponses(
        enquiry['_id'].toString() ?? '',
      );
      _isLoadingResponses = false;
    }
  }

  // ── actions ──────────────────────────────────────────────────────────────────

  Future<void> _onConfirm(String id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(Translate.t("popup.confirm")),
          content: Text(Translate.t("popup.confirm_quotes")),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Cancel
                    },
                    child: Text(Translate.t("popup.cancel")),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _responseService.setStatus(
                        endpoint: "confirm/stock_quotes/$id",
                        data: {
                          "status": "confirmed",
                          "buyer_remarks": "Quote confirmed by buyer",
                        },
                      );

                      _loadResponses();
                      Navigator.pop(context); // Close dialog
                    },
                    child: Text(Translate.t("popup.ok")),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _onReject(String id) async {
    await showRejectRemarkDialog(
      context,
      onConfirm: (remark) => _responseService.setStatus(
        endpoint: 'confirm/stock_quotes/$id',
        data: {'status': 'rejected', 'buyer_remarks': remark},
      ),
    );
    _loadResponses();
  }

  bool _canUpdatePost() {
    return (int.tryParse('${enquiry['remainingeditCount'] ?? 0}') ?? 0) > 0;
  }

  Future<void> _deletePost() async {
    final id = enquiry['_id']?.toString() ?? widget.index;
    await ApiDioPutService().getdata(
      endpoint: 'entities/post/$id',
      data: {'isDeleted': true, 'status': 'closed'},
    );
    if (mounted) context.pop(true);
  }

  Future<void> _editPost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewPostScreen(
          isEdit: true,
          existingData: enquiry,
          role: 'processor',
          type: enquiry['type'] ?? 'RCN',
          collectionName: 'stocks',
          queryType: 'posts',
        ),
      ),
    );
    if (mounted) _initializeData();
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translate.t("popup.cancel")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuote() async {
    if (quantityController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // BUG FIX: null check before cast, not after
    final points = (userData?['points'] as int?) ?? 0;
    if (points <= 14) {
      //showSubscriptionLimitSheet(context);
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
          "expectedPrice":
              int.tryParse(priceController.text.replaceAll(',', '').trim()) ??
              0,
          "price": price.toInt(),
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
      await _loadResponses();

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

  void _showMakeOfferDrawer() {
    // BUG FIX: null-safe points check (was: `userData['points'] as int <= 14 || userData['points'] == null`)
    final points = (userData?['points'] as int?) ?? 0;
    if (points <= 14) {
      //showSubscriptionLimitSheet(context);
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
                    const SizedBox(height: 16),
                    Text(
                      'Make a Quote',
                      style: AppTextThemes.getLightTextTheme.headlineMedium
                          ?.copyWith(color: AppColors.textPrimaryLight),
                    ),
                  ],
                ),
              ),
              MakeOfferForm(
                maxQuantity: available,
                quantityController: quantityController,
                priceController: priceController,
                remarksController: remarksController,
                negotiatePrice: enquiry['negotiateprice'] ?? false,
                minQuantity: PostViewUtils.getString(
                  enquiry['minimumqty'],
                  fallback: '0',
                ),
                currency: getCurrencySymbol(enquiry['currency'] ?? ""),
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
                    Translate.t("button.History"),
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
        final user =
            (res['buyer_details'] is List && res['buyer_details'].isNotEmpty)
            ? firstMapValue(res['buyer_details'], 'name') ?? "Unknown"
            : "Unknown";
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
                        RoutePath.myResponseSellerpost,
                        extra: ['${res["stockId"]}', '${res["_id"]}'],
                      )
                      .then((_) {
                        _initializeData();
                      });
                },
                showActions:
                    res['status'] == 'new' || res['status'] == 'processing',
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
                price: " ${Formatters.formatTomoney(res['expectedPrice'])}",
                total: Formatters.formatTomoney(res['price']),
                currency: getCurrencySymbol(
                  firstMapValue(res['stock_details'], 'currency'),
                ),
                // total: "₹ ${Formatters.formatTomoney(res['price'])}",
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
    return SafeArea(
      child: ZoomablePages(
        child: SingleChildScrollView(
          child: Consumer<PostProvider>(
            builder: (context, provider, _) {
              if (_isLoading && provider.isLoading) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const ViewScreenSkeleton(),
                );
              }

              if (widget.postList == null && provider.singlepost.isEmpty) {
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

              enquiry = widget.postList?.first ?? provider.singlepost.first;

              available =
                  '${PostViewUtils.parseInt(enquiry['availableqty']) - PostViewUtils.parseInt(enquiry['confirmedKg'])}';

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
                        _buildTradeHeader(
                          provider,
                          enquiry['buyerId']?.toString() ?? '',
                        ),
                        // const SizedBox(height: 8),
                        _buildProductDetailsCard(),
                        const SizedBox(height: 8),
                        if (!isKernel) ...[
                          PostTwoColumnCards(
                            availableLabel: Translate.t("view.CONFIRMED"),
                            availableValue: _formatToKg(
                              enquiry['confirmedKg'] ?? '0',
                            ),
                            minimumQtyValue: _formatToKg(minimumqty),
                          ),
                          const SizedBox(height: 8),
                          PostDeliveryLocationCard(
                            label: Translate.t("view.CONFIRMED"),
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
                              enquiry['fromdate'],
                            ),
                            untilDate: PostViewUtils.formatDate(
                              enquiry['expiredate'],
                            ),
                          ),
                        ],
                        if (stockImages.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ImageCardViewer(imageUrls: stockImages),
                          ),
                          const SizedBox(height: 8),
                        ],
                        // PostActionButtons(
                        //   isMyPost: true,
                        //   noresponse: false,
                        //   onInterested: _showMakeOfferDrawer,
                        //   onResponseHistory: _showResponseHistoryDrawer,
                        // ),
                        const SizedBox(height: 8),
                        // if (MediaQuery.sizeOf(context).width < 900)
                        CompactResponseList(
                          title: Translate.t("button.History"),
                          isMypost: true,
                          responses: responses,
                          isLoading: _isLoadingResponses,
                          mode: ResponseFieldMode.buyerStock,
                          onConfirm: _onConfirm,
                          onReject: _onReject,
                          onReload: _initializeData,
                          onView: (refId, responseId) => context
                              .push(
                                RoutePath.myResponseSellerpost,
                                extra: [refId, responseId],
                              )
                              .then((_) => _initializeData()),
                        ),
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
                  //     : CompactResponseList(
                  //         title: Translate.t("button.History"),
                  //         isMypost: true,
                  //         responses: responses,
                  //         isLoading: _isLoadingResponses,
                  //         mode: ResponseFieldMode.buyerStock,
                  //         onConfirm: _onConfirm,
                  //         onReject: _onReject,
                  //         onReload: _initializeData,
                  //         onView: (refId, responseId) => context
                  //             .push(
                  //               RoutePath.myResponseSellerpost,
                  //               extra: [refId, responseId],
                  //             )
                  //             .then((_) => _initializeData()),
                  //       ),
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
  Map<String, dynamic>? getUserById(List<dynamic> list, String id) {
    try {
      return list.firstWhere((element) => element["_id"] == id);
    } catch (e) {
      return null;
    }
  }

  List<dynamic> users = [];
  List<ViewedUser> viewedUsers = [];
  // ── sub-widgets ──────────────────────────────────────────────────────────────
  Future<void> loadUsers(List<dynamic> userslist) async {
    try {
      ApiDioPostService post = ApiDioPostService();
      List<String> userIds = userslist.map((e) => e.toString()).toList();
      final response = await post.getdata(
        endpoint: "dataset/data/viewed_users",
        data: {
          "filterParams": [
            {
              "parmasName": "userIds",
              "parmsDataType": "array_string",
              "paramsValue": userIds,
            },
          ],
        },
      );

      final responseData = response['data'];
      if (responseData is! List || responseData.isEmpty) {
        return;
      }
      final reportsData = responseData[0]['response'];
      if (reportsData is! List || reportsData.isEmpty) {
        return;
      }
      users = reportsData;
      setState(() {
        viewedUsers = users.map((e) => ViewedUser.fromJson(e)).toList();
      });
    } catch (e) {
      debugPrintStack();
    }
  }

  void showViewedUsersBottomSheet(
    BuildContext context,
    List<ViewedUser> users,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.beige,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          'Viewed Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Align(
                          alignment: AlignmentGeometry.centerEnd,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.borderLight,
                            child: Text(
                              users.length.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(),

                  Expanded(
                    child: users.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final user = users[index];

                              return GestureDetector(
                                onTap: () {
                                  context
                                      .push(
                                        RoutePath.userProfile,
                                        extra: [user.id, user.getmap(user)],
                                      )
                                      .then((_) => _initializeData());
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                        user.profilePicture != null &&
                                            user.profilePicture!.isNotEmpty
                                        ? !user.profilePicture!.startsWith(
                                                'http',
                                              )
                                              ? CachedNetworkImageProvider(
                                                  AppConfig.imageurl +
                                                      user.profilePicture!,
                                                )
                                              : CachedNetworkImageProvider(
                                                  user.profilePicture!,
                                                )
                                        : null,
                                    child:
                                        user.profilePicture == null ||
                                            user.profilePicture!.isEmpty
                                        ? Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : '?',
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
      },
    );
  }

  Widget _buildTradeHeader(PostProvider provider, String id) {
    final label = enquiry['type'] == 'Kernel'
        ? '${enquiry['grade']} Kernel'
        : '${enquiry['yearofcrop'] ?? ''} RCN';

    return TradeHeader(
      onviewers: () {
        showViewedUsersBottomSheet(context, viewedUsers);
      },
      isMyPost: true,
      isliked:
          (enquiry['favorite'] as List?)?.contains(userData?['_id']) ?? false,
      count: '${viewedUsers.length}',
      tradeId: label,
      onTap: () {},
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
        isavailablestock: true,
        negotiatePrice: enquiry['negotiateprice'] ?? false,
        isMypost: true,
        unit: enquiry['priceunit'] ?? "Kg",
        initialprice: _formatToMoney(
          enquiry['initialprice'] ?? enquiry['sellingprice'],
        ),
        confirmedKg: PostViewUtils.parseInt(enquiry['confirmedKg']).toString(),
        location: PostViewUtils.getString('${enquiry['origin']}'),
        moistureContent: PostViewUtils.getString(enquiry['moistureContent']),
        isliked: (enquiry['favorite'] as List?)?.contains(uid) ?? false,
        description: enquiry['description']?.toString() ?? '',
        productName: '${enquiry['grade']}',
        quantity: _formatToKg(available),
        originGrade: 'Origin / Grade',
        postedDate: PostViewUtils.formatDate(postedRaw),
        expireDate: PostViewUtils.formatDate(expireRaw),
        availablelabel: Translate.t("view.available_stock"),
        availableStock: _formatToKg(available),
        minimumOrder: _formatToKg(enquiry['minimumqty']),
        stockLocation:
            '${enquiry['location'] ?? ""} ${enquiry['pincode'] ?? ""}',
        currency: getCurrencySymbol(enquiry['currency'] ?? ""),
        pricePerKg: currentPrice == 0
            ? _formatToMoney(enquiry['sellingprice'] ?? "")
            : _formatToMoney(currentPrice),
        moreAction: MyPostActionMenu(
          canUpdate: _canUpdatePost(),
          onUpdate: _editPost,
          onDelete: _showDeleteDialog,
        ),
        onbiddinglist: () {
          showBiddings(context, list);
        },
      );
    }

    final productType = enquiry['type'] == 'Kernel'
        ? '${PostViewUtils.getString(enquiry['grade'], fallback: '')} Kernel'
        : ' RCN (${PostViewUtils.getString(enquiry['yearofcrop'], fallback: '')})';

    return PostMainHeaderCard(
      shipmentmethod: enquiry['shippingmethod'] ?? "",
      shipmenttype: enquiry['shipmenttype'] ?? "",
      negotiatePrice: enquiry['negotiateprice'] ?? false,
      isgst: enquiry['priceincludegst'] ?? false,
      isMyPost: true,
      unit: enquiry['priceunit'] ?? "Kg",
      initialprice: _formatToMoney(
        enquiry['initialprice'] ?? enquiry['sellingprice'],
      ),
      isLiked: (enquiry['favorite'] as List?)?.contains(uid) ?? false,
      origin: PostViewUtils.getString('${enquiry['origin']}'),
      productType: productType,
      requiredQty: PostViewUtils.getString(_formatToKg(available)),
      description: PostViewUtils.getString(enquiry['description']),
      budgetPrice: PostViewUtils.getString(
        currentPrice == 0
            ? _formatToMoney(enquiry['sellingprice'] ?? "")
            : _formatToMoney(currentPrice),
      ),
      currency: getCurrencySymbol(enquiry['currency'] ?? ""),
      // currency: isMyPost ? getCurrencySymbol(enquiry['currency'] ?? "") : "",
      confirmedKg: PostViewUtils.parseInt(enquiry['confirmedKg']).toString(),
      outTurn: PostViewUtils.getString(enquiry['outturn']),
      moistureContent: PostViewUtils.getString(
        enquiry['moistureContent'],
        fallback: '0',
      ),
      nutCount: PostViewUtils.getString(enquiry['netcount']),
      moreAction: MyPostActionMenu(
        canUpdate: _canUpdatePost(),
        onUpdate: _editPost,
        onDelete: _showDeleteDialog,
      ),
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

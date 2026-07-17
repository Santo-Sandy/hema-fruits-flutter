import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/config/app_config.dart';
import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/repositories/response_repository.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
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

class BuyerPostView extends StatefulWidget {
  final String index;
  final List<Map<String, dynamic>>? postList;
  const BuyerPostView({required this.index, this.postList, super.key});

  @override
  State<BuyerPostView> createState() => _BuyerPostViewState();
}

class _BuyerPostViewState extends State<BuyerPostView> {
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController remarksController;

  Map<String, dynamic> item = {};
  List<dynamic> responses = [];
  List<String> stockImages = [];
  List<Map<String, dynamic>> uploadedImages = [];

  String userId = '';
  double price = 0.0;
  dynamic userData;
  String available = '';
  bool _isLoadingResponses = true;
  bool _isLoading = true;
  bool _viewUsersLoaded = false;

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
    _loadPost();
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  // ── data loading ────────────────────────────────────────────────────────────

  Future<void> _loadPost() async {
    try {
      userData = await SecureStorageService.getUserData();
      if (!mounted) return;

      final uid = userData?['_id']?.toString() ?? '';
      setState(() => userId = uid);
      final provider = Provider.of<PostProvider>(context, listen: false);
      final endpoint = 'post';
      await provider.getSinglePost(endpoint: endpoint, id: widget.index);

      if (!mounted) return;
      final fresh = PostViewUtils.findById(provider.singlepost, widget.index);
      if (fresh != null) {
        setState(() {
          item = fresh;
          _isLoading = false;
        });
      }
      if (!_viewUsersLoaded) {
        _viewUsersLoaded = true;
        await loadUsers(item['viewed'] ?? []);
      }
      _loadResponses();
    } catch (e) {
      debugPrint('BuyerPostView._loadPost error: $e');
    }
  }

  void _loadResponses() async {
    if (!mounted || item.isEmpty) return;
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
                {
                  'column': 'requirementId',
                  'operator': 'EQUALS',
                  'value': itemId,
                },

                {
                  "column": "blocked_ids",
                  "operator": "NOTEQUAL",
                  "value": userId,
                },
                {
                  "column": "blocker_ids",
                  "operator": "NOTEQUAL",
                  "value": userId,
                },
                {'column': 'buyerId', 'operator': 'EQUALS', 'value': uid},
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
        _isLoadingResponses = false;
      });
    } catch (e) {
      debugPrint('BuyerPostView._loadResponses error: $e');
      if (mounted) setState(() => _isLoadingResponses = false);
    } finally {
      setState(() {
        responses = ResponseRepository.instance.getMyResponses(
          item['_id'].toString() ?? '',
        );
        _isLoadingResponses = false;
      });
    }
  }

  // ── actions ─────────────────────────────────────────────────────────────────

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
                        endpoint: "confirm/quotes/$id",
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
        endpoint: 'confirm/quotes/$id',
        data: {'status': 'rejected', 'buyer_remarks': remark},
      ),
    );
    _loadResponses();
  }

  bool _canUpdatePost() {
    return (int.tryParse('${item['remainingeditCount'] ?? 0}') ?? 0) > 0;
  }

  Future<void> _deletePost() async {
    final id = item['_id']?.toString() ?? widget.index;
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
          existingData: item,
          role: 'buyer',
          type: item['type'] ?? 'RCN',
          collectionName: 'requirements',
          queryType: 'posts',
        ),
      ),
    );
    _loadPost();
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
                onconfirm: () => _onConfirm(res['_id']),
                onreject: () => _onReject(res['_id']),
                onview: () {
                  context.pop();
                  context
                      .push(
                        RoutePath.myResponseBuyerpost,
                        extra: ['${res["requirementId"]}', '${res["_id"]}'],
                      )
                      .then((_) {
                        _loadPost();
                      });
                },
                showActions:
                    res['status'] == 'new' ||
                    res['status'] == 'processing' ||
                    res['status'] == 'viewed',
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
                quantity: Formatters.formatToKg(
                  res['supplyQtyKg'] ?? res['quantity'],
                ),
                currency: getCurrencySymbol(
                  (res['response_details']?['currency']),
                ),

                price: Formatters.formatTomoney(
                  res['priceperKg'] ?? res['expectedPrice'],
                ),
                total: Formatters.formatTomoney(
                  res['priceINR'] ?? res['price'],
                ),
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
    ContextManager().saveCurrentPage('viewscreen', context);
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
              if (widget.postList != null && provider.singlepost.isEmpty) {
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

              item = widget.postList?.first ?? provider.singlepost.first;

              available =
                  '${PostViewUtils.parseInt(item['requiredqty']) - PostViewUtils.parseInt(item['confirmedKg'])}';

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
                    child: Column(
                      children: [
                        _buildTradeHeader(
                          provider,
                          item['userid']?.toString() ?? '',
                        ),
                        // const SizedBox(height: 8),
                        _buildProductDetailsCard(),
                        const SizedBox(height: 8),
                        if (!isKernel) ...[
                          PostTwoColumnCards(
                            availableLabel: Translate.t("view.PURCHASED"),
                            availableValue: _formatToKg(
                              item['confirmedKg'] ?? '0',
                            ),
                            minimumQtyValue: _formatToKg(minimumqty),
                          ),
                          const SizedBox(height: 8),
                          PostDeliveryLocationCard(
                            label: Translate.t("view.PURCHASED"),
                            location: PostViewUtils.getString(
                              '${item['location'] ?? ""} ${item['pincode'] ?? ""}',
                            ),
                            confirmedKg: _formatToKg(
                              item['confirmedKg'] ?? '0',
                            ),
                          ),
                          const SizedBox(height: 8),
                          PostDatesSection(
                            postedDate: PostViewUtils.formatDate(
                              item['orderDate'] ?? "",
                            ),
                            untilDate: PostViewUtils.formatDate(
                              item['deliverydate'] ?? "",
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
                        //   onInterested: _showMakeOfferDrawer,
                        //   noresponse: responses.isNotEmpty
                        //       ? MediaQuery.sizeOf(context).width < 900
                        //       : false,
                        //   onResponseHistory: _showResponseHistoryDrawer,
                        // ),
                        const SizedBox(height: 8),
                        // if (MediaQuery.sizeOf(context).width < 900)
                        CompactResponseList(
                          title: Translate.t("button.History"),
                          isMypost: true,
                          responses: responses,
                          isLoading: _isLoadingResponses,
                          mode: ResponseFieldMode.sellerRequirement,
                          onConfirm: _onConfirm,
                          onReject: _onReject,
                          onReload: _loadPost,
                          onView: (refId, responseId) => context
                              .push(
                                RoutePath.myResponseBuyerpost,
                                extra: [refId, responseId],
                              )
                              .then((_) => _loadPost()),
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
                  //         mode: ResponseFieldMode.sellerRequirement,
                  //         onConfirm: _onConfirm,
                  //         onReject: _onReject,
                  //         onReload: _loadPost,
                  //         onView: (refId, responseId) => context
                  //             .push(
                  //               RoutePath.myResponseBuyerpost,
                  //               extra: [refId, responseId],
                  //             )
                  //             .then((_) => _loadPost()),
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
              decoration: BoxDecoration(
                color: AppColors.background,
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
                      children: [
                        const Text(
                          'Viewed Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
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
                                      .then((_) => _loadPost());
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
    final label = item['type'] == 'Kernel'
        ? '${item['grade']} Kernel'
        : 'RCN (${item['yearOfCrop']})';
    // loadUsers(item['viewed'] ?? []);
    return TradeHeader(
      onviewers: () {
        showViewedUsersBottomSheet(context, viewedUsers);
      },
      isMyPost: true,
      tradeId: label,
      count: "${viewedUsers.length}",
      onTap: () {},
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
        isavailablestock: false,
        shipmentmethod: item['shippingmethod'] ?? "",
        shipmenttype: item['shipmenttype'] ?? "",
        isgst: item['priceincludegst'] ?? false,
        isMypost: true,
        negotiatePrice: item['lowerbit'] ?? false,
        unit: item['priceunit'] ?? "Kg",
        initialprice: _formatToMoney(
          item['initialprice'] ?? item['sellingprice'],
        ),
        confirmedKg: PostViewUtils.parseInt(item['confirmedKg']).toString(),
        location: PostViewUtils.getString(
          '${item['flag'] ?? ''}  ${item['origin']}',
        ),
        productName: '${item['grade']}',
        moistureContent: PostViewUtils.getString(item['moistureContent']),
        isliked: (item['favorite'] as List?)?.contains(userId) ?? false,
        quantity: _formatToKg(available),
        originGrade: Translate.t("view.requGrade"),
        description: item['description']?.toString() ?? '',
        postedDate: PostViewUtils.formatDate(item['orderDate']),
        expireDate: PostViewUtils.formatDate(item['deliverydate']),
        availablelabel: Translate.t("view.REQUIRED_STOCK"),
        availableStock: _formatToKg(available),
        minimumOrder: _formatToKg(item['minimumqty'] ?? '0'),
        currency: getCurrencySymbol(item['currency'] ?? ""),
        stockLocation: '${item['location'] ?? ""} ${item['pincode'] ?? ""}',
        pricePerKg: currentPrice == 0
            ? _formatToMoney(item['expectedprice'] ?? "")
            : _formatToMoney(currentPrice),
        moreAction: MyPostActionMenu(
          canUpdate: _canUpdatePost(),
          onUpdate: _canUpdatePost() ? _editPost : () => {},
          onDelete: _showDeleteDialog,
        ),
        onbiddinglist: () {
          showBiddings(context, list);
        },
      );
    }

    return PostMainHeaderCard(
      shipmentmethod: item['shippingmethod'] ?? "",
      shipmenttype: item['shipmenttype'] ?? "",
      isgst: item['priceincludegst'] ?? false,
      isMyPost: true,
      negotiatePrice: item['lowerbit'] ?? false,
      unit: item['priceunit'] ?? "Kg",
      isLiked: (item['favorite'] as List?)?.contains(userId) ?? false,
      initialprice: _formatToMoney(
        item['initialprice'] ?? item['sellingprice'] ?? "",
      ),
      origin: PostViewUtils.getString(
        '${item['flag'] ?? ''}  ${item['origin']}',
      ),
      productType:
          'RCN (${PostViewUtils.getString(item['yearOfCrop'], fallback: '')})',
      requiredQty: PostViewUtils.getString(_formatToKg(available)),
      description: PostViewUtils.getString(item['description']),
      budgetPrice: PostViewUtils.getString(
        currentPrice == 0
            ? _formatToMoney(item['expectedprice'] ?? "")
            : _formatToMoney(currentPrice),
      ),
      currency: getCurrencySymbol(item['currency']),
      confirmedKg: PostViewUtils.parseInt(item['confirmedKg']).toString(),
      outTurn: PostViewUtils.getString(item['outTurn']),
      moistureContent: PostViewUtils.getString(
        item['moistureContent'],
        fallback: '0',
      ),
      nutCount: PostViewUtils.getString(item['nutCount']),
      moreAction: MyPostActionMenu(
        canUpdate: _canUpdatePost(),
        onUpdate: _canUpdatePost() ? _editPost : () => {},
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

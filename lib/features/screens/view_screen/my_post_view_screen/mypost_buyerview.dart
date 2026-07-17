import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/config/app_config.dart';
import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/providers/user_provider.dart';
import 'package:cashew_marketplace/core/repositories/response_repository.dart';
import 'package:cashew_marketplace/core/repositories/settings_repository.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/core/utils/currency.dart';
import 'package:cashew_marketplace/features/layouts/skeleton_loader.dart';
import 'package:cashew_marketplace/features/screens/activity/post_requiremment/newPost/newPost.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:cashew_marketplace/features/screens/view_screen/view_screen_safety.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/custom.dart';
import 'package:cashew_marketplace/shared/widgets/response_list_widget.dart';
import 'package:cashew_marketplace/shared/widgets/view_card_widget.dart';
import 'package:cashew_marketplace/shared/widgets/view_screen_widget.dart';
import 'package:cashew_marketplace/shared/widgets/zoomable_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MypostBuyerview extends StatefulWidget {
  final List<String> index;
  const MypostBuyerview({required this.index, super.key});

  @override
  State<MypostBuyerview> createState() => _MypostBuyerview();
}

class _MypostBuyerview extends State<MypostBuyerview> {
  late TextEditingController quantityController;
  late TextEditingController priceController;
  late TextEditingController remarksController;
  Map<String, dynamic> item = {};
  List<dynamic> responses = [];
  Map<String, dynamic> Settings = {};
  Map<String, dynamic> responseviewer = {};
  List<String> stockimages = [];
  List<Map<String, dynamic>> uploadedImages = [];
  String userId = "";
  double price = 0.0;
  dynamic userData;
  String available = '';
  bool _isLoadingResponses = true;
  bool _viewUsersLoaded = false;
  String post_id = '';
  String response_id = '';
  Function(dynamic) formatToKg = Formatters.formatToKg;
  Function(dynamic) formatToMoney = Formatters.formatTomoney;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController();
    priceController = TextEditingController();
    remarksController = TextEditingController();
    getPost();
  }

  Future<void> getPost() async {
    final routeIds = safeRoutePair(widget.index);
    post_id = routeIds[0];
    response_id = routeIds[1];
    if (post_id.isEmpty) return;
    try {
      final userData = await SecureStorageService.getUserData();
      setState(() {
        userId = userData?['_id']?.toString() ?? '';
      });
      final provider = Provider.of<PostProvider>(context, listen: false);
      await provider.getSinglePost(endpoint: "post", id: post_id);
      setState(() {
        item = getUserById(provider.singlepost, post_id) ?? {};
      });
      if (!_viewUsersLoaded) {
        _viewUsersLoaded = true;
        await loadUsers(item['viewed'] ?? []);
      }
      loadResponse();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    }
  }

  Map<String, dynamic>? getUserById(List<dynamic> list, String id) {
    try {
      return list.firstWhere((element) => element["_id"] == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> loadResponse() async {
    setState(() {
      _isLoadingResponses = true;
    });
    try {
      final postService = PostService();
      userData = await SecureStorageService.getUserData();
      final userId = userData?['_id']?.toString() ?? '';

      final response = await postService.loadResponse(
        endpoint: "dataset/data/post_response",
        data: {
          "filter": [
            {
              "clause": "AND",
              "conditions": [
                {
                  "column": "requirementId",
                  "operator": "EQUALS",
                  "value": item['_id'],
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
                {"column": "buyerId", "operator": "EQUALS", "value": userId},
              ],
            },
          ],
        },
      );

      if (mounted) {
        await ResponseRepository.instance.clearMyResponses(
          item['_id'].toString() ?? '',
        );
        await ResponseRepository.instance.saveMyResponses(
          List<Map<String, dynamic>>.from(extractResponseList(response)),
          item['_id'].toString() ?? '',
        );
        setState(() {
          responses = extractResponseList(response);
          responseviewer = findResponseById(responses, response_id);
          _isLoadingResponses = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingResponses = false;
      });
    } finally {
      setState(() {
        responses = ResponseRepository.instance.getMyResponses(
          item['_id'].toString() ?? '',
        );
        responseviewer = findResponseById(responses, response_id);
        _isLoadingResponses = false;
      });
    }
  }

  ResponseService responseService = ResponseService();
  Future<void> onConfirm(String id) async {
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
                      await responseService.setStatus(
                        endpoint: "confirm/quotes/$id",
                        data: {
                          "status": "confirmed",
                          "buyer_remarks": "Quote confirmed by buyer",
                        },
                      );

                      loadResponse();
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
                        endpoint: "confirm/quotes/$id",
                        data: {"status": "rejected", "buyer_remarks": remark},
                      );
                      loadResponse();
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

  void showSubscriptionLimitDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
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
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                Translate.t("popup.credit_limit_title"),
                style: AppTextThemes.getLightTextTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimaryLight,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                Translate.t("popup.credit_limit_desc", {
                  "point": Settings["EnquiresDetectionPoint"].toString(),
                  "ptype": Translate.t("popup.type_enquiry"),
                }),
                textAlign: TextAlign.center,
                style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    context.push(RoutePath.creditpayment).then((_) {
                      getPost();
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    Translate.t("popup.buy_points"),
                    style: TextStyle(fontSize: 16, color: Colors.white),
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

  Future<void> submit() async {
    PostService postService = PostService();
    await postService.dynamicPost(
      collectionName: "stock_quotes",
      queryType: "enquiries",
      data: {
        "_id": "SEQ|STQUOT",
        "quantity":
            int.tryParse(quantityController.text.replaceAll(',', '').trim()) ??
            0,
        "expectedPrice":
            int.tryParse(priceController.text.replaceAll(',', '').trim()) ?? 0,
        "price": price.toInt(),
        "remark": remarksController.text,
        "source": "Market Place",
        "stockId": "${item['_id']}",
        "status": "processing",
        "userId": userId,
        "merchantId": "${item['userid']}",
        "type": "${item['type']}",
      },
    );
    loadResponse();
    quantityController.clear();
    remarksController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote submitted successfully')),
      );
    }
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
    if (mounted) getPost();
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

  // Show bottom drawer for Response History
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
                onconfirm: () => onConfirm(res['_id']),
                onreject: () => onReject(res['_id']),
                img: ResponseNameResolver.getimage(responseviewer),
                onview: () {
                  context.pop();
                  context
                      .push(
                        RoutePath.myResponseBuyerpost,
                        extra: ['${res["requirementId"]}', '${res["_id"]}'],
                      )
                      .then((_) {
                        getPost();
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
                quantity: formatToKg(res['supplyQtyKg'] ?? res['quantity']),
                currency: getCurrencySymbol(
                  res['response_details']?['currency'],
                ),
                price:
                    "${formatToMoney(res['priceperKg'] ?? res['expectedPrice'])}",
                total: "${formatToMoney(res['priceINR'] ?? res['price'])}",
                totalColor: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    quantityController.dispose();
    priceController.dispose();
    remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('BuyerView', context);
    return SafeArea(
      child: ZoomablePages(
        child: SingleChildScrollView(
          child: Consumer<PostProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const ViewScreenSkeleton(),
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
              if (provider.singlepost.isNotEmpty) {
                item = provider.singlepost[0];
              } else {
                item = {};
              }
              available =
                  '${_parseInt(item['requiredqty']) - _parseInt(item['confirmedKg'])}';
              final images = item['images'];
              if (images is List) {
                uploadedImages = images
                    .where((e) => e is Map)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList();
                stockimages = uploadedImages
                    .map((e) => e['storage_name']?.toString() ?? '')
                    .toList();
              }
              // if (images != null) {
              //   uploadedImages = images
              //       .whereType<Map>()
              //       .map((e) => Map<String, dynamic>.from(e))
              //       .toList();
              //   for (int i = 0; i < uploadedImages.length; i++) {
              //     stockimages = uploadedImages[i]['storage_name'];
              //   }
              // }

              final minimumqty =
                  _parseInt(available) > _parseInt(item['minimumqty'])
                  ? "${item['minimumqty']}"
                  : "${available}";

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        // Header
                        _buildTradeHeader(),
                        // const SizedBox(height: 16),

                        // Product Details Card
                        _buildProductDetailsCard(),
                        const SizedBox(height: 8),

                        // Dates Section
                        item['type'] == "Kernel"
                            ? const SizedBox()
                            : PostDatesSection(
                                postedDate: PostViewUtils.formatDate(
                                  item['orderDate'],
                                ),
                                untilDate: PostViewUtils.formatDate(
                                  item['deliverydate'],
                                ),
                              ),
                        item['type'] == "Kernel"
                            ? const SizedBox()
                            : const SizedBox(height: 8),

                        // Two Column Cards
                        item['type'] == "Kernel"
                            ? const SizedBox()
                            : _buildTwoColumnCards(
                                available: formatToKg(
                                  item['confirmedKg'] ?? "0",
                                ),
                                minimumqty: formatToKg(minimumqty),
                              ),
                        item['type'] == "Kernel"
                            ? const SizedBox()
                            : const SizedBox(height: 8),

                        // Delivery Location
                        item['type'] == "Kernel"
                            ? const SizedBox()
                            : _buildDeliveryLocationCard(
                                location: _getString(
                                  '${item['location'] ?? ""} ${item['pincode'] ?? ""}',
                                ),
                                confirmkg: formatToKg(
                                  item['confirmedKg'] ?? "0",
                                ),
                              ),
                        item['type'] == "Kernel"
                            ? const SizedBox()
                            : const SizedBox(height: 8),
                        if (stockimages.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ImageCardViewer(imageUrls: stockimages),
                          ),
                        // MediaQuery.sizeOf(context).width < 900
                        !_isLoadingResponses
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
                                      onconfirm: () =>
                                          onConfirm(responseviewer['_id']),
                                      onreject: () =>
                                          onReject(responseviewer['_id']),
                                      onview: () {
                                        context
                                            .push(
                                              RoutePath.userProfile,
                                              extra: [
                                                ResponseNameResolver.getid(
                                                  responseviewer,
                                                ),
                                                {
                                                  'profilePicture':
                                                      ResponseNameResolver.getimage(
                                                        responseviewer,
                                                      ),
                                                },
                                              ],
                                            )
                                            .then((_) => getPost());
                                      },
                                      noview: true,
                                      showActions:
                                          responseviewer['status'] == 'new' ||
                                          responseviewer['status'] ==
                                              'processing' ||
                                          responseviewer['status'] == 'viewed',
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
                                      quantity: formatToKg(
                                        responseviewer['supplyQtyKg'] ??
                                            responseviewer['quantity'],
                                      ),

                                      currency: getCurrencySymbol(
                                        responseviewer['response_details']?['currency'],
                                      ),
                                      price:
                                          "${formatToMoney(responseviewer['priceperKg'] ?? responseviewer['expectedPrice'])}",
                                      total:
                                          "${formatToMoney(responseviewer['priceINR'] ?? responseviewer['price'])}",
                                      totalColor: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : OrderCardSkeleton(),
                        // : SizedBox(),
                        // Action Buttons
                        // responses.isNotEmpty &&
                        //         MediaQuery.sizeOf(context).width < 900
                        //     ? _buildActionButtons()
                        //     : SizedBox(),
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
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // responses.isEmpty
                  //     ? MediaQuery.sizeOf(context).width < 900
                  //           ? SizedBox()
                  //           : Center(
                  //               child: Text(
                  //                 "No Response",
                  //                 style: AppTextThemes
                  //                     .getLightTextTheme
                  //                     .titleSmall!
                  //                     .copyWith(
                  //                       color: AppColors.textSecondaryLight,
                  //                     ),
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
                  //                 child: !_isLoadingResponses
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
                  //                               onconfirm: () => onConfirm(
                  //                                 responseviewer['_id'],
                  //                               ),
                  //                               onreject: () => onReject(
                  //                                 responseviewer['_id'],
                  //                               ),
                  //                               onview: () {
                  //                                 context
                  //                                     .push(
                  //                                       RoutePath.userProfile,
                  //                                       extra: [
                  //                                         ResponseNameResolver.getid(
                  //                                           responseviewer,
                  //                                         ),
                  //                                         {
                  //                                           'profilePicture':
                  //                                               ResponseNameResolver.getimage(
                  //                                                 responseviewer,
                  //                                               ),
                  //                                         },
                  //                                       ],
                  //                                     )
                  //                                     .then((_) => getPost());
                  //                               },
                  //                               img:
                  //                                   ResponseNameResolver.getimage(
                  //                                     responseviewer,
                  //                                   ),
                  //                               noview: true,
                  //                               showActions:
                  //                                   responseviewer['status'] ==
                  //                                       'new' ||
                  //                                   responseviewer['status'] ==
                  //                                       'processing' ||
                  //                                   responseviewer['status'] ==
                  //                                       'viewed',
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
                  //                               quantity: formatToKg(
                  //                                 responseviewer['quantity'],
                  //                               ),

                  //                               currency: getCurrencySymbol(
                  //                                 responseviewer['response_details']?['currency'],
                  //                               ),
                  //                               price:
                  //                                   "${formatToMoney(responseviewer['expectedPrice'])}",
                  //                               total:
                  //                                   "${formatToMoney(responseviewer['price'])}",
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
                      children: [
                        const Text(
                          'Viewed Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
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
                                      .then((_) => getPost());
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                        user.profilePicture != null &&
                                            user.profilePicture!.isNotEmpty
                                        ? NetworkImage(user.profilePicture!)
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

  Widget _buildTradeHeader() {
    String header = "View Screen";
    header = item['type'] == 'Kernel'
        ? "${item['grade']} ${Translate.t("filter.kernel")}"
        : "${item['yearOfCrop']} ${Translate.t("filter.rcn")}";
    // loadUsers(item['viewed'] ?? []);
    return TradeHeader(
      onviewers: () {
        showViewedUsersBottomSheet(context, viewedUsers);
      },
      isMyPost: true,
      tradeId: header,
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
    if (item['type'] == "Kernel") {
      return ProductCardKernel(
        isavailablestock: false,
        shipmentmethod: item['shippingmethod'] ?? "",
        shipmenttype: item['shipmenttype'] ?? "",
        isgst: item['priceincludegst'] ?? false,
        negotiatePrice: item['lowerbit'] ?? false,
        isMypost: true,
        unit: PostViewUtils.parseInt(item['confirmedKg']).toString(),
        initialprice: Formatters.formatTomoney(
          item['initialprice'] ?? item['sellingprice'],
        ),
        confirmedKg: "${item['confirmedKg'] ?? "0"}",
        location: _getString('${item['flag'] ?? ""}  ${item['origin']}'),
        productName: '${item['grade']}',
        moistureContent: _getString(
          item['moistureContent'],
          defaultValue: 'N/A',
        ),
        quantity: '${formatToKg(available)}',
        originGrade: Translate.t("view.originGrade"),
        description: '${item['description']}',
        postedDate: DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.parse(item['orderDate'])),
        expireDate: DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.parse(item['deliverydate'])),
        availablelabel: "REQUIRED",
        currency: getCurrencySymbol(item['currency']),
        availableStock: Formatters.formatToKg(available),
        minimumOrder: '${formatToKg(item['minimumqty'])}',
        stockLocation: '${item['location'] ?? ""} ${item['pincode'] ?? ""}',
        pricePerKg:
            '${currentPrice == 0 ? formatToMoney(item['expectedprice'] ?? "") : formatToMoney(currentPrice)}',
        onbiddinglist: () {
          showBiddings(context, list);
        },
      );
    } else {
      return PostMainHeaderCard(
        shipmentmethod: item['shippingmethod'] ?? "",
        shipmenttype: item['shipmenttype'] ?? "",
        isgst: item['priceincludegst'] ?? false,
        nutCount: _getString(formatToKg(item['nutCount']), defaultValue: 'N/A'),
        isMyPost: true,
        negotiatePrice: item['lowerbit'] ?? false,
        moistureContent: _getString(
          item['moistureContent'],
          defaultValue: 'N/A',
        ),
        initialprice: Formatters.formatTomoney(
          item['initialprice'] ?? item['sellingprice'],
        ),
        unit: item['priceunit'] ?? "Kg",
        origin: _getString('${item['flag'] ?? ""}  ${item['origin']}'),
        productType: '${Translate.t("filter.rcn")}(${_getString(item['yearOfCrop'], defaultValue: '')})',
        requiredQty: _getString(formatToKg(available)),
        description: _getString(item['description']),
        currency: getCurrencySymbol(item['currency']),
        budgetPrice: _getString(
          currentPrice == 0
              ? formatToMoney(item['expectedprice'] ?? "")
              : formatToMoney(currentPrice),
        ),
        confirmedKg: _parseInt(
          '${formatToKg(item['confirmedKg'] ?? "0")}',
        ).toString(),
        outTurn: _getString(formatToKg(item['outTurn']), defaultValue: 'N/A'),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _showResponseHistoryDrawer,
              icon: Icon(Icons.history, color: AppColors.primary),
              label: Text(
                Translate.t("view.view_all"),
                style: TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable helper widgets
  Widget _buildMainHeaderCard({
    required String origin,
    required String productType,
    required String requiredQty,
    required String budgetPrice,
    required String description,
    required String currency,
    required String unit,
    required String confirmedKg,
    required String outTurn,
    required String moistureContent,
    required String nutCount,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$productType - $requiredQty',
                      style: AppTextThemes.getLightTextTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Translate.t("view.type_requi"),
                      style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiaryLight,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ExpandableText(text: description),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${Translate.t("view.BUDGET")} /$unit',
                      style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currency $budgetPrice',
                      style: AppTextThemes.getLightTextTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            ' $origin',
            style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            Translate.t("view.origin"),
            style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryLight,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildSpecItem(
                    icon: Icons.water_drop_outlined,
                    label: Translate.t("view.Moisture"),
                    value: outTurn == 'N/A' ? '0' : '$moistureContent %',
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildSpecItem(
                    icon: Icons.numbers,
                    label: Translate.t("view.NutCount"),
                    value: nutCount,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _buildSpecItem(
                    icon: Icons.trending_up,
                    label: Translate.t("view.OutTurn"),
                    value: outTurn == 'N/A' ? '0' : '$outTurn %',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                color: AppColors.textTertiaryLight,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  "${Translate.t("view.Posted")}: ",
                  style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  _formatDate(item['orderDate']),
                  style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  "${Translate.t("view.UNTIL")}: ",
                  style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  _formatDate(item['deliverydate']),
                  style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnCards({
    required String available,
    required String minimumqty,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuantityCard(
              icon: Icons.verified_outlined,
              label: Translate.t("view.CONFIRMED"),
              value: available,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuantityCard(
              icon: Icons.scale_outlined,
              label: Translate.t("view.MINIMUM_ORDER"),
              value: minimumqty,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryLocationCard({
    required String location,
    required String confirmkg,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          // Expanded(
          //   child: _buildQuantityCard(
          //     icon: Icons.verified_outlined,
          //     label: Translate.t("view.CONFIRMED"),
          //     value: confirmkg,
          //   ),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            child: _buildQuantityCard(
              icon: Icons.location_on_outlined,
              label: Translate.t("view.DELIVERY"),
              value: location,
            ),
          ),
        ],
      ),
    );
  }
}

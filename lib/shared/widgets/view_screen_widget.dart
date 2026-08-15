import 'package:hema_fruits/core/constants/app_assets.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/apptoaster.dart';
import 'package:hema_fruits/core/utils/currency.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/core/utils/uri_launcher.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:hema_fruits/shared/widgets/view_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PostViewUtils {
  PostViewUtils._();

  static Map<String, dynamic>? findById(List<dynamic> list, String id) {
    try {
      return list.firstWhere((e) => e['_id'] == id) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static int parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static String getString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static String firstFromList(dynamic list, {required String fallback}) {
    if (list is List && list.isNotEmpty) return list[0].toString();
    return fallback;
  }

  static String formatDate(dynamic dateValue) {
    try {
      if (dateValue == null || dateValue.toString().isEmpty) return '';
      return DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.parse(dateValue.toString()).toLocal());
    } catch (_) {
      return 'N/A';
    }
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'new':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textTertiaryLight;
    }
  }

  static double responsePrice(dynamic response) {
    if (response is! Map) return 0;
    const keys = ['priceperKg', 'expectedPrice', 'price', 'priceINR'];

    for (final key in keys) {
      final parsed = _tryParsePrice(response[key]);
      if (parsed != null) return parsed;
    }

    final details = response['response_details'];
    if (details is Map) {
      for (final key in keys) {
        final parsed = _tryParsePrice(details[key]);
        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  /// If post['price'] == 'MT', divide sellingprice/expectedprice by 1000.
  static dynamic resolvePrice(Map post, String field) {
    final raw = post[field];
    if (post['priceunit'] == 'MT') {
      final num = double.tryParse(raw?.toString() ?? '');
      return num != null ? num / 1000 : raw;
    }
    return raw;
  }

  static double? _tryParsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    final cleaned = value
        .toString()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.-]'), '')
        .trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}

enum ResponsePriceSort { none, lowToHigh, highToLow }

class FilteredResponseHistory extends StatefulWidget {
  const FilteredResponseHistory({
    super.key,
    // required this.scrollController,
    required this.isLoading,
    required this.responses,
    required this.itemBuilder,
  });

  // final ScrollController? scrollController;
  final bool isLoading;
  final List<dynamic> responses;
  final Widget Function(BuildContext context, Map<String, dynamic> response)
  itemBuilder;

  @override
  State<FilteredResponseHistory> createState() =>
      _FilteredResponseHistoryState();
}

class _FilteredResponseHistoryState extends State<FilteredResponseHistory> {
  String _selectedStatus = 'all';
  ResponsePriceSort _priceSort = ResponsePriceSort.none;

  List<Map<String, dynamic>> get _mappedResponses {
    return widget.responses
        .map((item) => Map<String, dynamic>.from(item is Map ? item : {}))
        .toList();
  }

  List<String> get _statusOptions {
    final statuses =
        _mappedResponses
            .map(
              (item) => PostViewUtils.getString(item['status'], fallback: ''),
            )
            .where((status) => status.isNotEmpty)
            .map((status) => status.toLowerCase().trim())
            .toSet()
            .toList()
          ..sort();
    return ['all', ...statuses];
  }

  List<Map<String, dynamic>> get _visibleResponses {
    final selectedStatus = _statusOptions.contains(_selectedStatus)
        ? _selectedStatus
        : 'all';
    final filtered = _mappedResponses.where((item) {
      if (selectedStatus == 'all') return true;
      final status = PostViewUtils.getString(
        item['status'],
        fallback: '',
      ).toLowerCase().trim();
      return status == selectedStatus;
    }).toList();

    switch (_priceSort) {
      case ResponsePriceSort.lowToHigh:
        filtered.sort(
          (a, b) => PostViewUtils.responsePrice(
            a,
          ).compareTo(PostViewUtils.responsePrice(b)),
        );
        break;
      case ResponsePriceSort.highToLow:
        filtered.sort(
          (a, b) => PostViewUtils.responsePrice(
            b,
          ).compareTo(PostViewUtils.responsePrice(a)),
        );
        break;
      case ResponsePriceSort.none:
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.responses.isEmpty) {
      return Center(
        child: Text(
          Translate.t("view.no_response"),
          style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
      );
    }

    final visibleResponses = _visibleResponses;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _statusOptions.contains(_selectedStatus)
                    ? _selectedStatus
                    : 'all',
                isExpanded: true,
                decoration: _filterDecoration(
                  label: 'Status',
                  icon: Icons.filter_list,
                ),
                items: _statusOptions
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status == 'all' ? 'All Status' : status.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatus = value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<ResponsePriceSort>(
                value: _priceSort,
                isExpanded: true,
                decoration: _filterDecoration(
                  label: 'Price',
                  icon: Icons.swap_vert,
                ),
                items: const [
                  DropdownMenuItem(
                    value: ResponsePriceSort.none,
                    child: Text('Default'),
                  ),
                  DropdownMenuItem(
                    value: ResponsePriceSort.lowToHigh,
                    child: Text('Low to High'),
                  ),
                  DropdownMenuItem(
                    value: ResponsePriceSort.highToLow,
                    child: Text('High to Low'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _priceSort = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MediaQuery.of(context).size.width < 600
            ? Expanded(
                child: visibleResponses.isEmpty
                    ? Center(
                        child: Text(
                          'No matching responses',
                          style: AppTextThemes.getLightTextTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      )
                    : ListView.builder(
                        // controller: widget.scrollController,
                        shrinkWrap: true,
                        // physics: const NeverScrollableScrollPhysics(),
                        itemCount: visibleResponses.length,
                        itemBuilder: (context, index) {
                          return widget.itemBuilder(
                            context,
                            visibleResponses[index],
                          );
                        },
                      ),
              )
            : visibleResponses.isEmpty
            ? Center(
                child: Text(
                  'No matching responses',
                  style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              )
            : ListView.builder(
                // controller: widget.scrollController,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleResponses.length,
                itemBuilder: (context, index) {
                  return widget.itemBuilder(context, visibleResponses[index]);
                },
              ),
      ],
    );
  }

  InputDecoration _filterDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
      isDense: true,
      filled: true,
      fillColor: AppColors.backgroundLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

class PostMainHeaderCard extends StatefulWidget {
  const PostMainHeaderCard({
    super.key,
    required this.origin,
    required this.productType,
    required this.requiredQty,
    required this.budgetPrice,
    required this.description,
    required this.confirmedKg,
    required this.shipmentmethod,
    required this.negotiatePrice,
    required this.shipmenttype,
    this.isgst = false,
    required this.initialprice,
    required this.outTurn,
    required this.unit,
    this.currency,
    required this.isMyPost,
    required this.moistureContent,
    required this.nutCount,
    this.isLiked = false,
    this.onLike,
    this.onbiddinglist,
    this.moreAction,
  });

  final String origin;
  final String productType;
  final String requiredQty;
  final String budgetPrice;
  final String description;
  final String confirmedKg;
  final String? currency;
  final String initialprice;
  final String shipmenttype;
  final String shipmentmethod;
  final bool isgst;
  final bool negotiatePrice;
  final String outTurn;
  final String unit;
  final String moistureContent;
  final String nutCount;
  final bool isLiked;
  final bool isMyPost;
  final ValueChanged<bool>? onLike;
  final Function()? onbiddinglist;
  final Widget? moreAction;

  @override
  State<PostMainHeaderCard> createState() => _PostMainHeaderCardState();
}

class _PostMainHeaderCardState extends State<PostMainHeaderCard>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(PostMainHeaderCard old) {
    super.didUpdateWidget(old);
    if (old.isLiked != widget.isLiked) {
      setState(() => _isLiked = widget.isLiked);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_isLiked == true) {
      AppToast.showFavoriteToast(context, "Added to favorite");
      setState(() => _isLiked = !_isLiked);
      widget.onLike?.call(_isLiked);
    } else {
      // final shouldRemove = await FavoriteDialog.showUnFavoriteDialog(context);
      AppToast.showFavoriteToast(context, "Removed from favorite");
      // if (shouldRemove == true) {
      setState(() => _isLiked = !_isLiked);
      widget.onLike?.call(_isLiked);
      // remove favorite
      // } else {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final int initialprice = int.parse(widget.initialprice.replaceAll(",", ''));
    final int currentprice = int.parse(widget.budgetPrice.replaceAll(",", ''));
    return Stack(
      children: [
        Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.all(12).copyWith(top: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.borderLight.withOpacity(0.7),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight.withOpacity(0.08),
                    blurRadius: 18,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER
                  Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          /// PRODUCT IMAGE
                          Container(
                            width: 68,
                            height: 68,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.08),
                                  AppColors.primary.withOpacity(0.02),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                AppAssets.iconRcn,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(width: 5),

                          /// TITLE + SUBTITLE
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.isMyPost
                                            ? widget.requiredQty
                                            : '${widget.productType} - ${widget.requiredQty}',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextThemes
                                            .getLightTextTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.textPrimaryLight,
                                              fontWeight: FontWeight.w800,
                                              height: 1.2,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),

                                    const SizedBox(width: 6),

                                    Expanded(
                                      child: Text(
                                        widget.origin,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextThemes
                                            .getLightTextTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.language,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),

                                    const SizedBox(width: 6),

                                    Expanded(
                                      child: Text(
                                        "${widget.shipmenttype} - ${widget.shipmentmethod} Price",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextThemes
                                            .getLightTextTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Container(
                                //   padding: const EdgeInsets.symmetric(
                                //     horizontal: 10,
                                //     vertical: 5,
                                //   ),
                                //   decoration: BoxDecoration(
                                //     color: AppColors.primary.withOpacity(0.08),
                                //     borderRadius: BorderRadius.circular(30),
                                //   ),
                                //   child: Text(
                                //     Translate.t("view.type_requi"),
                                //     style: AppTextThemes.getLightTextTheme.labelSmall
                                //         ?.copyWith(
                                //           color: AppColors.primary,
                                //           fontWeight: FontWeight.w600,
                                //           letterSpacing: 0.3,
                                //         ),
                                //   ),
                                // ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// FAVORITE BUTTON
                          widget.isMyPost
                              ? const SizedBox()
                              : ScaleTransition(
                                  scale: _scaleAnim,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      // padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        // color: _isLiked
                                        //     ? AppColors.error.withOpacity(0.12)
                                        //     : AppColors.surfaceLight,
                                        // shape: BoxShape.circle,
                                        // border: Border.all(
                                        //   color: _isLiked
                                        //       ? AppColors.error.withOpacity(0.3)
                                        //       : AppColors.borderLight,
                                        // ),
                                      ),
                                      child: Icon(
                                        _isLiked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: _isLiked
                                            ? Colors.white
                                            : Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                      widget.isMyPost
                          ? const SizedBox()
                          : Positioned(
                              right: 0,
                              child: ScaleTransition(
                                scale: _scaleAnim,
                                child: GestureDetector(
                                  onTap: _toggle,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    // padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      // color: _isLiked
                                      //     ? AppColors.error.withOpacity(0.12)
                                      //     : AppColors.surfaceLight,
                                      // shape: BoxShape.circle,
                                      // border: Border.all(
                                      //   color: _isLiked
                                      //       ? AppColors.error.withOpacity(0.3)
                                      //       : AppColors.borderLight,
                                      // ),
                                    ),
                                    child: Icon(
                                      _isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: _isLiked
                                          ? AppColors.error
                                          : AppColors.textSecondaryLight,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// ORIGIN + PRICE
                  widget.negotiatePrice
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            /// BUDGET
                            Container(
                              // padding: const EdgeInsets.symmetric(
                              //   horizontal: 18,
                              //   vertical: 14,
                              // ),
                              // decoration: BoxDecoration(
                              //   gradient: LinearGradient(
                              //     colors: [
                              //       AppColors.primary.withOpacity(0.12),
                              //       AppColors.primary.withOpacity(0.04),
                              //     ],
                              //   ),
                              //   borderRadius: BorderRadius.circular(20),
                              //   border: Border.all(
                              //     color: AppColors.primary.withOpacity(0.15),
                              //   ),
                              // ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${Translate.t("view.initial")} /${widget.unit}',
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize: 13,
                                          color: AppColors.textSecondaryLight,
                                          fontWeight: FontWeight.bold,

                                          letterSpacing: 0.5,
                                        ),
                                  ),

                                  Text(
                                    '${widget.currency} ${widget.initialprice}',
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            Center(
                              child: _iconselection(
                                initialprice == currentprice
                                    ? Icons.trending_flat
                                    : initialprice >= currentprice
                                    ? Icons.trending_down
                                    : Icons.trending_up,
                                initialprice == currentprice
                                    ? AppColors.warning
                                    : initialprice >= currentprice
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),

                            /// BUDGET
                            Container(
                              // padding: const EdgeInsets.symmetric(
                              //   horizontal: 18,
                              //   vertical: 14,
                              // ),
                              // decoration: BoxDecoration(
                              //   gradient: LinearGradient(
                              //     colors: [
                              //       AppColors.primary.withOpacity(0.12),
                              //       AppColors.primary.withOpacity(0.04),
                              //     ],
                              //   ),
                              //   borderRadius: BorderRadius.circular(20),
                              //   border: Border.all(
                              //     color: AppColors.primary.withOpacity(0.15),
                              //   ),
                              // ),
                              child: GestureDetector(
                                onTap: widget.onbiddinglist,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${Translate.t("view.current")} /${widget.unit}',
                                      style: AppTextThemes
                                          .getLightTextTheme
                                          .labelSmall
                                          ?.copyWith(
                                            fontSize: 13,
                                            color: AppColors.textSecondaryLight,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${widget.currency} ${widget.budgetPrice}',
                                          style: AppTextThemes
                                              .getLightTextTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.open_in_new,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Expanded(
                            //   child: ExpandableText(text: widget.description),
                            // ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.12),
                                    AppColors.primary.withOpacity(0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${widget.negotiatePrice
                                        ? Translate.t("view.current")
                                        : widget.shipmentmethod == "CIF" || widget.shipmentmethod == "FOB"
                                        ? "${widget.shipmentmethod} ${Translate.t("view.price")}"
                                        : Translate.t("view.price")} /${widget.unit}:',
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontSize: 13,
                                          color: AppColors.textSecondaryLight,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.currency} ${widget.budgetPrice}',
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                  /// SPECS
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ).copyWith(bottom: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight.withOpacity(0.08),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PostSpecItem(
                        icon: Icons.water_drop_outlined,
                        label: Translate.t("view.Moisture"),
                        value: widget.moistureContent == 'N/A'
                            ? '0%'
                            : '${widget.moistureContent}%',
                      ),
                    ),

                    Container(
                      width: 2,
                      height: 40,
                      color: AppColors.borderLight,
                    ),

                    Expanded(
                      child: PostSpecItem(
                        icon: Icons.numbers_rounded,
                        label: Translate.t("view.NutCount"),
                        value: widget.nutCount,
                      ),
                    ),

                    Container(
                      width: 2,
                      height: 40,
                      color: AppColors.borderLight,
                    ),

                    Expanded(
                      child: PostSpecItem(
                        icon: Icons.trending_up_rounded,
                        label: Translate.t("view.OutTurn"),
                        value: widget.outTurn == 'N/A' ? '0' : widget.outTurn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.description != "") ...[
              ExpandableText(text: widget.description),
            ],
          ],
        ),
        Positioned(
          top: 20,
          right: 10,
          child: widget.moreAction != null ? widget.moreAction! : SizedBox(),
        ),
      ],
    );
  }

  Widget _iconselection(IconData icon, Color color) {
    return Icon(icon, color: color, size: 26);
  }
}

class ProductCardKernel extends StatefulWidget {
  final String location;
  final String productName;
  final String quantity;
  final String moistureContent;
  final String originGrade;
  final String postedDate;
  final String expireDate;
  final String availablelabel;
  final String shipmenttype;
  final String shipmentmethod;
  final bool isgst;
  final String confirmedKg;
  final String availableStock;
  final String minimumOrder;
  final String? currency;
  final Function(bool isLiked)? onLike;
  final Function()? onbiddinglist;
  final bool? isliked;
  final bool isavailablestock;
  final bool negotiatePrice;
  final bool isMypost;
  final String description;
  final String stockLocation;
  final String pricePerKg;
  final String unit;
  final String initialprice;
  final Widget? moreAction;

  const ProductCardKernel({
    Key? key,
    required this.location,
    required this.productName,
    required this.quantity,
    required this.moistureContent,
    required this.originGrade,
    required this.confirmedKg,
    required this.isMypost,
    required this.isavailablestock,
    required this.unit,
    required this.negotiatePrice,
    required this.shipmentmethod,
    required this.shipmenttype,
    this.isgst = false,
    this.isliked,
    this.onbiddinglist,
    this.onLike,
    required this.postedDate,
    required this.expireDate,
    required this.availablelabel,
    required this.availableStock,
    required this.minimumOrder,
    this.currency,
    required this.description,
    required this.stockLocation,
    required this.pricePerKg,
    required this.initialprice,
    this.moreAction,
  }) : super(key: key);

  @override
  State<ProductCardKernel> createState() => _ProductCardKernelState();
}

class _ProductCardKernelState extends State<ProductCardKernel>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;
  bool isLiked = false;

  void _toggleLike() {
    if (!isLiked == true) {
      AppToast.showFavoriteToast(context, "Added to favorite");
      setState(() => isLiked = !isLiked);
      widget.onLike?.call(!isLiked);
    } else {
      // final shouldRemove = await FavoriteDialog.showUnFavoriteDialog(context);
      AppToast.showFavoriteToast(context, "Removed from favorite");
      // if (shouldRemove == true) {
      setState(() => isLiked = !isLiked);
      widget.onLike?.call(!isLiked);
      // remove favorite
      // } else {}
    }
  }

  @override
  void initState() {
    super.initState();
    isLiked = widget.isliked ?? false;
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int initialprice = int.parse(widget.initialprice.replaceAll(",", ''));
    final int currentprice = int.parse(widget.pricePerKg.replaceAll(",", ''));
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 70,
                                      height: 70,
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
                                          AppAssets.iconKernel,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  widget.isMypost
                                                      ? widget.quantity
                                                      : '${widget.productName} - ${widget.quantity}',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_rounded,
                                                size: 18,
                                                color: AppColors.primary,
                                              ),

                                              const SizedBox(width: 6),

                                              Expanded(
                                                child: Text(
                                                  widget.location,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextThemes
                                                      .getLightTextTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.language,
                                                size: 18,
                                                color: AppColors.primary,
                                              ),

                                              const SizedBox(width: 6),

                                              Expanded(
                                                child: Text(
                                                  "${widget.shipmenttype} - ${widget.shipmentmethod} Price",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppTextThemes
                                                      .getLightTextTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Text(
                                          //   widget.originGrade,
                                          //   style: TextStyle(
                                          //     fontSize: 12,
                                          //     fontWeight: FontWeight.w600,
                                          //     color: AppColors.textHint,
                                          //   ),
                                          // ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                widget.isMypost
                                    ? SizedBox()
                                    : Positioned(
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: _toggleLike,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_outline,
                                              color: isLiked
                                                  ? AppColors.error
                                                  : AppColors.textSecondary,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),

                            const SizedBox(height: 15),
                            widget.negotiatePrice
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                        // padding: const EdgeInsets.symmetric(
                                        //   horizontal: 18,
                                        //   vertical: 14,
                                        // ),
                                        // decoration: BoxDecoration(
                                        //   gradient: LinearGradient(
                                        //     colors: [
                                        //       AppColors.primary.withOpacity(
                                        //         0.12,
                                        //       ),
                                        //       AppColors.primary.withOpacity(
                                        //         0.04,
                                        //       ),
                                        //     ],
                                        //   ),
                                        //   borderRadius: BorderRadius.circular(
                                        //     20,
                                        //   ),
                                        //   border: Border.all(
                                        //     color: AppColors.borderDark
                                        //         .withAlpha(180),
                                        //   ),
                                        // ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${Translate.t("view.initial")} /${widget.unit}",
                                              style: AppTextThemes
                                                  .getLightTextTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .textSecondaryLight,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                            ),

                                            Text(
                                              '${widget.currency} ${widget.initialprice}',
                                              style: AppTextThemes
                                                  .getLightTextTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Container(
                                      //   padding: const EdgeInsets.symmetric(
                                      //     horizontal: 12,
                                      //   ).copyWith(top: 8, bottom: 8),
                                      //   decoration: BoxDecoration(
                                      //     color: const Color.fromARGB(255, 201, 238, 222),
                                      //     border: Border.all(
                                      //       color: const Color.fromARGB(
                                      //         255,
                                      //         154,
                                      //         195,
                                      //         176,
                                      //       ),
                                      //     ),
                                      //     borderRadius: BorderRadius.circular(12),
                                      //   ),
                                      //   child: Column(
                                      //     mainAxisSize: MainAxisSize.min,
                                      //     children: [
                                      //       Text(
                                      //         Translate.t("view.price"),
                                      //         style: TextStyle(
                                      //           fontSize: 10,
                                      //           fontWeight: FontWeight.w600,
                                      //           color: AppColors.textHintDark,
                                      //           letterSpacing: 0.5,
                                      //         ),
                                      //       ),
                                      //       const SizedBox(height: 4),
                                      //       Text(
                                      //         '${widget.currency} ${widget.pricePerKg}',
                                      //         style: TextStyle(
                                      //           fontSize: 18,
                                      //           fontWeight: FontWeight.w700,
                                      //           color: AppColors.primary,
                                      //         ),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                      Center(
                                        child: _iconselection(
                                          initialprice == currentprice
                                              ? Icons.trending_flat
                                              : initialprice >= currentprice
                                              ? Icons.trending_down
                                              : Icons.trending_up,
                                          initialprice == currentprice
                                              ? AppColors.warning
                                              : initialprice >= currentprice
                                              ? AppColors.error
                                              : AppColors.success,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: widget.onbiddinglist,
                                        child: Container(
                                          // padding: const EdgeInsets.symmetric(
                                          //   horizontal: 18,
                                          //   vertical: 14,
                                          // ),
                                          // decoration: BoxDecoration(
                                          //   gradient: LinearGradient(
                                          //     colors: [
                                          //       AppColors.primary.withOpacity(
                                          //         0.12,
                                          //       ),
                                          //       AppColors.primary.withOpacity(
                                          //         0.04,
                                          //       ),
                                          //     ],
                                          //   ),
                                          //   borderRadius: BorderRadius.circular(
                                          //     20,
                                          //   ),
                                          //   border: Border.all(
                                          //     color: AppColors.borderDark
                                          //         .withAlpha(180),
                                          //   ),
                                          // ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${Translate.t("view.current")} /${widget.unit}',
                                                    style: AppTextThemes
                                                        .getLightTextTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontSize: 13,
                                                          color: AppColors
                                                              .textSecondaryLight,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          letterSpacing: 0.5,
                                                        ),
                                                  ),

                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        '${widget.currency} ${widget.pricePerKg}',
                                                        style: AppTextThemes
                                                            .getLightTextTheme
                                                            .titleLarge
                                                            ?.copyWith(
                                                              color: AppColors
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Icon(
                                                        Icons.open_in_new,
                                                        color:
                                                            AppColors.primary,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              // const SizedBox(width: 6),
                                              // Container(
                                              //   padding:
                                              //       const EdgeInsets.symmetric(
                                              //         horizontal: 10.0,
                                              //         vertical: 8,
                                              //       ),
                                              //   decoration: BoxDecoration(
                                              //     color: Colors.white,
                                              //     border: Border.all(
                                              //       color: AppColors.border,
                                              //     ),
                                              //     borderRadius:
                                              //         BorderRadius.circular(12),
                                              //   ),
                                              //   child: Icon(
                                              //     Icons.open_in_new,
                                              //     color: AppColors.primary,
                                              //     size: 18,
                                              //   ),
                                              // ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // if (widget.description != "") ...[
                                      //   Expanded(
                                      //     child: ExpandableText(
                                      //       text: widget.description,
                                      //     ),
                                      //   ),
                                      // ] else ...[
                                      //   Expanded(
                                      //     child: ExpandableText(
                                      //       text: "No description",
                                      //     ),
                                      //   ),
                                      // ],
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary.withOpacity(
                                                0.12,
                                              ),
                                              AppColors.primary.withOpacity(
                                                0.04,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderDark
                                                .withAlpha(180),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${widget.negotiatePrice
                                                  ? Translate.t("view.current")
                                                  : widget.shipmentmethod == "CIF" || widget.shipmentmethod == "FOB"
                                                  ? "${widget.shipmentmethod} ${Translate.t("view.price")}"
                                                  : Translate.t("view.price")} /${widget.unit}: ',
                                              style: AppTextThemes
                                                  .getLightTextTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .textSecondaryLight,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${widget.currency} ${widget.pricePerKg}',
                                              style: AppTextThemes
                                                  .getLightTextTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                            // Container(
                            //   decoration: BoxDecoration(
                            //     borderRadius: BorderRadius.circular(18),
                            //   ),
                            //   child: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       Text(
                            //         Translate.t("view.origin"),
                            //         style: AppTextThemes.getLightTextTheme.labelLarge
                            //             ?.copyWith(
                            //               color: AppColors.textSecondary,
                            //               fontWeight: FontWeight.w900,
                            //               letterSpacing: 0.3,
                            //             ),
                            //       ),

                            //       Row(
                            //         children: [
                            //           Icon(
                            //             Icons.location_on_rounded,
                            //             size: 18,
                            //             color: AppColors.primary,
                            //           ),

                            //           const SizedBox(width: 6),

                            //           Expanded(
                            //             child: Text(
                            //               widget.location,
                            //               maxLines: 1,
                            //               overflow: TextOverflow.ellipsis,
                            //               style: AppTextThemes
                            //                   .getLightTextTheme
                            //                   .titleSmall
                            //                   ?.copyWith(
                            //                     color: AppColors.primary,
                            //                     fontWeight: FontWeight.w700,
                            //                   ),
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ],
                            //   ),
                            // ),

                            // Text(
                            //   Translate.t("view.origin"),
                            //   style: TextStyle(
                            //     fontSize: 11,
                            //     fontWeight: FontWeight.w600,
                            //     color: AppColors.textHint,
                            //     letterSpacing: 0.5,
                            //   ),
                            // ),

                            // Row(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     Icon(
                            //       Icons.water_drop_outlined,
                            //       size: 16,
                            //       color: AppColors.primary,
                            //     ),
                            //     const SizedBox(width: 6),
                            //     Row(
                            //       mainAxisAlignment: MainAxisAlignment.start,
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         Text(
                            //           Translate.t("view.Moisture"),
                            //           style: AppTextThemes
                            //               .getLightTextTheme
                            //               .labelMedium
                            //               ?.copyWith(
                            //                 color: AppColors.textTertiaryLight,
                            //                 fontWeight: FontWeight.w600,
                            //               ),
                            //         ),
                            //         const SizedBox(height: 2),
                            //         Text(
                            //           ': ${widget.moistureContent} %',
                            //           style: AppTextThemes
                            //               .getLightTextTheme
                            //               .bodySmall
                            //               ?.copyWith(
                            //                 color: AppColors.textPrimaryLight,
                            //                 fontWeight: FontWeight.w600,
                            //               ),
                            //         ),
                            //       ],
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                      // Column(
                      //   mainAxisAlignment: MainAxisAlignment.end,
                      //   crossAxisAlignment: CrossAxisAlignment.end,
                      //   children: [
                      //     widget.isMypost
                      //         ? SizedBox()
                      //         : GestureDetector(
                      //             onTap: _toggleLike,
                      //             child: Container(
                      //               decoration: BoxDecoration(
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //               child: Icon(
                      //                 isLiked
                      //                     ? Icons.favorite
                      //                     : Icons.favorite_outline,
                      //                 color: isLiked
                      //                     ? AppColors.error
                      //                     : AppColors.textSecondary,
                      //                 size: 30,
                      //               ),
                      //             ),
                      //           ),
                      //     const SizedBox(height: 12),
                      //     Container(
                      //       padding: const EdgeInsets.symmetric(
                      //         horizontal: 12,
                      //       ).copyWith(top: 8, bottom: 8),
                      //       decoration: BoxDecoration(
                      //         color: const Color.fromARGB(255, 201, 238, 222),
                      //         border: Border.all(
                      //           color: const Color.fromARGB(255, 154, 195, 176),
                      //         ),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       child: Column(
                      //         mainAxisSize: MainAxisSize.min,
                      //         children: [
                      //           Text(
                      //             Translate.t("view.price"),
                      //             style: TextStyle(
                      //               fontSize: 10,
                      //               fontWeight: FontWeight.w600,
                      //               color: AppColors.textHintDark,
                      //               letterSpacing: 0.5,
                      //             ),
                      //           ),
                      //           const SizedBox(height: 4),
                      //           Text(
                      //             '${widget.currency} ${widget.pricePerKg}',
                      //             style: TextStyle(
                      //               fontSize: 18,
                      //               fontWeight: FontWeight.w700,
                      //               color: AppColors.primary,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 10,
                  child: widget.isMypost
                      ? widget.moreAction ?? SizedBox.shrink()
                      : SizedBox.shrink(),
                ),
              ],
            ),
            if (widget.description != "" && widget.negotiatePrice) ...[
              const SizedBox(height: 8),
              ExpandableText(text: widget.description),
            ],
            const SizedBox(height: 8),
            PostTwoColumnCards(
              availableLabel: widget.isavailablestock
                  ? Translate.t("view.CONFIRMED")
                  : Translate.t("view.PURCHASED"),
              availableValue: Formatters.formatToKg(widget.confirmedKg),
              minimumQtyValue: widget.minimumOrder,
            ),
            const SizedBox(height: 8),
            PostDeliveryLocationCard(
              label: widget.isavailablestock
                  ? Translate.t("view.CONFIRMED")
                  : Translate.t("view.PURCHASED"),
              location: widget.stockLocation,
              confirmedKg: widget.confirmedKg,
            ),
            const SizedBox(height: 8),
            PostDatesSection(
              postedDate: widget.postedDate,
              untilDate: widget.expireDate,
            ),
          ],
        ),
        // Positioned(
        //   top: -10,
        //   right: 20,
        //   child: GestureDetector(
        //     onTap: _toggleLike,
        //     child: Container(
        //       decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        //       child: Icon(
        //         isLiked ? Icons.favorite : Icons.favorite_outline,
        //         color: isLiked ? AppColors.error : AppColors.textSecondary,
        //         size: 28,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _iconselection(IconData icon, Color color) {
    return Icon(icon, color: color, size: 40);
  }
}

class PostSpecItem extends StatelessWidget {
  const PostSpecItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 8),
      // decoration: BoxDecoration(
      //   color: Colors.white.withValues(alpha: 0.08),
      //   borderRadius: BorderRadius.circular(12),
      //   border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      // ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostQuantityCards extends StatelessWidget {
  const PostQuantityCards({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
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
}

class PostQuantityCard extends StatelessWidget {
  const PostQuantityCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.beige),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.08),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
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
}

class PostDatesSection extends StatelessWidget {
  const PostDatesSection({
    super.key,
    required this.postedDate,
    required this.untilDate,
  });

  final String postedDate;
  final String untilDate;

  Widget _dateRow(IconData icon, String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              value,
              style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _dateRow(
              Icons.calendar_today_outlined,
              Translate.t("view.Posted"),
              postedDate,
            ),
            _dateRow(
              Icons.access_time_outlined,
              Translate.t("view.UNTIL"),
              untilDate,
            ),
          ],
        ),
      ),
    );
  }
}

class PostTwoColumnCards extends StatelessWidget {
  const PostTwoColumnCards({
    super.key,
    required this.availableLabel,
    required this.availableValue,
    required this.minimumQtyValue,
  });

  final String availableLabel;
  final String availableValue;
  final String minimumQtyValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: PostQuantityCard(
              icon: Icons.inventory_2_outlined,
              label: availableLabel,
              value: availableValue,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: PostQuantityCard(
              icon: Icons.shopping_cart_checkout,
              label: Translate.t("view.MINIMUM_ORDER"),
              value: minimumQtyValue,
            ),
          ),
        ],
      ),
    );
  }
}

class PostDeliveryLocationCard extends StatelessWidget {
  const PostDeliveryLocationCard({
    super.key,
    required this.location,
    required this.label,
    required this.confirmedKg,
  });

  final String location;
  final String label;
  final String confirmedKg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded(
          //   child: PostQuantityCard(
          //     icon: Icons.verified_outlined,
          //     label: label,
          //     value: confirmedKg,
          //   ),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await ExternalLauncher.openMapWithAddress(location);
              },
              child: PostQuantityCards(
                icon: Icons.location_on,
                label: Translate.t("view.DELIVERY"),
                value: location,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostActionButtons extends StatelessWidget {
  const PostActionButtons({
    super.key,
    required this.isMyPost,
    required this.onInterested,
    required this.labelmessage,
    this.noresponse,
    required this.onResponseHistory,
  });

  final bool isMyPost;
  final bool? noresponse;
  final String labelmessage;
  final VoidCallback onInterested;
  final VoidCallback onResponseHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isMyPost) ...[
            IntrinsicWidth(
              child: ElevatedButton.icon(
                onPressed: onInterested,
                icon: const Icon(Icons.quickreply_outlined),
                label: Text(labelmessage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          if (!isMyPost && (noresponse ?? true)) ...[const SizedBox(width: 12)],
          if (noresponse ?? true) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onResponseHistory,
                icon: Icon(Icons.history, color: AppColors.primary),
                label: Text(
                  Translate.t("button.History"),
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
        ],
      ),
    );
  }
}

void showSubscriptionLimitSheet(
  BuildContext context, {
  required int dpoint,
  required String ptype,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SubscriptionLimitContent(dpoint: dpoint, ptype: ptype),
  );
}

class _SubscriptionLimitContent extends StatelessWidget {
  final int dpoint;
  final String ptype;
  const _SubscriptionLimitContent({required this.dpoint, required this.ptype});

  @override
  Widget build(BuildContext context) {
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
            child: Icon(Icons.lock_outline, size: 32, color: AppColors.primary),
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
              "point": dpoint.toString(),
              "ptype": ptype,
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
                context.push(RoutePath.creditpayment);
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
  }
}

Future<void> showRejectRemarkDialog(
  BuildContext context, {
  required Future<void> Function(String remark) onConfirm,
}) async {
  final remarkCtrl = TextEditingController();
  try {
    final remark = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Remark'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: remarkCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Please provide the reason for rejecting the Quote..',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final remark = remarkCtrl.text.trim();
                    if (remark.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Remark is required')),
                      );
                      return;
                    }
                    Navigator.pop(ctx, remark);
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (remark != null && remark.isNotEmpty) {
      await onConfirm(remark);
    }
  } finally {
    remarkCtrl.dispose();
  }
}

class ProductCardMultiple extends StatefulWidget {
  final List<dynamic> products;
  final String location;
  final String quantity;
  final String postedDate;
  final String expireDate;
  final String shipmenttype;
  final String shipmentmethod;
  final bool isgst;
  final String minimumOrder;
  final String? currency;
  final Function(bool isLiked)? onLike;
  final Function()? onbiddinglist;
  final bool? isliked;
  final bool negotiatePrice;
  final bool isMypost;
  final String stockLocation;

  const ProductCardMultiple({
    Key? key,
    required this.products,
    required this.location,
    required this.quantity,
    required this.postedDate,
    required this.expireDate,
    required this.shipmenttype,
    required this.shipmentmethod,
    this.isgst = false,
    required this.minimumOrder,
    this.currency,
    this.onLike,
    this.onbiddinglist,
    this.isliked,
    required this.negotiatePrice,
    required this.isMypost,
    required this.stockLocation,
  }) : super(key: key);

  @override
  State<ProductCardMultiple> createState() => _ProductCardMultipleState();
}

class _ProductCardMultipleState extends State<ProductCardMultiple> {
  bool isLiked = false;
  static const String _apiBase = "https://cerp.sgp1.digitaloceanspaces.com/";

  @override
  void initState() {
    super.initState();
    isLiked = widget.isliked ?? false;
  }

  void _toggleLike() {
    AppToast.showFavoriteToast(
      context,
      isLiked ? "Removed from favorite" : "Added to favorite",
    );
    setState(() => isLiked = !isLiked);
    widget.onLike?.call(isLiked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.08),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Common Post Details Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Multiple Option Post",
                      style: AppTextThemes.getLightTextTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.location,
                            style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!widget.isMypost && widget.onLike != null)
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? AppColors.error : AppColors.textSecondaryLight,
                  ),
                  onPressed: _toggleLike,
                ),
            ],
          ),
          const Divider(height: 24),

          // Shipment & Quantity Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem("Total Quantity", widget.quantity),
              _buildInfoItem("Min Order", widget.minimumOrder),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem("Shipment Type", widget.shipmenttype),
              _buildInfoItem("Shipment Basis", widget.shipmentmethod),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoItem("Location", widget.stockLocation),
              _buildInfoItem("Available Till", widget.expireDate),
            ],
          ),
          const Divider(height: 24),

          // Products List Section Header
          Text(
            "Products List",
            style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Products List
          if (widget.products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "No products added.",
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            )
          else
            ...widget.products.map((prod) => _buildProductItem(prod)).toList(),

          if (widget.negotiatePrice && widget.onbiddinglist != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onbiddinglist,
                child: const Text("View Responses / Negotiation"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(dynamic prod) {
    final name = prod['name']?.toString() ?? 'Unnamed';
    final rate = prod['rate']?.toString() ?? '0';
    final description = prod['description']?.toString() ?? '';
    final imageMap = prod['image'];
    final imageUrl = imageMap != null && imageMap['storage_name'] != null
        ? '$_apiBase${imageMap['storage_name']}'
        : null;

    final formattedRate = "${widget.currency ?? '₹'} $rate / Kg";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      formattedRate,
                      style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextThemes.getLightTextTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.borderLight.withOpacity(0.3),
      child: Icon(
        Icons.image_outlined,
        color: AppColors.textSecondaryLight,
      ),
    );
  }
}


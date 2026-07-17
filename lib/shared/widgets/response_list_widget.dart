import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashew_marketplace/core/config/app_config.dart';
import 'package:cashew_marketplace/core/extensions/string_ext.dart';
import 'package:cashew_marketplace/core/utils/currency.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:cashew_marketplace/shared/widgets/view_card_widget.dart';
import 'package:cashew_marketplace/shared/widgets/view_screen_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ResponseNameResolver
// Controls how the sender name and price/qty fields are extracted per screen.
// ─────────────────────────────────────────────────────────────────────────────

enum ResponseFieldMode {
  /// Buyer viewing a stock enquiry  (stock_quotes)
  buyerStock,

  /// Seller viewing a requirement enquiry  (quotes)
  sellerRequirement,
}

class ResponseNameResolver {
  const ResponseNameResolver._();

  static String name(Map<String, dynamic> res, ResponseFieldMode mode) {
    switch (mode) {
      case ResponseFieldMode.buyerStock:
        final bd = res['buyername'] ?? res['buyer_name'] ?? "";
        return (bd is List && bd.isNotEmpty)
            ? bd[0]?.toString() ?? 'User'
            : bd?.toString() ?? 'User';
      case ResponseFieldMode.sellerRequirement:
        final mn = res['merchantname'] ?? res['merchant_name'] ?? "";
        return (mn is List && mn.isNotEmpty)
            ? mn[0]?.toString() ?? 'User'
            : mn?.toString() ?? 'User';
    }
  }

  static String? getimage(Map<String, dynamic> res) {
    final image = res['user_details'] != null
        ? res['user_details'][0] != null
              ? res['user_details'][0]['profilePicture'] ?? null
              : null
        : null;
    return image;
  }

  static String? getid(Map<String, dynamic> res) {
    final image = res['user_details'] != null
        ? res['user_details'][0] != null
              ? res['user_details'][0]['_id'] ?? null
              : null
        : null;
    return image;
  }

  static String quantity(Map<String, dynamic> res, ResponseFieldMode mode) {
    switch (mode) {
      case ResponseFieldMode.buyerStock:
        return Formatters.formatToKg(res['quantity'] ?? "");
      case ResponseFieldMode.sellerRequirement:
        return Formatters.formatToKg(
          res['supplyQtyKg'] ?? res['quantity'] ?? "",
        );
    }
  }

  static String price(Map<String, dynamic> res, ResponseFieldMode mode) {
    switch (mode) {
      case ResponseFieldMode.buyerStock:
        return Formatters.formatTomoney(res['expectedPrice'] ?? "");
      case ResponseFieldMode.sellerRequirement:
        return Formatters.formatTomoney(
          res['priceperKg'] ?? res['expectedPrice'] ?? "",
        );
    }
  }

  static String total(Map<String, dynamic> res, ResponseFieldMode mode) {
    switch (mode) {
      case ResponseFieldMode.buyerStock:
        return Formatters.formatTomoney(res['price']);
      case ResponseFieldMode.sellerRequirement:
        return Formatters.formatTomoney(
          res['priceINR'] ?? res['price'] ?? res['expectedPrice'] ?? "",
        );
    }
  }

  static String currency(Map<String, dynamic> res, ResponseFieldMode mode) {
    switch (mode) {
      case ResponseFieldMode.buyerStock:
        final details = res['stock_details'] ?? "";
        return getCurrencySymbol(
          (details is List && details.isNotEmpty)
              ? details[0]['currency'] ?? ''
              : '',
        );
      case ResponseFieldMode.sellerRequirement:
        final details = res['response_details'] ?? "";
        return getCurrencySymbol(
          details is Map ? details['currency'] ?? '' : '',
        );
    }
  }
}

class CompactResponseList extends StatefulWidget {
  const CompactResponseList({
    super.key,
    required this.responses,
    required this.isLoading,
    required this.mode,
    required this.onConfirm,
    required this.onReject,
    required this.isMypost,
    required this.onView,
    required this.onReload,
    required this.title,
  });

  final List<dynamic> responses;
  final bool isLoading;
  final ResponseFieldMode mode;
  final bool isMypost;
  final String title;
  final void Function(String id) onConfirm;
  final void Function(String id) onReject;
  final void Function(String refId, String responseId) onView;
  final VoidCallback onReload;

  @override
  State<CompactResponseList> createState() => _CompactResponseListState();
}

class _CompactResponseListState extends State<CompactResponseList> {
  bool _filterOpen = false;
  String _selectedStatus = 'All Status';
  ResponsePriceSort _priceSort = ResponsePriceSort.none;

  List<Map<String, dynamic>> get _mapped => widget.responses
      .map((r) => Map<String, dynamic>.from(r is Map ? r : {}))
      .toList();

  List<String> get _statusOptions {
    final statuses =
        _mapped
            .map((r) => (r['status'] ?? '').toString().toLowerCase().trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['all', ...statuses];
  }

  List<Map<String, dynamic>> get _visible {
    final valid = _statusOptions.contains(_selectedStatus)
        ? _selectedStatus
        : 'all';
    final filtered = _mapped.where((r) {
      if (valid == 'all') return true;
      return (r['status'] ?? '').toString().toLowerCase().trim() == valid;
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

  static Color _statusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'approved':
      case 'confirmed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase().trim()) {
      case 'approved':
      case 'confirmed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  static String _formatDate(dynamic v) {
    try {
      if (v == null || v.toString().isEmpty) return 'N/A';
      return DateFormat(
        'dd/MM/yyyy',
      ).format(DateTime.parse(v.toString()).toLocal());
    } catch (_) {
      return 'N/A';
    }
  }

  void _openDrawer(Map<String, dynamic> res) {
    final isPending = res.containsKey('offlineQueueId');
    final status = isPending
        ? 'pending'
        : (res['status'] ?? 'unknown').toString();
    final name = ResponseNameResolver.name(res, widget.mode);
    final image = ResponseNameResolver.getimage(res);
    final currency = ResponseNameResolver.currency(res, widget.mode);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
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
              if (isPending)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PendingUploadIcon(),
                      const SizedBox(width: 8),
                      Text(
                        'Pending upload — will send when online',
                        style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              Card(
                elevation: 2,
                color: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.borderLight, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ResponseItem(
                    avatar: Icons.person,
                    avatarBg: AppColors.accent,
                    img: image,
                    senderName: name,
                    timestamp: isPending
                        ? 'Just now'
                        : _formatDate(res['created_on'] ?? ""),
                    status: isPending
                        ? 'Uploading'
                        : status == "processing"
                        ? 'Not viewed'
                        : status.capitalize,
                    statusColor: isPending
                        ? AppColors.warning
                        : _statusColor(status),
                    quantity: ResponseNameResolver.quantity(res, widget.mode),
                    price: ResponseNameResolver.price(res, widget.mode),
                    total: ResponseNameResolver.total(res, widget.mode),
                    currency: currency,
                    totalColor: AppColors.primary,
                    enquiriesRemark:
                        '${res['remarks'] ?? res['remark'] ?? 'No Remarks'}',
                    responseRemark:
                        res['buyer_remarks']?.toString() ?? 'No Remarks',
                    isrejected: false,
                    showActions: false,
                    onconfirm: () {},
                    onreject: () {},
                    onview: () {
                      widget.onView(
                        res['stockId'] ?? res['requirementId'] ?? "",
                        res['_id'],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _filterDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextThemes.getLightTextTheme.bodySmall!.copyWith(),
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

  @override
  Widget build(BuildContext context) {
    final isActive =
        _filterOpen ||
        _selectedStatus != 'all' ||
        _priceSort != ResponsePriceSort.none;
    if (_visible.isEmpty) {
      return const SizedBox.shrink();
    } // hide if no responses to show

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row: title + filter toggle ──
        Container(
          // margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            // borderRadius: BorderRadius.circular(12),
            // border: Border(top: BorderSide(color: AppColors.primary)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: AppTextThemes.getLightTextTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _filterOpen = !_filterOpen),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    // decoration: BoxDecoration(
                    //   color: isActive
                    //       ? Colors.white.withOpacity(0.12)
                    //       : AppColors.backgroundLight,
                    //   borderRadius: BorderRadius.circular(8),
                    //   border: Border.all(
                    //     color: isActive ? Colors.white : AppColors.borderLight,
                    //     width: 1.2,
                    //   ),
                    // ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        // const SizedBox(width: 4),
                        // Text(
                        //   'Filter',
                        //   style: AppTextThemes.getLightTextTheme.labelSmall
                        //       ?.copyWith(
                        //         color: isActive
                        //             ? Colors.white
                        //             : AppColors.textSecondaryLight,
                        //         fontWeight: FontWeight.w600,
                        //       ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Filter dropdowns (animated) ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _filterOpen
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                // Expanded(
                //   child: CustomDropdownFormField(
                //     value: _selectedStatus,
                //     items: _statusOptions
                //         .map((s) => s == 'all' ? 'All Status' : s.toUpperCase())
                //         .toList(),
                //     labels: _statusOptions
                //         .map((s) => s == 'all' ? 'All Status' : s.toUpperCase())
                //         .toList(),
                //     onChanged: (v) {
                //       if (v == null) return;
                //       setState(() => _selectedStatus = v);
                //     },
                //   ),
                // ),
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
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s == 'all' ? 'All Status' : s.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedStatus = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Expanded(
                //   child: CustomDropdownFormField(
                //     value: _priceSort,
                //     items: const [
                //       DropdownMenuItem(
                //         value: ResponsePriceSort.none,
                //         child: Text('Default'),
                //       ),
                //       DropdownMenuItem(
                //         value: ResponsePriceSort.lowToHigh,
                //         child: Text('Low to High'),
                //       ),
                //       DropdownMenuItem(
                //         value: ResponsePriceSort.highToLow,
                //         child: Text('High to Low'),
                //       ),
                //     ],
                //     // labels: const ['Default', 'Low to High', 'High to Low'],
                //     onChanged: (v) {
                //       if (v == null) return;
                //       setState(() => _priceSort = v);
                //     },
                //   ),
                // ),
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
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _priceSort = v);
                    },
                  ),
                ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),

        const SizedBox(height: 12),

        // ── List ──
        if (widget.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_visible.isEmpty)
          Center(
            child: Column(
              children: [
                Text(
                  widget.responses.isEmpty
                      ? 'No Response'
                      : 'No matching responses',
                  style: AppTextThemes.getLightTextTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _visible.map((res) {
                final status = (res['status'] ?? 'unknown').toString();
                final name = ResponseNameResolver.name(res, widget.mode);
                final price = ResponseNameResolver.price(res, widget.mode);
                final qty = ResponseNameResolver.quantity(res, widget.mode);
                final currency = ResponseNameResolver.currency(
                  res,
                  widget.mode,
                );
                final color = _statusColor(status);

                final image = ResponseNameResolver.getimage(res);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => _openDrawer(res),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          // CircleAvatar(
                          //   radius: 18,
                          //   backgroundColor: AppColors.accent,
                          //   child: const Icon(
                          //     Icons.person,
                          //     color: Colors.white,
                          //     size: 18,
                          //   ),
                          // ),
                          CircleAvatar(
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
                                    name[0],
                                    style: TextStyle(
                                      color: AppColors.textPrimaryLight,
                                      fontSize: 30 * 0.6,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: AppTextThemes.getLightTextTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$qty - ($currency$price /kg)',
                                  style: AppTextThemes.getLightTextTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondaryLight,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (res.containsKey('offlineQueueId')) ...[
                            _PendingUploadIcon(),
                          ] else if (status != 'confirmed' &&
                              status != 'rejected' &&
                              widget.isMypost) ...[
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      widget.onConfirm(res['_id'] ?? ''),
                                  child: Icon(
                                    Icons.check_outlined,
                                    color: AppColors.success,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () =>
                                      widget.onReject(res['_id'] ?? ''),
                                  child: Icon(
                                    Icons.close_outlined,
                                    color: AppColors.error,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Icon(_statusIcon(status), color: color, size: 22),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _PendingUploadIcon extends StatefulWidget {
  const _PendingUploadIcon();

  @override
  State<_PendingUploadIcon> createState() => _PendingUploadIconState();
}

class _PendingUploadIconState extends State<_PendingUploadIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Icon(
        Icons.cloud_upload_outlined,
        color: AppColors.warning,
        size: 22,
      ),
    );
  }
}

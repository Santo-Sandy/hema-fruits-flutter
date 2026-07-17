import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/translate.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/currency.dart';
import 'package:cashew_marketplace/features/screens/activity/enquiry/my_enquiry_screen.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EnquiryViewscreen extends StatefulWidget {
  final EnquiryItem item;

  const EnquiryViewscreen({super.key, required this.item});

  @override
  State<EnquiryViewscreen> createState() => _EnquiryViewscreenState();
}

class _EnquiryViewscreenState extends State<EnquiryViewscreen> {
  String currentRole = 'both';
  @override
  void initState() {
    super.initState();
    final role = context.read<SwapUserProvider>().swapedUser;
    if (currentRole != role) {
      currentRole = role;
    }
  }

  @override
  Widget build(BuildContext context) {
    ContextManager().saveCurrentPage('EnquiryView', context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isKernel = widget.item.productType == 'Kernel';
    final accentColor = isKernel ? AppColors.warning : AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimaryLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.item.grade.isNotEmpty
              ? Translate.t(
                  "enquiryView.title_with_grade",
                ).replaceAll("{grade}", widget.item.grade)
              : Translate.t(
                  "enquiryView.title_with_product",
                ).replaceAll("{product}", widget.item.product),
          style: AppTextThemes.getLightTextTheme.titleMedium?.copyWith(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        height: screenHeight * 0.85,
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: MediaQuery.sizeOf(context).width < 1024
            ? Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: InkWell(
                      // onTap: () {
                      //   widget.item.rawData['post_type'] == 'stock_quotes'
                      //       ? context.push(
                      //           RoutePath.userProfile,
                      //           extra: widget.item.rawData['merchantId'],
                      //         )
                      //       : context.push(
                      //           RoutePath.userProfile,
                      //           extra: widget.item.rawData['buyerId'],
                      //         );
                      // },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              spacing: 0,
                              children: [
                                Text(
                                  widget.item.name,
                                  style: AppTextThemes
                                      .getLightTextTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimaryLight,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    widget.item.rawData['post_type'] ==
                                            'stock_quotes'
                                        ? context.push(
                                            RoutePath.userProfile,
                                            extra: [
                                              widget.item.rawData['merchantId'],
                                              widget.item.rawData,
                                            ],
                                            // [
                                            //   "${widget.item.rawData['merchantId']}",
                                            // ],
                                          )
                                        : context.push(
                                            RoutePath.userProfile,
                                            extra: [
                                              widget.item.rawData['buyerId'],
                                              widget.item.rawData,
                                            ],
                                            // [
                                            //   "${widget.item.rawData['buyerId']}",
                                            //   "${widget.item.id}",
                                            // ],
                                          );
                                  },
                                  icon: Icon(
                                    Icons.open_in_new,
                                    size: 18,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                            widget.item.company == ""
                                ? const SizedBox()
                                : Text(
                                    widget.item.company,
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .titleSmall
                                        ?.copyWith(
                                          overflow: TextOverflow.ellipsis,
                                          color: AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_android,
                                          size: 14,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.item.phone,
                                          style: AppTextThemes
                                              .getLightTextTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors
                                                    .textSecondaryLight,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.mail,
                                          size: 14,
                                          color: accentColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.item.email,
                                          style: AppTextThemes
                                              .getLightTextTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppColors
                                                    .textSecondaryLight,
                                              ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                    ),
                                    // Container(
                                    //   padding: const EdgeInsets.symmetric(
                                    //     horizontal: 10,
                                    //     vertical: 5,
                                    //   ),
                                    //   decoration: BoxDecoration(
                                    //     color: accentColor.withValues(alpha: 0.1),
                                    //     borderRadius: BorderRadius.circular(8),
                                    //   ),
                                    //   child: Row(
                                    //     mainAxisSize: MainAxisSize.min,
                                    //     children: [
                                    //       Icon(
                                    //         isKernel
                                    //             ? Icons.grain_outlined
                                    //             : Icons.eco_outlined,
                                    //         size: 14,
                                    //         color: accentColor,
                                    //       ),
                                    //       const SizedBox(width: 4),
                                    //       Text(
                                    //         widget.item.productType,
                                    //         style: AppTextThemes
                                    //             .getLightTextTheme
                                    //             .labelSmall
                                    //             ?.copyWith(
                                    //               color: accentColor,
                                    //               fontWeight: FontWeight.w700,
                                    //             ),
                                    //       ),
                                    //     ],
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Row(
                            //   children: [
                            //     // Expanded(
                            //     //   child: InkWell(
                            //     //     onTap: () {
                            //     //       item.currentRole == 'buyer'
                            //     //           ? context.push(
                            //     //               RoutePath.postView,
                            //     //               extra: '${item.id}',
                            //     //             )
                            //     //           : context.push(
                            //     //               RoutePath.postSellerView,
                            //     //               extra: '${item.id}',
                            //     //             );
                            //     //     },
                            //     //     child: Container(
                            //     //       padding: const EdgeInsets.symmetric(
                            //     //         horizontal: 12,
                            //     //         vertical: 6,
                            //     //       ),
                            //     //       decoration: BoxDecoration(
                            //     //         color: AppColors.primary.withValues(alpha: 0.08),
                            //     //         borderRadius: BorderRadius.circular(8),
                            //     //       ),
                            //     //       child: Center(
                            //     //         child: Text(
                            //     //           'View',
                            //     //           style: AppTextThemes.getLightTextTheme.labelSmall
                            //     //               ?.copyWith(
                            //     //                 color: AppColors.primary,
                            //     //                 fontWeight: FontWeight.w600,
                            //     //               ),
                            //     //         ),
                            //     //       ),
                            //     //     ),
                            //     //   ),
                            //     // ),

                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      children: [
                        _buildSpecsCard(accentColor),
                        const SizedBox(height: 12),
                        _buildPricingCard(),
                        const SizedBox(height: 12),
                        _buildRemarksCard(),
                        // const SizedBox(height: 12),
                        // _buildPartyCard(),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      children: [
                        _buildSpecsCard(accentColor),
                        const SizedBox(height: 12),
                        _buildPricingCard(),
                        const SizedBox(height: 12),
                        _buildRemarksCard(),
                        // const SizedBox(height: 12),
                        // _buildPartyCard(),
                      ],
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Flexible(
                      child: InkWell(
                        onTap: () {
                          widget.item.rawData['post_type'] == 'stock_quotes'
                              ? context.push(
                                  RoutePath.userProfile,
                                  extra: widget.item.rawData['merchantId'],
                                )
                              : context.push(
                                  RoutePath.userProfile,
                                  extra: widget.item.rawData['buyerId'],
                                );
                        },
                        child: Container(
                          height: 130,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                spacing: 0,
                                children: [
                                  Text(
                                    widget.item.name,
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      widget.item.rawData['post_type'] ==
                                              'stock_quotes'
                                          ? context.push(
                                              RoutePath.userProfile,
                                              extra: widget
                                                  .item
                                                  .rawData['merchantId'],
                                            )
                                          : context.push(
                                              RoutePath.userProfile,
                                              extra: widget
                                                  .item
                                                  .rawData['buyerId'],
                                            );
                                    },
                                    icon: Icon(
                                      Icons.open_in_new,
                                      size: 18,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                widget.item.company,
                                style: AppTextThemes
                                    .getLightTextTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      overflow: TextOverflow.ellipsis,
                                      color: AppColors.textPrimaryLight,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.phone_android,
                                    size: 14,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.item.phone,
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondaryLight,
                                        ),
                                  ),
                                ],
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.mail,
                                    size: 14,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.item.email,
                                    style: AppTextThemes
                                        .getLightTextTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondaryLight,
                                        ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Scrollable content
                ],
              ),
      ),
    );
  }

  Widget _buildStatusBanner(EnquiryStatus status) {
    final (label, color) = switch (status) {
      EnquiryStatus.confirmed => ('Confirmed', AppColors.success),
      EnquiryStatus.rejected => ('Rejected', AppColors.error),
      EnquiryStatus.pending => ('Pending', AppColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  String getTimeAgo(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hr ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} weeks ago';
      }
    } catch (e) {
      return dateString; // fallback
    }
  }

  Widget _buildSpecsCard(Color accentColor) {
    final role = context.read<SwapUserProvider>().swapedUser;
    final res = widget.item.rawData;
    return _DrawerSectionCard(
      title: Translate.t("enquiryView.specifications"),
      icon: widget.item.productType == 'Kernel'
          ? Icons.grain_outlined
          : Icons.eco_outlined,
      iconColor: accentColor,
      openPost: () {
        widget.item.rawData['post_type'] == 'stock_quotes'
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
              );
      },
      statusBanner: _buildStatusBanner(widget.item.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: widget.item.productType == 'Kernel'
                ? [
                    Expanded(
                      child: _buildDrawerStatCell(
                        Translate.t("enquiryView.grade"),
                        widget.item.grade.isNotEmpty
                            ? widget.item.grade
                            : Translate.t("common.na"),
                        accentColor,
                      ),
                    ),
                    _buildDrawerDivider(),
                    Expanded(
                      child: _buildDrawerStatCell(
                        Translate.t("enquiryView.moisture"),
                        widget.item.moistureContent.isNotEmpty
                            ? '${widget.item.moistureContent}%'
                            : Translate.t("common.na"),
                        accentColor,
                      ),
                    ),
                  ]
                : [
                    Expanded(
                      child: _buildDrawerStatCell(
                        Translate.t("enquiryView.nut_count"),
                        widget.item.nutcount.isNotEmpty
                            ? widget.item.nutcount
                            : Translate.t("common.na"),
                        accentColor,
                      ),
                    ),
                    _buildDrawerDivider(),
                    Expanded(
                      child: _buildDrawerStatCell(
                        Translate.t("enquiryView.out_turn"),
                        widget.item.outturn.isNotEmpty
                            ? widget.item.outturn
                            : Translate.t("common.na"),
                        accentColor,
                      ),
                    ),
                    _buildDrawerDivider(),
                    Expanded(
                      child: _buildDrawerStatCell(
                        Translate.t("enquiryView.year"),
                        widget.item.yearOfCrop.isNotEmpty
                            ? widget.item.yearOfCrop
                            : Translate.t("common.na"),
                        accentColor,
                      ),
                    ),
                  ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                getTimeAgo(widget.item.date),
                style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    return _DrawerSectionCard(
      title: Translate.t("enquiryView.pricing_details"),
      icon: Icons.local_offer_outlined,
      child: Column(
        children: [
          _buildDrawerRow(
            Translate.t("enquiryView.total_quantity"),
            widget.item.totalQuantity,
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),
          _buildDrawerRow(
            Translate.t("enquiryView.price_per_kg"),
            '${getCurrencySymbol(widget.item.currency)} ${widget.item.pricePerKg}',
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),
          _buildDrawerRow(
            widget.item.rawData['post_type'] == 'stock_quotes'
                ? Translate.t("enquiryView.available_qty")
                : Translate.t("enquiryView.required_qty"),
            widget.item.quantity,
          ),

          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 10),
          _buildDrawerRow(
            Translate.t("enquiryView.total_price"),
            '${getCurrencySymbol(widget.item.currency)} ${widget.item.totalPrice}',
            color: AppColors.primary,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard() {
    final hasRemark = widget.item.remark?.isNotEmpty ?? false;
    final hasBuyerRemark = widget.item.buyerRemark?.isNotEmpty ?? false;

    if (!hasRemark && !hasBuyerRemark) return const SizedBox.shrink();

    return _DrawerSectionCard(
      title: Translate.t("enquiryView.remarks"),
      icon: Icons.comment_outlined,
      child: Column(
        children: [
          if (hasRemark) ...[
            _buildRemarkBox(
              Translate.t("enquiryView.your_remark"),
              widget.item.remark!,
            ),
            if (hasBuyerRemark) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 10),
            ],
          ],
          if (hasBuyerRemark)
            _buildRemarkBox(
              widget.item.rawData['post_type'] == 'stock_quotes'
                  ? Translate.t("enquiryView.merchant_remark")
                  : Translate.t("enquiryView.buyer_remark"),
              widget.item.buyerRemark!,
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerRow(
    String label,
    String value, {
    Color? color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
              color: color ?? AppColors.textPrimaryLight,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarkBox(String label, String remark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Text(
            remark,
            style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
              color: AppColors.textPrimaryLight,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// Helper widgets
class _DrawerSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;
  final Widget? statusBanner;
  final VoidCallback? openPost;

  const _DrawerSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.openPost,
    this.iconColor,
    this.statusBanner,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: openPost,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (iconColor ?? AppColors.primary).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 14,
                        color: iconColor ?? AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (statusBanner != null) ...[
                  const SizedBox(width: 10),
                  statusBanner!,
                ],
                const SizedBox(width: 10),
                openPost == null
                    ? const SizedBox()
                    : IconButton(
                        onPressed: openPost,
                        icon: Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _buildDrawerStatCell(String label, String value, Color accent) {
  return Column(
    children: [
      Text(
        label,
        style: AppTextThemes.getLightTextTheme.labelSmall?.copyWith(
          color: AppColors.textSecondaryLight,
          letterSpacing: 0.2,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

Widget _buildDrawerDivider() {
  return Container(
    width: 1,
    height: 35,
    color: AppColors.borderLight.withValues(alpha: 0.3),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

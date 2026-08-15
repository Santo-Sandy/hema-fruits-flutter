import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/constants/app_assets.dart';
import 'package:hema_fruits/core/constants/app_strings.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/utils/Responsive/responsivea_context.dart';
import 'package:hema_fruits/core/utils/apptoaster.dart';
import 'package:hema_fruits/core/utils/currency.dart';
import 'package:hema_fruits/shared/models/notification_model.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MarketplaceListingCard extends StatefulWidget {
  final String title;
  final String location;
  final String name;
  final String company;
  final String availableFrom;
  final String availableUntil;
  final String qtyavailablelabel;
  final String qtylabel;
  final String quantity;
  final String pricePerUnit;
  final String currency;
  final String? unit;
  final bool high;
  final bool isrcn;
  final bool liked;
  final Function(bool isLiked)? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onTap;
  final double? height;
  final double? width;
  final String? badge;
  final Color? badgeColor;
  final double? rating;
  final String? posttype;
  final int? reviewCount;
  final Widget? additionalInfo;

  const MarketplaceListingCard({
    super.key,
    required this.title,
    required this.name,
    required this.company,
    required this.location,
    required this.quantity,
    required this.posttype,
    required this.isrcn,
    required this.liked,
    required this.qtylabel,
    required this.qtyavailablelabel,
    required this.availableFrom,
    required this.availableUntil,
    required this.pricePerUnit,
    required this.currency,
    this.unit,
    required this.high,
    this.onLike,
    this.onShare,
    this.onTap,
    this.height,
    this.width,
    this.badge,
    this.badgeColor,
    this.rating,
    this.reviewCount,
    this.additionalInfo,
  });

  @override
  State<MarketplaceListingCard> createState() => _MarketplaceListingCardState();
}

class _MarketplaceListingCardState extends State<MarketplaceListingCard>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late AnimationController _likeAnimationController;
  late Animation<double> _likeScaleAnimation;

  @override
  void initState() {
    super.initState();
    isLiked = widget.liked;
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _likeScaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.bounceOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MarketplaceListingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liked != widget.liked) {
      setState(() {
        isLiked = widget.liked;
      });
    }
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
    });
    widget.onLike?.call(isLiked);
    if (isLiked) {
      _likeAnimationController.forward(from: 0.0);
      AppToast.showFavoriteToast(context, "Added to favorites");
    } else {
      AppToast.showFavoriteToast(context, "Removed from favorites");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStock = widget.posttype == "stocks";
    
    // Parse price to calculate mock discount details
    double priceVal = double.tryParse(widget.pricePerUnit.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    double crossedPrice = priceVal * 1.25; // mock original price showing 20% discount
    String symbol = getCurrencySymbol(widget.currency);
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEEEEEE),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Flipkart-style left accent indicator tag
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: Container(
                  color: isStock ? AppColors.secondary : AppColors.primary,
                ),
              ),

              // Main content layout
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP ROW: Type badge, Rating, Favorite icon
                    Row(
                      children: [
                        // Post Type Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isStock 
                              ? AppColors.secondary.withOpacity(0.1) 
                              : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isStock ? "SELLING STOCK" : "BUY REQUIREMENT",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isStock ? AppColors.secondary : AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Ratings stars
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 14),
                            const SizedBox(width: 2),
                            Text(
                              "4.3",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "(14)",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textHintDark,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Favorite button with bounce animation
                        ScaleTransition(
                          scale: _likeScaleAnimation,
                          child: GestureDetector(
                            onTap: _toggleLike,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                                color: isLiked ? AppColors.error : AppColors.textHintDark,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // BODY ROW: Image + Description
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fruit Category Icon / Photo
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFECECEC),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              widget.isrcn ? AppAssets.iconRcn : AppAssets.iconKernel,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Info section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF212121),
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Location row
                              Row(
                                children: [
                                  Icon(
                                    widget.high ? Icons.anchor_rounded : Icons.location_on_rounded,
                                    size: 13,
                                    color: AppColors.textHintDark,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    widget.high ? "High Sea" : widget.location,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHintDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Posted by metadata
                              Text(
                                "${Translate.t("homeScreen.PostedBy")} : ${widget.name}",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHintDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // LOWER DIVIDER
                    Container(
                      height: 1,
                      color: const Color(0xFFF2F2F2),
                    ),
                    const SizedBox(height: 8),

                    // BOTTOM ROW: Price & Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Pricing info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  "$symbol${widget.pricePerUnit}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isStock ? AppColors.secondary : AppColors.primary,
                                  ),
                                ),
                                Text(
                                  " / ${widget.unit ?? Translate.t("homeScreen.kg")}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHintDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (priceVal > 0)
                              Row(
                                children: [
                                  Text(
                                    "$symbol${crossedPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF878787),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "20% OFF",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF388E3C),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        // Action Button
                        ElevatedButton(
                          onPressed: widget.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStock ? AppColors.secondary : AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: const Size(90, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isStock ? "Bid Now" : "Quote",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Corner ribbon if high priority
              if (widget.high)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFBF360C),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "HIGH SEA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyPostCard extends StatelessWidget {
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String id;
  final bool isrcn;
  final String postedDate;
  final IconData? metadataIcon;
  final String primaryAction;
  final String postlabel;
  final String quantity;
  final String? secondaryAction;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final int editcount;
  final Function()? onPressed;
  final String? posttype; // "stocks" or "requirements"

  const MyPostCard({
    super.key,
    required this.status,
    required this.statusColor,
    required this.statusBgColor,
    required this.icon,
    required this.onPressed,
    required this.postlabel,
    required this.quantity,
    required this.iconColor,
    required this.title,
    required this.isrcn,
    required this.id,
    required this.editcount,
    required this.postedDate,
    this.metadataIcon,
    required this.primaryAction,
    required this.secondaryAction,
    required this.onPrimaryAction,
    this.onSecondaryAction,
    this.posttype,
  });

  @override
  Widget build(BuildContext context) {
    final isStock = posttype == "stocks";
    final cardBg = posttype == null
        ? AppColors.surfaceLight
        : isStock
        ? AppColors.sellerCardBg
        : AppColors.buyerCardBg;
    return Expanded(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.borderDark.withAlpha(80),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: InkWell(
                onTap: onPrimaryAction,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title and ID
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
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
                                isrcn
                                    ? AppAssets.iconRcn
                                    : AppAssets.iconKernel,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                title,
                                                softWrap: true,
                                                maxLines: 2,
                                                style: AppTextThemes
                                                    .getLightTextTheme
                                                    .titleSmall!
                                                    .copyWith(
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                              ),
                                              if (status.toLowerCase() ==
                                                  'active') ...[
                                                const SizedBox(width: 5),
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Color.fromARGB(
                                                          255,
                                                          59,
                                                          167,
                                                          124,
                                                        ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (posttype != null)
                                                _PostTypeBadge(
                                                  posttype: posttype!,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // PopupMenuButton<String>(
                                    //   padding: EdgeInsets.zero,
                                    //   tooltip: 'More options',
                                    //   icon: Icon(
                                    //     Icons.more_vert_rounded,
                                    //     color: AppColors.textPrimary,
                                    //     size: 24,
                                    //   ),
                                    //   onSelected: (value) {
                                    //     if (value == 'update') {
                                    //       onSecondaryAction?.call();
                                    //       return;
                                    //     }
                                    //     if (value == 'delete') {
                                    //       onPressed?.call();
                                    //     }
                                    //   },
                                    //   itemBuilder: (context) => [
                                    //     PopupMenuItem<String>(
                                    //       value: 'update',
                                    //       enabled:
                                    //           editcount > 0 &&
                                    //           onSecondaryAction != null,
                                    //       child: Row(
                                    //         children: [
                                    //           Icon(
                                    //             Icons.edit_outlined,
                                    //             size: 18,
                                    //             color: editcount > 0
                                    //                 ? AppColors.accent
                                    //                 : AppColors.textHint,
                                    //           ),
                                    //           const SizedBox(width: 10),
                                    //           Text(
                                    //             'Edit',
                                    //             style: TextStyle(
                                    //               color: editcount > 0
                                    //                   ? AppColors.textPrimary
                                    //                   : AppColors.textHint,
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       ),
                                    //     ),
                                    //     PopupMenuItem<String>(
                                    //       value: 'delete',
                                    //       child: Row(
                                    //         children: [
                                    //           Icon(
                                    //             Icons.delete_outline,
                                    //             size: 18,
                                    //             color: AppColors.error,
                                    //           ),
                                    //           const SizedBox(width: 10),
                                    //           Text(
                                    //             'Delete',
                                    //             style: TextStyle(
                                    //               color: AppColors.error,
                                    //             ),
                                    //           ),
                                    //         ],
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                  ],
                                ),

                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.end,
                                //   children: [
                                //     Text(
                                //       "Edit left: $editcount",
                                //       style: const TextStyle(
                                //         fontSize: 14,
                                //         fontWeight: FontWeight.w700,
                                //         color: AppColors.textHint,
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                // const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Icon(
                            //   Icons.production_quantity_limits,
                            //   size: 16,
                            //   color: AppColors.textHintDark,
                            // ),
                            // const SizedBox(width: 6),
                            // Text(
                            //   '$postlabel: ',
                            //   style: AppTextThemes.getLightTextTheme.bodySmall!
                            //       .copyWith(color: AppColors.textHintDark),
                            // ),
                            Text(
                              "$quantity $postlabel $postedDate",
                              maxLines: 2,
                              style: AppTextThemes.getLightTextTheme.bodyMedium!
                                  .copyWith(
                                    // fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            // ? Container(
                            //     padding: const EdgeInsets.symmetric(
                            //       vertical: 6,
                            //       horizontal: 10,
                            //     ),
                            //     decoration: BoxDecoration(
                            //       border: Border.all(
                            //         color: AppColors.disabled,
                            //         width: 2,
                            //       ),
                            //       borderRadius: BorderRadius.circular(24),
                            //     ),
                            //     child: Center(
                            //       child: Row(
                            //         children: [
                            //           Text(
                            //             secondaryAction!,
                            //             style: const TextStyle(
                            //               fontSize: 16,
                            //               fontWeight: FontWeight.w900,
                            //               color: AppColors.disabled,
                            //             ),
                            //           ),
                            //           const SizedBox(width: 2),
                            //           Icon(
                            //             Icons.edit,
                            //             size: 18,
                            //             color: AppColors.disabled,
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   )
                            // : _OutlinedButton(
                            //     label: secondaryAction!,
                            //     onTap: onSecondaryAction ?? () {},
                            //   ),
                          ],
                        ),
                      ),

                      // Action buttons
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              tooltip: 'More options',
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.textPrimary,
                size: 24,
              ),
              onSelected: (value) {
                if (value == 'update') {
                  if (editcount > 0 && onSecondaryAction != null) {
                    onSecondaryAction?.call();
                  }
                  return;
                }
                if (value == 'delete') {
                  onPressed?.call();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'update',
                  enabled: editcount > 0 && onSecondaryAction != null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: editcount > 0
                            ? AppColors.accent
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: editcount > 0
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: AppColors.error)),
                    ],
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

class _PostTypeBadge extends StatelessWidget {
  final String posttype;
  const _PostTypeBadge({required this.posttype});

  @override
  Widget build(BuildContext context) {
    final isStock = posttype == 'stocks';
    final color = isStock ? AppColors.buyerCardAccent : AppColors.merchantColor;
    final label = isStock ? 'Sale' : 'Purchase';
    final icon = isStock
        ? Icons.storefront_outlined
        : Icons.shopping_cart_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
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
}

class CreditBalanceCard extends StatelessWidget {
  final int creditBalance;
  final VoidCallback? onAddCredits;
  final bool ishorizontal;

  const CreditBalanceCard({
    super.key,
    this.creditBalance = 12000,
    this.onAddCredits,
    this.ishorizontal = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ishorizontal
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Icon + balance info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.toll_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translate.t("creditScreen.CreditPoints"),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatNumber(creditBalance),
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Right: Add credits button
                GestureDetector(
                  onTap: onAddCredits,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          Translate.t("creditScreen.AddCredits"),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left: Icon + balance info
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.toll_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translate.t("creditScreen.CreditPoints"),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatNumber(creditBalance),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Right: Add credits button
                GestureDetector(
                  onTap: onAddCredits,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Translate.t("creditScreen.AddCredits"),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

class PaymentProcessingLoader extends StatefulWidget {
  const PaymentProcessingLoader({super.key});

  @override
  State<PaymentProcessingLoader> createState() =>
      _PaymentProcessingLoaderState();
}

class _PaymentProcessingLoaderState extends State<PaymentProcessingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.25),
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Loader
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 70,
                      width: 70,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: 26,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  "Processing Payment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  "Please wait while we securely transfer your money",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ImageCardViewer extends StatefulWidget {
  final List<String> imageUrls;

  const ImageCardViewer({super.key, required this.imageUrls});

  @override
  State<ImageCardViewer> createState() => _ImageCardViewerState();
}

class _ImageCardViewerState extends State<ImageCardViewer> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  static const String _apiBase = "https://cerp.sgp1.digitaloceanspaces.com/";

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return const SizedBox(); // or placeholder
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final url = '$_apiBase${widget.imageUrls[index]}';

                return GestureDetector(
                  onTap: () => _openFullScreen(index),
                  child: Hero(
                    tag: url,
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      fit: BoxFit.cover,
                      progressIndicatorBuilder: (context, child, progress) {
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorWidget: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                final isActive = index == _currentIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 10 : 6,
                  height: isActive ? 10 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.disabled,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreen(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenViewer(
          imageUrls: widget.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class FullScreenViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        itemBuilder: (context, index) {
          final url = '${AppStrings.imageApiBase}${widget.imageUrls[index]}';

          return Center(
            child: Hero(
              tag: url,
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onTap;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.onMarkAsRead,
    this.onTap,
  }) : super(key: key);

  Color _getTypeColor() {
    switch (notification.type) {
      case NotificationType.enquiry:
        return AppColors.info;
      case NotificationType.subscription:
        return AppColors.warning;
      case NotificationType.system:
        return AppColors.error;
      case NotificationType.general:
      default:
        return AppColors.primary;
    }
  }

  String _getTypeLabel() {
    return notification.type.name[0].toUpperCase() +
        notification.type.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? bgColor : bgColor,
          border: Border.all(
            color: notification.isRead
                ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                : AppColors.primary.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight.withValues(
                alpha: notification.isRead ? 0.05 : 0.1,
              ),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getTypeColor().withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  _getNotificationIcon(),
                  color: _getTypeColor(),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextThemes.getLightTextTheme.titleSmall
                              ?.copyWith(
                                color: textColor,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          GestureDetector(
                            onTap: onMarkAsRead,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextThemes.getLightTextTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeLabel(),
                          style: AppTextThemes.getLightTextTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Text(
                        _formatTime(notification.createdAt),
                        style: AppTextThemes.getLightTextTheme.labelSmall
                            ?.copyWith(color: secondaryTextColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case NotificationType.enquiry:
        return Icons.help_outline;
      case NotificationType.subscription:
        return Icons.card_membership;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.general:
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

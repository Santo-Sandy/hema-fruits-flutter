import 'package:cashew_marketplace/core/utils/countdowncontroller.dart';
import 'package:cashew_marketplace/core/utils/formatters.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
import 'package:cashew_marketplace/shared/theme/app_text_theme.dart';
import 'package:flutter/material.dart';

class BiddingCardsWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime closingIn;
  final String qty;
  final Color? color;
  final String? posttype;
  final VoidCallback? onPlaceBid;

  const BiddingCardsWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.closingIn,
    required this.qty,
    this.color = Colors.white,
    this.posttype,
    this.onPlaceBid,
  });

  @override
  Widget build(BuildContext context) {
    final isStock = posttype == 'stocks';
    final typeIcon = isStock
        ? Icons.storefront_outlined
        : Icons.shopping_cart_outlined;
    final typeColor = isStock
        ? AppColors.buyerCardAccent
        : AppColors.merchantColor;
    return InkWell(
      onTap: onPlaceBid,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark),
          boxShadow: [
            BoxShadow(
              color: AppColors.textHint.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (posttype != null) ...[
                  Icon(typeIcon, size: 13, color: typeColor),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextThemes.getLightTextTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 12, color: AppColors.buyerColor),
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: AppTextThemes.getLightTextTheme.bodyMedium!.copyWith(
                    color: AppColors.buyerColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              qty,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextThemes.getLightTextTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
            Text(
              'Avail. Upto: ',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextThemes.getLightTextTheme.bodySmall!.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiaryLight,
              ),
            ),
            Text(
              Formatters.formatDate(closingIn.toString()),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextThemes.getLightTextTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            CountdownWidget(
              endDate: closingIn,
              backgroundColor: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

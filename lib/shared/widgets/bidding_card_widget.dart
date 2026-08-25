import 'package:hema_fruits/core/utils/countdowncontroller.dart';
import 'package:hema_fruits/core/utils/formatters.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:hema_fruits/shared/theme/app_text_theme.dart';
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
    final typeIcon = isStock ? Icons.storefront_rounded : Icons.shopping_bag_rounded;
    final typeLabel = isStock ? 'SALE' : 'PURCHASE';
    final typeBadgeColor = isStock ? const Color(0xFF1E5E42) : const Color(0xFF1976D2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: typeBadgeColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Badge Row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeBadgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(typeIcon, size: 11, color: typeBadgeColor),
                      const SizedBox(width: 3),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: typeBadgeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 10, color: Colors.orange),
                      const SizedBox(width: 2),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Title & Location
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 11, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quantity Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1E5E42).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Qty:',
                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    qty,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E5E42),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Timer & Place Bid Button Row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                CountdownWidget(
                  endDate: closingIn,
                  backgroundColor: AppColors.error,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeBadgeColor,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 1,
                    ),
                    onPressed: onPlaceBid,
                    child: const Text(
                      'PLACE BID',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
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

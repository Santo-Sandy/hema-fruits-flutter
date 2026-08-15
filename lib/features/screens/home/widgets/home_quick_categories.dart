import 'package:flutter/material.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class HomeQuickCategories extends StatelessWidget {
  final Function(String category) onCategoryTap;
  final Function(String role) onRoleTap;
  final VoidCallback onWalletTap;

  const HomeQuickCategories({
    super.key,
    required this.onCategoryTap,
    required this.onRoleTap,
    required this.onWalletTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.layers_outlined,
        'label': "RCN",
        'category': "RCN",
        'color': AppColors.primary,
      },
      {
        'icon': Icons.grain_rounded,
        'label': "Kernel",
        'category': "Kernel",
        'color': AppColors.secondary,
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'label': "Buy Orders",
        'role': "buyer",
        'color': const Color(0xFF0D47A1),
      },
      {
        'icon': Icons.store_mall_directory_outlined,
        'label': "Sell Offers",
        'role': "seller",
        'color': const Color(0xFF388E3C),
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': "Wallet",
        'action': onWalletTap,
        'color': const Color(0xFFE65100),
      },
    ];

    return Container(
      height: 92,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              if (item['action'] != null) {
                (item['action'] as VoidCallback).call();
                return;
              }
              if (item['role'] != null) {
                onRoleTap(item['role'] as String);
                onCategoryTap("All Listings");
              } else {
                onCategoryTap(item['category'] as String);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (item['color'] as Color).withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

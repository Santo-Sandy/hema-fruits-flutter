import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<EcommCatalogProvider>();
    final cart = context.watch<EcommCartProvider>();

    final wishlistedProducts = catalog.products.where((p) => catalog.wishlistProductIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Wishlist',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: wishlistedProducts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite_border, size: 60, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Wishlist is Empty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore our farm fresh fruits and organic vegetables and tap the heart icon to save items for later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: () => context.pop(),
                      child: const Text(
                        'Explore Catalog',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: wishlistedProducts.length,
              itemBuilder: (context, index) {
                final product = wishlistedProducts[index];
                final variant = product.defaultVariant;

                final cartIndex = cart.items.indexWhere((item) => item.variantId == variant.id);
                final cartQty = cartIndex >= 0 ? cart.items[cartIndex].quantity : 0;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product.images.isNotEmpty ? product.images.first : '',
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[100]),
                            errorWidget: (context, url, err) => Container(color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.isOrganic)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Organic',
                                    style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              Text(
                                product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                variant.formattedWeight,
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '₹${variant.sellingPrice.toInt()}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 6),
                                  if (variant.mrp > variant.sellingPrice)
                                    Text(
                                      '₹${variant.mrp.toInt()}',
                                      style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 11),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.favorite, color: AppColors.secondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => catalog.toggleWishlist(product.id),
                            ),
                            const SizedBox(height: 12),
                            cartQty > 0
                                ? Container(
                                    height: 28,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => cart.updateQuantity(variant.id, -1),
                                          child: const Icon(Icons.remove, color: Colors.white, size: 14),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('$cartQty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        InkWell(
                                          onTap: () => cart.updateQuantity(variant.id, 1),
                                          child: const Icon(Icons.add, color: Colors.white, size: 14),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(
                                    height: 28,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        elevation: 0,
                                      ),
                                      onPressed: () {
                                        cart.addItem(product, variant);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${product.title} added to basket!'),
                                            backgroundColor: AppColors.primary,
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: const Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                  ),
                          ],
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

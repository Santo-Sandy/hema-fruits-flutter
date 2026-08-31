import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedVariantIndex = 0;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<EcommCatalogProvider>();
    final cart = context.watch<EcommCartProvider>();

    final productList = catalog.products.where((p) => p.id == widget.productId).toList();
    final product = productList.isNotEmpty ? productList.first : catalog.products.first;

    final selectedVariant = (product.variants.isNotEmpty && _selectedVariantIndex < product.variants.length)
        ? product.variants[_selectedVariantIndex]
        : product.defaultVariant;

    final cartIndex = cart.items.indexWhere((item) => item.variantId == selectedVariant.id);
    final cartQty = cartIndex >= 0 ? cart.items[cartIndex].quantity : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(product.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              catalog.isProductWishlisted(product.id) ? Icons.favorite : Icons.favorite_border,
              color: catalog.isProductWishlisted(product.id) ? AppColors.secondary : Colors.black87,
            ),
            onPressed: () {
              catalog.toggleWishlist(product.id);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: product.images.isNotEmpty ? product.images.first : '',
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[100]),
                        errorWidget: (context, url, err) => Container(color: Colors.grey[200]),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quality Grade & Organic Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF0F9D58)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF0F9D58), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              product.qualityGrade,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.isOrganic)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.eco, color: Colors.amberAccent, size: 14),
                              SizedBox(width: 4),
                              Text('100% Organic', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Title & Origin
                  Text(
                    product.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),

                  const SizedBox(height: 6),

                  // Rating Summary Row
                  GestureDetector(
                    onTap: () => context.push('/ecommerce/product/${product.id}/reviews'),
                    child: Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < product.avgRating.floor() ? Icons.star : Icons.star_half,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${product.avgRating}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${product.reviewCount} reviews)',
                          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Farm Origin: ${product.originRegion}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Price Details
                  Row(
                    children: [
                      Text(
                        '₹${selectedVariant.sellingPrice.toInt()}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                      ),
                      const SizedBox(width: 8),
                      if (selectedVariant.mrp > selectedVariant.sellingPrice)
                        Text(
                          'MRP ₹${selectedVariant.mrp.toInt()}',
                          style: const TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough, color: Colors.grey),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '(${selectedVariant.formattedWeight})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Weight Variant Selector Pills
                  const Text('Select Pack Size:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: List.generate(product.variants.length, (idx) {
                      final v = product.variants[idx];
                      final isSelected = _selectedVariantIndex == idx;

                      return ChoiceChip(
                        label: Text('${v.formattedWeight} - ₹${v.sellingPrice.toInt()}'),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0F9D58),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedVariantIndex = idx);
                          }
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Freshness & Shelf-Life Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Freshness Guaranteed for ${product.shelfLifeDays} Days',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                product.storageInstructions,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Product Overview
                  const Text('Description & Benefits', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  ),

                  const SizedBox(height: 20),

                  // Quality Certifications / Badges
                  const Text('Quality Certifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCertBadge(Icons.verified_user, '100% Safe', 'Pesticide free'),
                      _buildCertBadge(Icons.health_and_safety, 'USDA Organic', 'Certified process'),
                      _buildCertBadge(Icons.local_shipping, 'Cold Chain', 'Speed delivery'),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Related Products slider
                  _buildRelatedProducts(context, catalog, product, cart),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Total Price', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      '₹${selectedVariant.sellingPrice.toInt()}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
                const Spacer(),
                cartQty > 0
                    ? Container(
                        height: 48,
                        width: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F9D58),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white),
                              onPressed: () => cart.updateQuantity(selectedVariant.id, -1),
                            ),
                            Text('$cartQty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white),
                              onPressed: () => cart.updateQuantity(selectedVariant.id, 1),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          cart.addItem(product, selectedVariant);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.title} added to cart!'),
                              backgroundColor: const Color(0xFF1B5E20),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag, color: Colors.white),
                        label: const Text('ADD TO CART', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildCertBadge(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
        Text(subtitle, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRelatedProducts(BuildContext context, EcommCatalogProvider catalog, StoreProduct currentProduct, EcommCartProvider cart) {
    final related = catalog.products.where((p) => p.categoryId == currentProduct.categoryId && p.id != currentProduct.id).toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Related Fresh Stock', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: related.length,
            itemBuilder: (context, idx) {
              final prod = related[idx];
              final variant = prod.defaultVariant;

              return GestureDetector(
                onTap: () {
                  context.pushReplacement('/ecommerce/product/${prod.id}');
                },
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: CachedNetworkImage(
                          imageUrl: prod.images.isNotEmpty ? prod.images.first : '',
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[100]),
                          errorWidget: (context, url, err) => Container(color: Colors.grey[200]),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prod.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87),
                            ),
                            Text(variant.formattedWeight, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('₹${variant.sellingPrice.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                                InkWell(
                                  onTap: () {
                                    cart.addItem(prod, variant);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${prod.title} added!'),
                                        backgroundColor: AppColors.primary,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.add, size: 12, color: AppColors.primary),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

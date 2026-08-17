import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
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
            icon: const Icon(Icons.favorite_border, color: Colors.black87),
            onPressed: () {},
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

                  const SizedBox(height: 4),

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
}

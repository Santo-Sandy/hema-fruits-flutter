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
  int _currentImageIndex = 0;

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(product.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50), size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF2C3E50)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product link copied to clipboard!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded, color: Color(0xFF2C3E50)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Gallery Carousel
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            itemCount: product.images.isNotEmpty ? product.images.length : 1,
                            onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
                            itemBuilder: (context, idx) {
                              final imgUrl = product.images.isNotEmpty ? product.images[idx] : '';
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CachedNetworkImage(
                                    imageUrl: imgUrl,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                                    errorWidget: (context, url, err) => Container(
                                      color: const Color(0xFFE8F5E9),
                                      child: const Icon(Icons.eco_rounded, size: 64, color: Color(0xFF1E5E42)),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Carousel Dots
                        if (product.images.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(product.images.length, (idx) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentImageIndex == idx ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == idx ? const Color(0xFF1E5E42) : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Details Container
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quality Grade & Organic Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF1E5E42).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_rounded, color: Color(0xFF1E5E42), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.qualityGrade,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E5E42)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (product.isOrganic)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20),
                                  borderRadius: BorderRadius.circular(8),
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
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Farm Origin: ${product.originRegion}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Price Details Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '₹${selectedVariant.sellingPrice.toInt()}',
                                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1E5E42)),
                                      ),
                                      const SizedBox(width: 8),
                                      if (selectedVariant.mrp > selectedVariant.sellingPrice)
                                        Text(
                                          'MRP ₹${selectedVariant.mrp.toInt()}',
                                          style: TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough, color: Colors.grey[400]),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Inclusive of all taxes • (${selectedVariant.formattedWeight})',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Weight Variant Selector
                        const Text('Select Pack Size:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: List.generate(product.variants.length, (idx) {
                            final v = product.variants[idx];
                            final isSelected = _selectedVariantIndex == idx;

                            return ChoiceChip(
                              label: Text('${v.formattedWeight} - ₹${v.sellingPrice.toInt()}'),
                              selected: isSelected,
                              selectedColor: const Color(0xFF1E5E42),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: isSelected ? const Color(0xFF1E5E42) : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
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
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.timer_outlined, color: Color(0xFF795548), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guaranteed Fresh for ${product.shelfLifeDays} Days',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF5D4037)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.storageInstructions,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF795548)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description
                        const Text('Description & Benefits', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
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
                      '₹${(selectedVariant.sellingPrice * (cartQty > 0 ? cartQty : 1)).toInt()}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E5E42)),
                    ),
                  ],
                ),
                const Spacer(),
                cartQty > 0
                    ? Container(
                        height: 46,
                        width: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E5E42),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                              onPressed: () => cart.updateQuantity(selectedVariant.id, -1),
                            ),
                            Text('$cartQty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white, size: 18),
                              onPressed: () => cart.updateQuantity(selectedVariant.id, 1),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5E42),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          cart.addItem(product, selectedVariant);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.title} added to cart!'),
                              backgroundColor: const Color(0xFF1E5E42),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                        label: const Text('ADD TO CART', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

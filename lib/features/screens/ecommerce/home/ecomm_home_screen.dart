import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EcommHomeScreen extends StatefulWidget {
  const EcommHomeScreen({super.key});

  @override
  State<EcommHomeScreen> createState() => _EcommHomeScreenState();
}

class _EcommHomeScreenState extends State<EcommHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EcommCatalogProvider>().initCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<EcommCatalogProvider>();
    final cart = context.watch<EcommCartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFAFAFAF).withValues(alpha: 0.1),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F9D58), Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on, color: Colors.amberAccent, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Deliver to HSR Layout, 560102',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                            ],
                          ),
                          Text(
                            'Express 2-Hour Delivery Available ⚡',
                            style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => catalog.setSearchQuery(val),
                      decoration: const InputDecoration(
                        hintText: 'Search fresh apples, spinach, cashews...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF0F9D58)),
                        suffixIcon: Icon(Icons.mic, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: catalog.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D58)))
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Slider
                      if (catalog.banners.isNotEmpty)
                        SizedBox(
                          height: 140,
                          child: PageView.builder(
                            itemCount: catalog.banners.length,
                            itemBuilder: (context, index) {
                              final banner = catalog.banners[index];
                              return Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: banner.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                                        errorWidget: (context, url, err) => Container(color: Colors.green[100]),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 16,
                                        top: 20,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              banner.title,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              banner.subtitle,
                                              style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0F9D58),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: const Text('SHOP NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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

                      // Category Pills Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Explore Fresh Categories',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            InkWell(
                              onTap: () => catalog.toggleOrganicFilter(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: catalog.isOrganicOnly ? const Color(0xFF1B5E20) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF0F9D58)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.eco, size: 14, color: catalog.isOrganicOnly ? Colors.white : const Color(0xFF0F9D58)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Organic Only',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: catalog.isOrganicOnly ? Colors.white : const Color(0xFF0F9D58),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category Bar
                      SizedBox(
                        height: 95,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: catalog.categories.length,
                          itemBuilder: (context, index) {
                            final cat = catalog.categories[index];
                            final isSelected = catalog.selectedCategoryId == cat.id;

                            return GestureDetector(
                              onTap: () => catalog.selectCategory(cat.id),
                              child: Container(
                                width: 85,
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0F9D58) : Colors.grey.withValues(alpha: 0.2),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: cat.iconUrl,
                                        height: 42,
                                        width: 42,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Icon(Icons.shopping_basket, color: Colors.green),
                                        errorWidget: (context, url, err) => const Icon(Icons.nature, color: Colors.green),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      cat.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Flash Deals Badge Header
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.amber, size: 20),
                            SizedBox(width: 6),
                            Text(
                              'Hema Guaranteed Freshness • Harvested Daily',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Product Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: catalog.products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final product = catalog.products[index];
                            final variant = product.defaultVariant;

                            return ProductCardWidget(product: product, variant: variant, cart: cart);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Cart Bar
                if (cart.totalCount > 0)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 16,
                    child: InkWell(
                      onTap: () => context.push('/ecommerce/cart'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.amberAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cart.totalCount}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${cart.grandTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  cart.freeDeliveryProgress >= 1.0 ? 'FREE Express Shipping Applied' : 'Add ₹${cart.amountNeededForFreeDelivery.toStringAsFixed(0)} for FREE delivery',
                                  style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Text(
                              'View Cart',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class ProductCardWidget extends StatelessWidget {
  final StoreProduct product;
  final ProductVariant variant;
  final EcommCartProvider cart;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.variant,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    final discountPercent = variant.mrp > 0
        ? (((variant.mrp - variant.sellingPrice) / variant.mrp) * 100).round()
        : 0;

    final cartIndex = cart.items.indexWhere((item) => item.variantId == variant.id);
    final cartQty = cartIndex >= 0 ? cart.items[cartIndex].quantity : 0;

    return GestureDetector(
      onTap: () => context.push('/ecommerce/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: product.images.isNotEmpty ? product.images.first : '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[100]),
                    errorWidget: (context, url, err) => Container(color: Colors.grey[200]),
                  ),
                ),
                if (discountPercent > 0)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (product.isOrganic)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.eco, color: Colors.white, size: 10),
                          SizedBox(width: 2),
                          Text('Organic', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      variant.formattedWeight,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${variant.sellingPrice.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                      ),
                      const SizedBox(width: 4),
                      if (variant.mrp > variant.sellingPrice)
                        Text(
                          '₹${variant.mrp.toInt()}',
                          style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  cartQty > 0
                      ? Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F9D58),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              InkWell(
                                onTap: () => cart.updateQuantity(variant.id, -1),
                                child: const Icon(Icons.remove, color: Colors.white, size: 16),
                              ),
                              Text('$cartQty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              InkWell(
                                onTap: () => cart.updateQuantity(variant.id, 1),
                                child: const Icon(Icons.add, color: Colors.white, size: 16),
                              ),
                            ],
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0F9D58)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => cart.addItem(product, variant),
                            child: const Text(
                              'ADD',
                              style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

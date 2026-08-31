import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/features/screens/ecommerce/home/ecomm_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;

  const CategoryProductsScreen({super.key, required this.categoryId});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSubcategoryId = '';
  String _searchQuery = '';
  bool _isOrganicOnly = false;
  bool _isGridView = true;
  String _sortBy = 'POPULARITY';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EcommCatalogProvider>().initCatalog();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<EcommCatalogProvider>();
    final cart = context.watch<EcommCartProvider>();

    final categoryList = catalog.categories.where((c) => c.id == widget.categoryId).toList();
    if (categoryList.isEmpty && catalog.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F9D58))),
      );
    }

    final category = categoryList.isNotEmpty ? categoryList.first : catalog.categories.first;

    // Filter products locally for instantaneous feel, while respecting catalog state
    final filteredProducts = catalog.products.where((product) {
      if (product.categoryId != widget.categoryId) return false;
      if (_selectedSubcategoryId.isNotEmpty && product.subcategoryId != _selectedSubcategoryId) return false;
      if (_isOrganicOnly && !product.isOrganic) return false;
      if (_searchQuery.isNotEmpty && !product.title.toLowerCase().contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();

    if (_sortBy == 'PRICE_ASC') {
      filteredProducts.sort((a, b) => a.defaultVariant.sellingPrice.compareTo(b.defaultVariant.sellingPrice));
    } else if (_sortBy == 'PRICE_DESC') {
      filteredProducts.sort((a, b) => b.defaultVariant.sellingPrice.compareTo(a.defaultVariant.sellingPrice));
    } else if (_sortBy == 'RATING') {
      filteredProducts.sort((a, b) => b.avgRating.compareTo(a.avgRating));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Premium Sliver App Bar with Category Banner Image
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0F9D58),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      shadows: [
                        Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 4),
                      ],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: category.bannerUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.green[100]),
                        errorWidget: (context, url, err) => Container(color: Colors.green[200]),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar & Filter options header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      // Search inside category
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search in ${category.name}...',
                            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF0F9D58)),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Organic only filter option row
                      Row(
                        children: [
                          const Text(
                            'Refine Results',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
                          ),
                          const Spacer(),
                          // Layout Toggle
                          IconButton(
                            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: const Color(0xFF0F9D58), size: 20),
                            onPressed: () => setState(() => _isGridView = !_isGridView),
                          ),
                          // Sorting Dropdown
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.sort, color: Color(0xFF0F9D58), size: 20),
                            onSelected: (val) => setState(() => _sortBy = val),
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'POPULARITY', child: Text('Popularity')),
                              const PopupMenuItem(value: 'PRICE_ASC', child: Text('Price: Low to High')),
                              const PopupMenuItem(value: 'PRICE_DESC', child: Text('Price: High to Low')),
                              const PopupMenuItem(value: 'RATING', child: Text('Customer Rating')),
                            ],
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isOrganicOnly = !_isOrganicOnly;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isOrganicOnly ? const Color(0xFF1B5E20) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF0F9D58)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.eco, size: 14, color: _isOrganicOnly ? Colors.white : const Color(0xFF0F9D58)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Organic Only',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isOrganicOnly ? Colors.white : const Color(0xFF0F9D58),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Subcategories pills selector
              if (category.subcategories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: category.subcategories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final sub = isAll ? null : category.subcategories[index - 1];
                        final subId = isAll ? '' : sub!.id;
                        final name = isAll ? 'All Items' : sub!.name;
                        final isSelected = _selectedSubcategoryId == subId;

                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(name),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F9D58),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedSubcategoryId = subId;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Product Listing Grid
              filteredProducts.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_outlined, size: 70, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No products found in ${category.name}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            const Text('Try adjusting filters or searching another keyword', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                      sliver: _isGridView
                          ? SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = filteredProducts[index];
                                  final variant = product.defaultVariant;
                                  return ProductCardWidget(product: product, variant: variant, cart: cart);
                                },
                                childCount: filteredProducts.length,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = filteredProducts[index];
                                  final variant = product.defaultVariant;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: _buildProductListItem(context, product, variant, cart),
                                  );
                                },
                                childCount: filteredProducts.length,
                              ),
                            ),
                    ),
            ],
          ),

          // Floating Cart Summary Bar
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
  Widget _buildProductListItem(BuildContext context, StoreProduct product, ProductVariant variant, EcommCartProvider cart) {
    final cartIndex = cart.items.indexWhere((item) => item.variantId == variant.id);
    final cartQty = cartIndex >= 0 ? cart.items[cartIndex].quantity : 0;

    return GestureDetector(
      onTap: () => context.push('/ecommerce/product/${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.images.isNotEmpty ? product.images.first : '',
                height: 80,
                width: 80,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${variant.sellingPrice.toInt()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                      ),
                      const SizedBox(width: 6),
                      if (variant.mrp > variant.sellingPrice)
                        Text(
                          '₹${variant.mrp.toInt()}',
                          style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11, color: Colors.grey),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            cartQty > 0
                ? Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F9D58),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.white, size: 14),
                          onPressed: () => cart.updateQuantity(variant.id, -1),
                        ),
                        Text('$cartQty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white, size: 14),
                          onPressed: () => cart.updateQuantity(variant.id, 1),
                        ),
                      ],
                    ),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0F9D58)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () => cart.addItem(product, variant),
                    child: const Text('ADD', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
          ],
        ),
      ),
    );
  }
}

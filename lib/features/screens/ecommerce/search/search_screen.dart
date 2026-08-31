import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/features/screens/ecommerce/home/ecomm_home_screen.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isListening = false;
  String _selectedCategory = 'ALL';
  bool _organicOnly = false;
  String _sortBy = 'POPULARITY'; // POPULARITY, PRICE_ASC, PRICE_DESC, RATING
  String _query = '';

  final List<String> _trendingSearches = [
    'Mangoes 🥭',
    'Palak 🥬',
    'Cashews 🥜',
    'Apples 🍎',
    'Berries 🍓',
    'Walnuts 🌰',
  ];

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

  void _triggerVoiceSearch() {
    setState(() => _isListening = true);
    // Simulate hearing voice input and finishing search after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isListening = false;
          _query = 'Alphonso Mangoes';
          _searchController.text = 'Alphonso Mangoes';
        });
      }
    });
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter & Sort Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = 'ALL';
                            _organicOnly = false;
                            _sortBy = 'POPULARITY';
                          });
                        },
                        child: const Text('Reset All', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('ALL', 'All Items', _selectedCategory, (val) => setModalState(() => _selectedCategory = val)),
                      _filterChip('cat_fruits', 'Fresh Fruits', _selectedCategory, (val) => setModalState(() => _selectedCategory = val)),
                      _filterChip('cat_veggies', 'Vegetables', _selectedCategory, (val) => setModalState(() => _selectedCategory = val)),
                      _filterChip('cat_dry_nuts', 'Nuts & Seeds', _selectedCategory, (val) => setModalState(() => _selectedCategory = val)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Farming Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),
                  FilterChip(
                    label: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('100% Organic Pesticide-Free'),
                      ],
                    ),
                    selected: _organicOnly,
                    selectedColor: AppColors.primarySoft,
                    checkmarkColor: AppColors.primary,
                    onSelected: (selected) {
                      setModalState(() {
                        _organicOnly = selected;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('POPULARITY', 'Popularity', _sortBy, (val) => setModalState(() => _sortBy = val)),
                      _filterChip('PRICE_ASC', 'Price: Low to High', _sortBy, (val) => setModalState(() => _sortBy = val)),
                      _filterChip('PRICE_DESC', 'Price: High to Low', _sortBy, (val) => setModalState(() => _sortBy = val)),
                      _filterChip('RATING', 'Customer Rating', _sortBy, (val) => setModalState(() => _sortBy = val)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {}); // Trigger search results reload
                        Navigator.pop(context);
                      },
                      child: const Text('APPLY FILTERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip(String value, String label, String groupValue, Function(String) onSelect) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          onSelect(value);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<EcommCatalogProvider>();
    final cart = context.watch<EcommCartProvider>();

    // Search and filter operations locally
    var filteredProducts = catalog.products.where((p) {
      if (_query.isNotEmpty) {
        final matchesTitle = p.title.toLowerCase().contains(_query.toLowerCase());
        final matchesDesc = p.description.toLowerCase().contains(_query.toLowerCase());
        if (!matchesTitle && !matchesDesc) return false;
      }
      if (_selectedCategory != 'ALL' && p.categoryId != _selectedCategory) {
        return false;
      }
      if (_organicOnly && !p.isOrganic) {
        return false;
      }
      return true;
    }).toList();

    // Sorting operations
    if (_sortBy == 'PRICE_ASC') {
      filteredProducts.sort((a, b) => a.defaultVariant.sellingPrice.compareTo(b.defaultVariant.sellingPrice));
    } else if (_sortBy == 'PRICE_DESC') {
      filteredProducts.sort((a, b) => b.defaultVariant.sellingPrice.compareTo(a.defaultVariant.sellingPrice));
    } else if (_sortBy == 'RATING') {
      filteredProducts.sort((a, b) => b.avgRating.compareTo(a.avgRating));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) {
                          setState(() {
                            _query = val.trim();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search organic apples, fresh palak...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          prefixIcon: Icon(Icons.search, color: AppColors.primary),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _query = '';
                                    });
                                  },
                                ),
                              IconButton(
                                icon: Icon(Icons.mic, color: AppColors.primary),
                                onPressed: _triggerVoiceSearch,
                              ),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: AppColors.primary),
                    onPressed: () => _openFilterSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _isListening
              ? Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic, size: 100, color: Colors.amberAccent),
                      const SizedBox(height: 20),
                      const Text(
                        'Listening for Fresh Produce...',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try saying "Alphonso Mangoes" or "Palak"',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                      const SizedBox(height: 40),
                      CircularProgressIndicator(color: AppColors.primary),
                    ],
                  ),
                )
              : _query.isEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trending Searches ⚡',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _trendingSearches.map((item) {
                              return GestureDetector(
                                onTap: () {
                                  // Strip emojis for search
                                  final term = item.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                                  setState(() {
                                    _query = term;
                                    _searchController.text = term;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                                  ),
                                  child: Text(
                                    item,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.search, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                const Text('Search for fresh products directly from cold store hubs', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('No Match Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text('No products matched "$_query" under current filters', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(14),
                          itemCount: filteredProducts.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final variant = product.defaultVariant;

                            return ProductCardWidget(product: product, variant: variant, cart: cart);
                          },
                        ),

          // Floating Bottom Cart Bar
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
                    color: AppColors.primary,
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
                            cart.freeDeliveryProgress >= 1.0 ? 'FREE Delivery Applied' : 'Add ₹${cart.amountNeededForFreeDelivery.toStringAsFixed(0)} for FREE delivery',
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

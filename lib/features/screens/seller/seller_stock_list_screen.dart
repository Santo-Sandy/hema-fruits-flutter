import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class SellerStockListScreen extends StatefulWidget {
  const SellerStockListScreen({super.key});

  @override
  State<SellerStockListScreen> createState() => _SellerStockListScreenState();
}

class _SellerStockListScreenState extends State<SellerStockListScreen> {
  final EcommerceRepository _repository = EcommerceRepository();
  List<StoreProduct> _myProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All'; // All, In Stock, Low Stock, Out of Stock
  String _currentSellerId = '';
  String _sellerName = '';

  @override
  void initState() {
    super.initState();
    _loadSellerProducts();
  }

  Future<void> _loadSellerProducts() async {
    setState(() => _isLoading = true);
    final user = await SecureStorageService.getUserData() ?? {};
    _currentSellerId = user['_id']?.toString() ?? 'usr_seller_seed_001';
    _sellerName = user['store_name']?.toString().isNotEmpty == true
        ? user['store_name']
        : (user['name'] ?? 'Seller');

    try {
      // Fetch products filtered strictly by seller_id
      final products = await _repository.getProducts(sellerId: _currentSellerId);
      if (mounted) {
        setState(() {
          _myProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteProduct(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Stock Listing'),
        content: Text('Are you sure you want to remove "$title" from your inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _repository.deleteProduct(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed "$title"'), backgroundColor: const Color(0xFF0F9D58)),
        );
        _loadSellerProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _myProducts.where((p) {
      final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.originRegion.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      final stock = p.variants.isNotEmpty ? p.variants.first.stockQuantity : 0;
      if (_selectedStatus == 'In Stock') return stock > 10;
      if (_selectedStatus == 'Low Stock') return stock > 0 && stock <= 10;
      if (_selectedStatus == 'Out of Stock') return stock == 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F9D58),
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Produce Listings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            Text(
              'Seller Store: $_sellerName',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _loadSellerProducts,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
            tooltip: 'Sales Performance',
            onPressed: () => context.push('/seller/sales-dashboard'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/seller/add-stock');
          _loadSellerProducts();
        },
        backgroundColor: const Color(0xFF0F9D58),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search your listed stocks...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0F9D58)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'In Stock', 'Low Stock', 'Out of Stock'].map((st) {
                      final isSel = _selectedStatus == st;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(st),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedStatus = st),
                          selectedColor: const Color(0xFF0F9D58).withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSel ? const Color(0xFF0F9D58) : const Color(0xFF64748B),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: isSel ? const Color(0xFF0F9D58) : Colors.grey[300]!,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D58)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F9D58).withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF0F9D58)),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No products found in your inventory',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tap "+ Add Stock" below to publish your first produce listing.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await context.push('/seller/add-stock');
                                _loadSellerProducts();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F9D58),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Add Produce Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSellerProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final p = filtered[i];
                            final variant = p.variants.isNotEmpty ? p.variants.first : null;
                            final price = variant?.sellingPrice ?? 0.0;
                            final stock = variant?.stockQuantity ?? 0;
                            final unit = variant?.weightUnit ?? 'Kg';
                            final imgUrl = p.images.isNotEmpty ? p.images.first : '';

                            Color badgeColor = const Color(0xFF0F9D58);
                            String badgeText = 'In Stock ($stock $unit)';
                            if (stock == 0) {
                              badgeColor = const Color(0xFFD32F2F);
                              badgeText = 'Out of Stock';
                            } else if (stock <= 10) {
                              badgeColor = const Color(0xFFF57C00);
                              badgeText = 'Low Stock ($stock $unit)';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 90,
                                      height: 90,
                                      color: const Color(0xFFF1F5F9),
                                      child: imgUrl.isNotEmpty
                                          ? Image.network(
                                              AppConfig.resolveImageUrl(imgUrl),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                Icons.eco,
                                                color: Color(0xFF0F9D58),
                                                size: 36,
                                              ),
                                            )
                                          : const Icon(Icons.eco, color: Color(0xFF0F9D58), size: 36),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: badgeColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                badgeText,
                                                style: TextStyle(
                                                  color: badgeColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            if (p.isOrganic) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF0F9D58).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  '🌿 Organic',
                                                  style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold, fontSize: 10),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          p.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Grade: ${p.qualityGrade} • ${p.originRegion}',
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${price.toStringAsFixed(0)} / $unit',
                                              style: const TextStyle(
                                                color: Color(0xFF0F9D58),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                              tooltip: 'Delete Product',
                                              onPressed: () => _deleteProduct(p.id, p.title),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class AdminControlScreen extends StatefulWidget {
  const AdminControlScreen({super.key});

  @override
  State<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends State<AdminControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EcommerceRepository _repository = EcommerceRepository();

  // Data States
  Map<String, dynamic> _stats = {};
  List<StoreProduct> _products = [];
  List<Map<String, dynamic>> _users = [];
  List<StoreOrderModel> _orders = [];
  bool _isLoading = true;

  // Filter States
  String _selectedSellerFilter = 'ALL';
  String _selectedCategoryFilter = 'ALL';
  String _selectedUserRoleFilter = 'ALL';
  String _productSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllAdminData();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getAdminStats(),
        _repository.getProducts(),
        _repository.getStoreUsers(),
        _repository.getOrders(),
      ]);

      if (mounted) {
        setState(() {
          _stats = (results[0] as Map<String, dynamic>?) ?? {};
          _products = (results[1] as List<StoreProduct>?) ?? [];
          _users = (results[2] as List<Map<String, dynamic>>?) ?? [];
          _orders = (results[3] as List<StoreOrderModel>?) ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Action: Delete Product'),
        content: Text('Are you sure you want to permanently remove "$title" from the marketplace catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Product'),
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
        _loadAllAdminData();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extract distinct sellers from loaded products & users
    final Map<String, String> sellerOptions = {'ALL': 'All Sellers'};
    for (final p in _products) {
      if (p.sellerId != null && p.sellerId!.isNotEmpty) {
        sellerOptions[p.sellerId!] = p.sellerName ?? 'Seller (${p.sellerId!.substring(0, 6)})';
      }
    }
    for (final u in _users) {
      final r = (u['role'] ?? '').toString().toLowerCase();
      if (r == 'processor' || r == 'seller') {
        final id = (u['_id'] ?? '').toString();
        final name = (u['store_name'] ?? u['name'] ?? 'Seller').toString();
        if (id.isNotEmpty) sellerOptions[id] = name;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'Super Admin Control Center',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
            onPressed: _loadAllAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            tooltip: 'Add Product',
            onPressed: () async {
              await context.push('/seller/add-stock');
              _loadAllAdminData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_rounded, size: 18)),
            Tab(text: 'Products', icon: Icon(Icons.inventory_2_rounded, size: 18)),
            Tab(text: 'Users & Roles', icon: Icon(Icons.people_alt_rounded, size: 18)),
            Tab(text: 'Live Orders', icon: Icon(Icons.local_shipping_rounded, size: 18)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProductsTab(sellerOptions),
                _buildUsersTab(),
                _buildOrdersTab(),
              ],
            ),
    );
  }

  // ── 1. OVERVIEW TAB ───────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final totalProducts = _stats['total_products'] ?? _products.length;
    final totalUsers = _stats['total_users'] ?? _users.length;
    final totalSellers = _stats['total_sellers'] ?? _users.where((u) => u['role'] == 'processor' || u['role'] == 'seller').length;
    final totalBuyers = _stats['total_buyers'] ?? _users.where((u) => u['role'] == 'buyer').length;
    final totalOrders = _stats['total_orders'] ?? _orders.length;
    final totalRevenue = (_stats['total_revenue'] as num?)?.toDouble() ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadAllAdminData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Grid
            Row(
              children: [
                Expanded(
                  child: _KPICard(
                    title: 'TOTAL PRODUCTS',
                    value: '$totalProducts',
                    icon: Icons.inventory_2_rounded,
                    color: const Color(0xFF0F9D58),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KPICard(
                    title: 'STORE REVENUE',
                    value: '₹${totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.monetization_on_rounded,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KPICard(
                    title: 'REGISTERED SELLERS',
                    value: '$totalSellers',
                    icon: Icons.storefront_rounded,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KPICard(
                    title: 'RETAIL BUYERS',
                    value: '$totalBuyers',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Operations Row
            const Text(
              'Quick Admin Operations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/seller/add-stock');
                      _loadAllAdminData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D58),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: const Text('Create New Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.manage_accounts_rounded, color: Colors.white),
                    label: const Text('Manage User Roles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Registered Accounts Preview
            const Text(
              'Recent User Registrations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            ..._users.take(5).map((u) {
              final role = (u['role'] ?? 'buyer').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: role == 'admin'
                          ? const Color(0xFF7C3AED)
                          : role == 'processor' || role == 'seller'
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF0F9D58),
                      child: Text(
                        (u['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u['name'] ?? 'User',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            u['email'] ?? '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _RoleBadge(role: role),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── 2. PRODUCTS TAB WITH SELLER & CATEGORY FILTERS ─────────────────────────

  Widget _buildProductsTab(Map<String, String> sellerOptions) {
    final filtered = _products.where((p) {
      if (_selectedSellerFilter != 'ALL' && p.sellerId != _selectedSellerFilter) {
        return false;
      }
      if (_selectedCategoryFilter != 'ALL' && p.categoryId != _selectedCategoryFilter) {
        return false;
      }
      if (_productSearchQuery.isNotEmpty) {
        final q = _productSearchQuery.toLowerCase();
        return p.title.toLowerCase().contains(q) ||
            p.originRegion.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Controls Bar
        Container(
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Column(
            children: [
              // Search Input
              TextField(
                onChanged: (v) => setState(() => _productSearchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search catalog by product name or origin...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Seller Dropdown Filter
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSellerFilter,
                          isExpanded: true,
                          items: sellerOptions.entries.map((e) {
                            return DropdownMenuItem(
                              value: e.key,
                              child: Text(
                                'Seller: ${e.value}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedSellerFilter = v ?? 'ALL'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category Dropdown Filter
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryFilter,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('All Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            DropdownMenuItem(value: 'cat_fruits', child: Text('Fresh Fruits', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            DropdownMenuItem(value: 'cat_veggies', child: Text('Vegetables', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                            DropdownMenuItem(value: 'cat_dry_nuts', child: Text('Dry Nuts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                          ],
                          onChanged: (v) => setState(() => _selectedCategoryFilter = v ?? 'ALL'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Product Count Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filtered.length} of ${_products.length} Products',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
              ),
              if (_selectedSellerFilter != 'ALL' || _selectedCategoryFilter != 'ALL')
                TextButton(
                  onPressed: () => setState(() {
                    _selectedSellerFilter = 'ALL';
                    _selectedCategoryFilter = 'ALL';
                    _productSearchQuery = '';
                  }),
                  child: const Text('Reset Filters', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED))),
                ),
            ],
          ),
        ),

        // Products List
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No products match current filters', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final p = filtered[i];
                    final v = p.variants.isNotEmpty ? p.variants.first : null;
                    final price = v?.sellingPrice ?? 0.0;
                    final stock = v?.stockQuantity ?? 0;
                    final unit = v?.weightUnit ?? 'Kg';
                    final img = p.images.isNotEmpty ? p.images.first : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 60,
                              height: 60,
                              color: const Color(0xFFF1F5F9),
                              child: img.isNotEmpty
                                  ? Image.network(
                                      AppConfig.resolveImageUrl(img),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF0F9D58)),
                                    )
                                  : const Icon(Icons.eco, color: Color(0xFF0F9D58)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Seller: ${p.sellerName ?? p.sellerId ?? 'Direct Store'}',
                                  style: const TextStyle(color: Color(0xFF1565C0), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${price.toStringAsFixed(0)} / $unit  •  Stock: $stock $unit  •  ${p.originRegion}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                            tooltip: 'Delete Product',
                            onPressed: () => _deleteProduct(p.id, p.title),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── 3. USERS TAB ──────────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    final filtered = _users.where((u) {
      if (_selectedUserRoleFilter == 'ALL') return true;
      final role = (u['role'] ?? '').toString().toLowerCase();
      if (_selectedUserRoleFilter == 'SELLER') return role == 'processor' || role == 'seller';
      if (_selectedUserRoleFilter == 'BUYER') return role == 'buyer';
      if (_selectedUserRoleFilter == 'ADMIN') return role == 'admin';
      return true;
    }).toList();

    return Column(
      children: [
        // Role Filter Pills
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: ['ALL', 'BUYER', 'SELLER', 'ADMIN'].map((r) {
              final isSel = _selectedUserRoleFilter == r;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(r == 'ALL' ? 'All Roles' : r),
                  selected: isSel,
                  onSelected: (_) => setState(() => _selectedUserRoleFilter = r),
                  selectedColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Users List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final u = filtered[i];
              final role = (u['role'] ?? 'buyer').toString();
              final storeName = u['store_name']?.toString() ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: role == 'admin'
                          ? const Color(0xFF7C3AED)
                          : role == 'processor' || role == 'seller'
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF0F9D58),
                      child: Text(
                        (u['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u['name'] ?? 'User Name',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (storeName.isNotEmpty)
                            Text(
                              'Store: $storeName',
                              style: const TextStyle(color: Color(0xFF1565C0), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          Text(
                            '${u['email'] ?? ''} • ${u['mobile_number'] ?? u['phone'] ?? 'No phone'}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    _RoleBadge(role: role),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 4. ORDERS TAB ─────────────────────────────────────────────────────────

  Widget _buildOrdersTab() {
    return _orders.isEmpty
        ? const Center(child: Text('No orders recorded in store database', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _orders.length,
            itemBuilder: (context, i) {
              final o = _orders[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${o.id.length > 8 ? o.id.substring(0, 8) : o.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F9D58).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            o.orderStatus.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${o.items.length} items  •  Grand Total: ₹${o.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payment: ${o.paymentMethod}  •  User: ${o.userId}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              );
            },
          );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
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

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF0F9D58);
    String label = 'Buyer';

    final r = role.toLowerCase();
    if (r == 'admin') {
      bg = const Color(0xFF7C3AED);
      label = 'Super Admin';
    } else if (r == 'processor' || r == 'seller') {
      bg = const Color(0xFF1565C0);
      label = 'Producer Seller';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}

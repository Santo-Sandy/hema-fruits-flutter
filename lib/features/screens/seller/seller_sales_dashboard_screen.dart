import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class SellerSalesDashboardScreen extends StatefulWidget {
  const SellerSalesDashboardScreen({super.key});

  @override
  State<SellerSalesDashboardScreen> createState() => _SellerSalesDashboardScreenState();
}

class _SellerSalesDashboardScreenState extends State<SellerSalesDashboardScreen> {
  final EcommerceRepository _repository = EcommerceRepository();
  List<StoreProduct> _sellerProducts = [];
  bool _isLoading = true;
  String _sellerName = 'Seller Hub';
  String _sellerId = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final user = await SecureStorageService.getUserData() ?? {};
    _sellerId = user['_id']?.toString() ?? 'usr_seller_seed_001';
    _sellerName = user['store_name']?.toString().isNotEmpty == true
        ? user['store_name']
        : (user['name'] ?? 'Seller Partner');

    try {
      final products = await _repository.getProducts(sellerId: _sellerId);
      if (mounted) {
        setState(() {
          _sellerProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalStock = 0;
    double estimatedValue = 0;
    int lowStockCount = 0;

    for (final p in _sellerProducts) {
      for (final v in p.variants) {
        totalStock += v.stockQuantity;
        estimatedValue += v.stockQuantity * v.sellingPrice;
        if (v.stockQuantity <= 10 && v.stockQuantity > 0) {
          lowStockCount++;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seller Business Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            Text(
              '$_sellerName • Inventory Performance',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Colors.white),
            tooltip: 'Add Produce Stock',
            onPressed: () async {
              await context.push('/seller/add-stock');
              _loadDashboardData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview KPI Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ESTIMATED INVENTORY VALUE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${estimatedValue.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MetricSubItem(
                                  label: 'Listed Products',
                                  value: '${_sellerProducts.length}',
                                  icon: Icons.inventory_2_outlined,
                                ),
                              ),
                              Expanded(
                                child: _MetricSubItem(
                                  label: 'Total Available Units',
                                  value: '$totalStock units',
                                  icon: Icons.pie_chart_outline_rounded,
                                ),
                              ),
                              Expanded(
                                child: _MetricSubItem(
                                  label: 'Low Stock Alerts',
                                  value: '$lowStockCount',
                                  icon: Icons.warning_amber_rounded,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Add Produce Stock',
                            icon: Icons.add_circle_outline,
                            color: const Color(0xFF0F9D58),
                            onTap: () async {
                              await context.push('/seller/add-stock');
                              _loadDashboardData();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            label: 'View My Inventory',
                            icon: Icons.list_alt_rounded,
                            color: const Color(0xFF1565C0),
                            onTap: () => context.push('/seller/stocks'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section Heading: My Live Products
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Live Listed Products',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/seller/stocks'),
                          child: const Text('See All', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_sellerProducts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 44, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              'No active products found for your store',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Click "Add Produce Stock" to list your first agricultural harvest.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ..._sellerProducts.map((prod) {
                        final v = prod.variants.isNotEmpty ? prod.variants.first : null;
                        final price = v?.sellingPrice ?? 0.0;
                        final stock = v?.stockQuantity ?? 0;
                        final unit = v?.weightUnit ?? 'Kg';
                        final img = prod.images.isNotEmpty ? prod.images.first : '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 65,
                                  height: 65,
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
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Grade: ${prod.qualityGrade} • ${prod.originRegion}',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${price.toStringAsFixed(0)} / $unit  •  Stock: $stock $unit',
                                      style: const TextStyle(
                                        color: Color(0xFF1565C0),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _MetricSubItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricSubItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class SellerSalesDashboardScreen extends StatefulWidget {
  const SellerSalesDashboardScreen({super.key});

  @override
  State<SellerSalesDashboardScreen> createState() => _SellerSalesDashboardScreenState();
}

class _SellerSalesDashboardScreenState extends State<SellerSalesDashboardScreen> {
  // Product Selling Stocks Data Breakdown
  final List<Map<String, dynamic>> _productStockSales = [
    {
      "productName": "Organic Alphonso Mangoes",
      "category": "Fruits",
      "pricePerUnit": 180,
      "unit": "Kg",
      "initialStock": 1000,
      "stockRemaining": 450,
      "unitsSold": 550,
      "revenueEarned": 99000,
      "salesRate": 0.55,
      "image": "https://images.unsplash.com/photo-1553279768-865429fa0078?w=300",
    },
    {
      "productName": "Raw Cashew Nuts (W240)",
      "category": "RCN / Cashew",
      "pricePerUnit": 720,
      "unit": "Kg",
      "initialStock": 2000,
      "stockRemaining": 1200,
      "unitsSold": 800,
      "revenueEarned": 576000,
      "salesRate": 0.40,
      "image": "https://images.unsplash.com/photo-1599599810694-b5b37304c041?w=300",
    },
    {
      "productName": "Export Grade Bananas",
      "category": "Fruits",
      "pricePerUnit": 45,
      "unit": "Kg",
      "initialStock": 1500,
      "stockRemaining": 0,
      "unitsSold": 1500,
      "revenueEarned": 67500,
      "salesRate": 1.00,
      "image": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=300",
    },
    {
      "productName": "Fresh Shimla Apples",
      "category": "Fruits",
      "pricePerUnit": 160,
      "unit": "Kg",
      "initialStock": 500,
      "stockRemaining": 25,
      "unitsSold": 475,
      "revenueEarned": 76000,
      "salesRate": 0.95,
      "image": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=300",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _productStockSales.fold<double>(
        0, (sum, item) => sum + (item['revenueEarned'] as num).toDouble());
    final totalUnitsSold = _productStockSales.fold<int>(
        0, (sum, item) => sum + (item['unitsSold'] as int));
    final totalStockRemaining = _productStockSales.fold<int>(
        0, (sum, item) => sum + (item['stockRemaining'] as int));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 2,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seller Sales Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('Selling Stock Breakdown Per Product', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Colors.white),
            tooltip: 'Add Stock',
            onPressed: () => context.push('/seller/add-stock'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview KPI Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL SALES REVENUE',
                              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                          SizedBox(height: 4),
                          Text('₹8,18,500',
                              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderKpi('UNITS SOLD', '$totalUnitsSold Kg', Icons.shopping_bag_outlined),
                      _buildHeaderKpi('LIVE STOCK', '$totalStockRemaining Kg', Icons.inventory_outlined),
                      _buildHeaderKpi('PRODUCTS', '${_productStockSales.length} Items', Icons.grid_view_outlined),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selling Stocks Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/seller/stocks'),
                  icon: const Icon(Icons.inventory, size: 16, color: Color(0xFF1565C0)),
                  label: const Text('Manage Stocks', style: TextStyle(color: Color(0xFF1565C0), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Product Cards List
            ..._productStockSales.map((product) {
              final double salesRate = product['salesRate'] as double;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product['image'],
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[200],
                                child: const Icon(Icons.eco, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['productName'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Category: ${product['category']} • ₹${product['pricePerUnit']} / ${product['unit']}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: salesRate >= 0.8
                                  ? Colors.green[100]
                                  : salesRate >= 0.4
                                      ? Colors.blue[100]
                                      : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              salesRate >= 1.0
                                  ? 'SOLD OUT'
                                  : '${(salesRate * 100).toInt()}% Sold',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: salesRate >= 0.8
                                    ? Colors.green[800]
                                    : salesRate >= 0.4
                                        ? Colors.blue[800]
                                        : Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Sales Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: salesRate,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            salesRate >= 0.8
                                ? Colors.green
                                : salesRate >= 0.4
                                    ? Colors.blue
                                    : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stock Metrics Details Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailCol('Stock Remaining', '${product['stockRemaining']} ${product['unit']}'),
                          _buildDetailCol('Units Sold', '${product['unitsSold']} ${product['unit']}'),
                          _buildDetailCol('Revenue', '₹${product['revenueEarned']}', isBold: true),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderKpi(String title, String val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDetailCol(String title, String val, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? const Color(0xFF1565C0) : Colors.grey[900],
          ),
        ),
      ],
    );
  }
}

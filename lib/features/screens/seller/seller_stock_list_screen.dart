import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class SellerStockListScreen extends StatefulWidget {
  const SellerStockListScreen({super.key});

  @override
  State<SellerStockListScreen> createState() => _SellerStockListScreenState();
}

class _SellerStockListScreenState extends State<SellerStockListScreen> {
  final List<Map<String, dynamic>> _myStocks = [
    {
      "id": "stk_01",
      "name": "Organic Alphonso Mangoes",
      "category": "Fruits",
      "quantity": 450,
      "unit": "Kg",
      "price": 180,
      "status": "In Stock",
      "grade": "Grade A",
      "location": "Ratnagiri, MH",
      "image": "https://images.unsplash.com/photo-1553279768-865429fa0078?w=300",
    },
    {
      "id": "stk_02",
      "name": "Raw Cashew Nuts (W240 Grade)",
      "category": "RCN / Cashew",
      "quantity": 1200,
      "unit": "Kg",
      "price": 720,
      "status": "In Stock",
      "grade": "Export Grade",
      "location": "Kollam, KL",
      "image": "https://images.unsplash.com/photo-1599599810694-b5b37304c041?w=300",
    },
    {
      "id": "stk_03",
      "name": "Fresh Shimla Apples",
      "category": "Fruits",
      "quantity": 25,
      "unit": "Kg",
      "price": 160,
      "status": "Low Stock",
      "grade": "Premium",
      "location": "Shimla, HP",
      "image": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=300",
    },
    {
      "id": "stk_04",
      "name": "Green Cavendish Bananas",
      "category": "Fruits",
      "quantity": 0,
      "unit": "Kg",
      "price": 45,
      "status": "Out of Stock",
      "grade": "Standard",
      "location": "Theni, TN",
      "image": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=300",
    },
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredStocks = _myStocks.where((s) {
      final q = _searchQuery.toLowerCase();
      return s['name'].toString().toLowerCase().contains(q) ||
          s['category'].toString().toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F9D58),
        elevation: 2,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Stock Listings',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            Text(
              'Manage your agricultural inventory',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
            tooltip: 'Sales Dashboard',
            onPressed: () => context.push('/seller/sales-dashboard'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Metrics Header Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search my stocks...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF0F9D58)),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuickMetricCard(
                        'Total Items', '${_myStocks.length}', Icons.inventory_2_outlined, Colors.blue),
                    const SizedBox(width: 8),
                    _buildQuickMetricCard(
                        'Live Stock',
                        '${_myStocks.where((s) => s['quantity'] > 0).length}',
                        Icons.check_circle_outline,
                        Colors.green),
                    const SizedBox(width: 8),
                    _buildQuickMetricCard(
                        'Out of Stock',
                        '${_myStocks.where((s) => s['quantity'] == 0).length}',
                        Icons.warning_amber_rounded,
                        Colors.red),
                  ],
                ),
              ],
            ),
          ),

          // Stock List
          Expanded(
            child: filteredStocks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No stock listings found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredStocks.length,
                    itemBuilder: (ctx, i) {
                      final item = filteredStocks[i];
                      final isOutOfStock = item['quantity'] <= 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item['image'],
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 76,
                                    height: 76,
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['name'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F9D58).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item['grade'],
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F9D58)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item['category']} • ${item['location']}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '₹${item['price']} / ${item['unit']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                            color: Color(0xFF0F9D58),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOutOfStock
                                                ? Colors.red[100]
                                                : item['quantity'] < 50
                                                    ? Colors.orange[100]
                                                    : Colors.green[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isOutOfStock
                                                ? 'Out of Stock'
                                                : '${item['quantity']} ${item['unit']} Available',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock
                                                  ? Colors.red[800]
                                                  : item['quantity'] < 50
                                                      ? Colors.orange[800]
                                                      : Colors.green[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (val) {
                                  if (val == 'edit_qty') {
                                    _showEditQuantityDialog(item);
                                  } else if (val == 'delete') {
                                    setState(() {
                                      _myStocks.removeWhere((s) => s['id'] == item['id']);
                                    });
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit_qty',
                                    child: Text('Update Quantity'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Listing', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/seller/add-stock'),
        backgroundColor: const Color(0xFF0F9D58),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Produce Stock', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickMetricCard(String label, String val, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: color[700], size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color[900])),
                Text(label, style: TextStyle(fontSize: 9, color: color[800])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditQuantityDialog(Map<String, dynamic> item) {
    final controller = TextEditingController(text: item['quantity'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Stock: ${item['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Available Quantity (${item['unit']})',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58)),
            onPressed: () {
              final newQty = int.tryParse(controller.text) ?? item['quantity'];
              setState(() {
                item['quantity'] = newQty;
                item['status'] = newQty > 50
                    ? 'In Stock'
                    : newQty > 0
                        ? 'Low Stock'
                        : 'Out of Stock';
              });
              Navigator.pop(ctx);
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

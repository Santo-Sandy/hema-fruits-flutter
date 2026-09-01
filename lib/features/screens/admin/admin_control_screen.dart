import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class AdminControlScreen extends StatefulWidget {
  const AdminControlScreen({super.key});

  @override
  State<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends State<AdminControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock / Initial Admin Data State
  final List<Map<String, dynamic>> _products = [
    {
      "id": "p1",
      "name": "Fresh Organic Alphonso Mangoes",
      "category": "Fruits",
      "price": 180,
      "unit": "Kg",
      "stock": 450,
      "status": "In Stock",
      "seller": "Green Valley Farms",
      "image": "https://images.unsplash.com/photo-1553279768-865429fa0078?w=300",
    },
    {
      "id": "p2",
      "name": "Premium Raw Cashew Nuts (W240)",
      "category": "RCN / Cashew",
      "price": 720,
      "unit": "Kg",
      "stock": 1200,
      "status": "In Stock",
      "seller": "Hema Cashew Traders",
      "image": "https://images.unsplash.com/photo-1599599810694-b5b37304c041?w=300",
    },
    {
      "id": "p3",
      "name": "Export Grade Cavendish Bananas",
      "category": "Fruits",
      "price": 45,
      "unit": "Kg",
      "stock": 0,
      "status": "Out of Stock",
      "seller": "Sunrise Orchards",
      "image": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=300",
    },
    {
      "id": "p4",
      "name": "Fresh Shimla Apples (Grade A)",
      "category": "Fruits",
      "price": 160,
      "unit": "Kg",
      "stock": 80,
      "status": "Low Stock",
      "seller": "Himalayan Fresh",
      "image": "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=300",
    },
  ];

  final List<Map<String, dynamic>> _users = [
    {
      "id": "u1",
      "name": "Rajesh Kumar",
      "email": "rajesh@farms.com",
      "role": "processor",
      "status": "Active",
      "phone": "+91 9876543210",
      "joined": "2025-01-15",
    },
    {
      "id": "u2",
      "name": "Anita Sharma",
      "email": "anita@buyer.com",
      "role": "buyer",
      "status": "Active",
      "phone": "+91 9123456789",
      "joined": "2025-02-10",
    },
    {
      "id": "u3",
      "name": "Global Traders Co.",
      "email": "info@globaltraders.com",
      "role": "processor",
      "status": "Deactive",
      "phone": "+91 9988776655",
      "joined": "2024-11-20",
    },
    {
      "id": "u4",
      "name": "Super Admin User",
      "email": "admin@fruits.com",
      "role": "admin",
      "status": "Active",
      "phone": "+91 9000000000",
      "joined": "2024-01-01",
    },
  ];

  final List<Map<String, dynamic>> _orders = [
    {
      "id": "ORD-9901",
      "customer": "Anita Sharma",
      "items": "Alphonso Mangoes (25 Kg)",
      "total": 4500,
      "status": "Processing",
      "date": "2026-08-30",
    },
    {
      "id": "ORD-9884",
      "customer": "Fresh Market Retailers",
      "items": "Raw Cashew Nuts (100 Kg)",
      "total": 72000,
      "status": "Shipped",
      "date": "2026-08-28",
    },
    {
      "id": "ORD-9750",
      "customer": "Green Grocery Hub",
      "items": "Shimla Apples (50 Kg)",
      "total": 8000,
      "status": "Delivered",
      "date": "2026-08-25",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        elevation: 2,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Control Hub',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text(
                  'Platform Oversight & Management',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Products'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildUsersTab(),
          _buildOrdersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: const Color(0xFF4A148C),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── 1. PRODUCTS & INVENTORY CONTROL TAB ────────────────────────────────────

  Widget _buildProductsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Metrics Bar
        Row(
          children: [
            _buildStatCard('Total Catalog', '${_products.length}', Icons.grid_view_rounded, Colors.purple),
            const SizedBox(width: 10),
            _buildStatCard(
              'In Stock',
              '${_products.where((p) => p['status'] == 'In Stock').length}',
              Icons.check_circle_outline,
              Colors.green,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              'Out of Stock',
              '${_products.where((p) => p['status'] == 'Out of Stock').length}',
              Icons.warning_amber_rounded,
              Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Platform Product Inventory',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            Text(
              '${_products.length} Items',
              style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ..._products.map((product) => Card(
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
                        product['image'],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Seller: ${product['seller']} • Category: ${product['category']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '₹${product['price']} / ${product['unit']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF4A148C)),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: product['status'] == 'In Stock'
                                      ? Colors.green[100]
                                      : product['status'] == 'Low Stock'
                                          ? Colors.orange[100]
                                          : Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${product['status']} (${product['stock']} ${product['unit']})',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: product['status'] == 'In Stock'
                                        ? Colors.green[800]
                                        : product['status'] == 'Low Stock'
                                            ? Colors.orange[800]
                                            : Colors.red[800],
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
                        if (val == 'toggle_stock') {
                          setState(() {
                            product['status'] =
                                product['status'] == 'In Stock' ? 'Out of Stock' : 'In Stock';
                          });
                        } else if (val == 'delete') {
                          setState(() {
                            _products.removeWhere((p) => p['id'] == product['id']);
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle_stock',
                          child: Text(product['status'] == 'In Stock'
                              ? 'Mark Out of Stock'
                              : 'Mark In Stock'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Product', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  // ── 2. USER & ACCESS CONTROL TAB ──────────────────────────────────────────

  Widget _buildUsersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Registered Accounts & Roles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4A148C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_users.length} Users',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ..._users.map((user) {
          final isBlocked = user['status'] == 'Deactive';
          final roleColor = user['role'] == 'admin'
              ? Colors.purple
              : user['role'] == 'processor'
                  ? Colors.blue
                  : Colors.green;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Icon(
                  user['role'] == 'admin'
                      ? Icons.admin_panel_settings
                      : user['role'] == 'processor'
                          ? Icons.storefront
                          : Icons.person,
                  color: roleColor,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    user['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user['role'].toString().toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor),
                    ),
                  ),
                ],
              ),
              subtitle: Text('${user['email']} • ${user['phone']}'),
              trailing: Switch(
                value: !isBlocked,
                activeColor: Colors.green,
                onChanged: (val) {
                  setState(() {
                    user['status'] = val ? 'Active' : 'Deactive';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${user['name']} status updated to ${user['status']}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── 3. PLATFORM ORDERS OVERVIEW TAB ───────────────────────────────────────

  Widget _buildOrdersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _buildStatCard('Total Revenue', '₹84,500', Icons.payments_outlined, Colors.green),
            const SizedBox(width: 10),
            _buildStatCard('Active Orders', '${_orders.length}', Icons.local_shipping_outlined, Colors.blue),
          ],
        ),
        const SizedBox(height: 20),

        const Text(
          'Platform Orders Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
        ),
        const SizedBox(height: 12),

        ..._orders.map((order) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order['id'],
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF4A148C)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: order['status'] == 'Delivered'
                                ? Colors.green[100]
                                : order['status'] == 'Shipped'
                                    ? Colors.blue[100]
                                    : Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order['status'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: order['status'] == 'Delivered'
                                  ? Colors.green[800]
                                  : order['status'] == 'Shipped'
                                      ? Colors.blue[800]
                                      : Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Customer: ${order['customer']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Items: ${order['items']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${order['date']}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        Text(
                          'Total: ₹${order['total']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color[700], size: 22),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color[900])),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add New Catalog Product', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (₹)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Initial Stock (Kg/Units)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A148C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                setState(() {
                  _products.insert(0, {
                    "id": "p_${DateTime.now().millisecondsSinceEpoch}",
                    "name": nameController.text.trim(),
                    "category": "Fresh Produce",
                    "price": int.tryParse(priceController.text) ?? 100,
                    "unit": "Kg",
                    "stock": int.tryParse(stockController.text) ?? 50,
                    "status": "In Stock",
                    "seller": "Admin Direct Catalog",
                    "image": "https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=300",
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product added to platform catalog!'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('Add Product', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

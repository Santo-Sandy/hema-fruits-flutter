import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final EcommerceRepository _repository = EcommerceRepository();
  List<StoreOrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final list = await _repository.getOrders();
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Fresh Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/ecommerce/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D58)))
          : _orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('No Orders Placed Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('You haven\'t ordered any fresh fruits or vegetables yet. Start exploring our catalog!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D58),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => context.go('/ecommerce/home'),
                          child: const Text('Browse Fresh Catalog', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  Widget _buildOrderCard(StoreOrderModel order) {
    Color statusColor;
    Color statusBgColor;
    String statusText = order.orderStatus;

    switch (order.orderStatus) {
      case 'PLACED':
        statusColor = const Color(0xFFE65100);
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = 'Placed';
        break;
      case 'PACKED':
        statusColor = const Color(0xFF3E2723);
        statusBgColor = const Color(0xFFD7CCC8);
        statusText = 'Packed';
        break;
      case 'OUT_FOR_DELIVERY':
        statusColor = const Color(0xFF0D47A1);
        statusBgColor = const Color(0xFFE3F2FD);
        statusText = 'Out for Delivery';
        break;
      case 'DELIVERED':
        statusColor = const Color(0xFF1B5E20);
        statusBgColor = const Color(0xFFE8F5E9);
        statusText = 'Delivered';
        break;
      default:
        statusColor = Colors.grey[800]!;
        statusBgColor = Colors.grey[200]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Express Delivery Order',
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Order Items Preview
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: Color(0xFF0F9D58)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.productTitle}',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                          Text(
                            '₹${item.totalPrice.toInt()}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                        ],
                      ),
                    )),
                if (order.items.isEmpty)
                  const Text('Fresh Fruits Package', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Total Price & Actions
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Paid', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${order.grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D58),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => context.push('/ecommerce/order-tracking/${order.id}'),
                  icon: const Icon(Icons.location_searching, color: Colors.white, size: 14),
                  label: const Text('Track Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

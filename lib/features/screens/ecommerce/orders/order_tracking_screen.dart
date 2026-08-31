import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final EcommerceRepository _repository = EcommerceRepository();
  StoreOrderModel? _order;
  bool _isLoading = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      StoreOrderModel? res;
      if (widget.orderId == 'latest') {
        final list = await _repository.getOrders();
        if (list.isNotEmpty) {
          res = list.first;
        }
      } else {
        res = await _repository.getOrderById(widget.orderId);
      }

      if (res == null) {
        // Fallback local mockup for demo/safety
        res = StoreOrderModel(
          id: widget.orderId,
          orderNumber: 'HEMA-FRESH-9921',
          items: [],
          orderStatus: 'PLACED',
          paymentMethod: 'UPI',
          grandTotal: 480,
          deliveryOtp: '7194',
          deliveryAgentName: 'Ramesh (Express Delivery)',
          deliveryAgentPhone: '+91 98123 45678',
        );
      }

      setState(() {
        _order = res;
        _isLoading = false;
        _notFound = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _notFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Order Status & Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/ecommerce/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D58)))
          : _notFound
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Order not found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('The order may have been removed or the ID is invalid.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: () => context.go('/ecommerce/home'), child: const Text('Go Home')),
                    ],
                  ),
                )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Confirmation Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.amberAccent, size: 28),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Order Placed Successfully!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Order ID: ${_order?.orderNumber ?? widget.orderId}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.key, color: Colors.amberAccent, size: 20),
                              const SizedBox(width: 8),
                              const Text('Delivery OTP: ', style: TextStyle(color: Colors.white, fontSize: 13)),
                              Text(
                                _order?.deliveryOtp ?? '7194',
                                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2),
                              ),
                              const Spacer(),
                              const Text('Share with delivery agent', style: TextStyle(color: Colors.white60, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Visual Map View Card
                  _buildMockMapCard(context),

                  const SizedBox(height: 16),

                  // Live Visual Timeline Tracker
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Live Delivery Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 16),
                        _buildTimelineStep(
                          title: 'Order Confirmed',
                          subtitle: 'Your fresh produce list is registered',
                          isDone: _isStepDone('PLACED'),
                          isCurrent: _order?.orderStatus == 'PLACED',
                        ),
                        _buildTimelineStep(
                          title: 'Freshness Checked & Packed 🥦',
                          subtitle: 'Handpicked from cold-chain center',
                          isDone: _isStepDone('PACKED'),
                          isCurrent: _order?.orderStatus == 'PACKED',
                        ),
                        _buildTimelineStep(
                          title: 'Out for Express Delivery 🚚',
                          subtitle: 'Your order is on the way',
                          isDone: _isStepDone('OUT_FOR_DELIVERY'),
                          isCurrent: _order?.orderStatus == 'OUT_FOR_DELIVERY',
                        ),
                        _buildTimelineStep(
                          title: 'Delivered to Doorstep 📦',
                          subtitle: 'Verified via OTP',
                          isDone: _isStepDone('DELIVERED'),
                          isCurrent: _order?.orderStatus == 'DELIVERED',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delivery Agent Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE8F5E9),
                          child: Icon(Icons.person, color: Color(0xFF0F9D58)),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_order?.deliveryAgentName ?? 'Ramesh (Express Delivery)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const Text('Fresh Delivery Executive', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D58),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          onPressed: () {},
                          icon: const Icon(Icons.call, color: Colors.white, size: 14),
                          label: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 24-Hour Return Guarantee Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text('24-Hour Perishable Guarantee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'If any fruits or veggies arrive spoiled or damaged, submit a photo proof within 24 hours for instant refund.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.amber),
                          ),
                          onPressed: () => _openReturnModal(context),
                          child: const Text('REPORT DAMAGED ITEM', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  /// Returns true if the order has progressed past the given status step.
  bool _isStepDone(String step) {
    const order = ['PLACED', 'PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED'];
    final currentIdx = order.indexOf(_order?.orderStatus ?? '');
    final stepIdx = order.indexOf(step);
    if (currentIdx < 0 || stepIdx < 0) return false;
    return currentIdx > stepIdx;
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? const Color(0xFF0F9D58)
                    : isCurrent
                        ? Colors.amber
                        : Colors.grey[300],
              ),
              child: Icon(
                isDone ? Icons.check : (isCurrent ? Icons.directions_bike : Icons.circle),
                color: Colors.white,
                size: 14,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 38,
                color: isDone ? const Color(0xFF0F9D58) : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color: isCurrent ? const Color(0xFF1B5E20) : Colors.black87,
                ),
              ),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }

  void _openReturnModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submit Damaged Item Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Select reason for return:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: const Text('Spoiled/Rotten'), backgroundColor: Colors.red[50]),
                  Chip(label: const Text('Damaged Packaging'), backgroundColor: Colors.orange[50]),
                  Chip(label: const Text('Wrong Weight'), backgroundColor: Colors.grey[100]),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Return request submitted! Our team is reviewing photo proof.'),
                      backgroundColor: Color(0xFF1B5E20),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text('UPLOAD PHOTO & SUBMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildMockMapCard(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Mock map background image (representing HSR layout Bengaluru roads)
            CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, err) => Container(color: Colors.grey[300]),
            ),
            // Semi-transparent overlay to style the map beautifully
            Container(color: Colors.white.withValues(alpha: 0.1)),
            // Visual simulated route markers
            Positioned(
              top: 50,
              left: 80,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                child: const Icon(Icons.store, color: Colors.white, size: 16),
              ),
            ),
            Positioned(
              bottom: 40,
              right: 90,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.home, color: Colors.white, size: 16),
              ),
            ),
            Positioned(
              top: 80,
              left: 140,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.directions_bike, color: Colors.white, size: 16),
              ),
            ),
            // Delivery executive badge
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bike, color: Colors.amberAccent, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Ramesh is 1.4 km away',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

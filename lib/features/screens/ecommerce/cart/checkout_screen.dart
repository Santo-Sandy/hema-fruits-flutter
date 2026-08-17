import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final EcommerceRepository _repository = EcommerceRepository();

  String _selectedSlot = 'EXPRESS';
  String _selectedPaymentMethod = 'UPI';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<EcommCartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Checkout & Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0F9D58)),
                  SizedBox(height: 16),
                  Text('Securing Farm Fresh Slot & Processing Order...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF0F9D58)),
                            const SizedBox(width: 8),
                            const Text('Delivering To:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: const Text('CHANGE', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Santo Kumar • 98765 43210', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        const Text('Flat 402, Green Avenue, 12th Main Road, HSR Layout Sector 1, Bengaluru, Karnataka - 560102', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('⚡ Serviceable for 2-Hour Express Delivery', style: TextStyle(fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Delivery Slot Selector Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Delivery Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 10),
                        RadioListTile<String>(
                          value: 'EXPRESS',
                          groupValue: _selectedSlot,
                          activeColor: const Color(0xFF0F9D58),
                          title: const Text('Express Delivery (Within 2 Hours)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Direct from Cold Storage Hub', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          onChanged: (val) => setState(() => _selectedSlot = val!),
                        ),
                        RadioListTile<String>(
                          value: 'SLOT_MORNING',
                          groupValue: _selectedSlot,
                          activeColor: const Color(0xFF0F9D58),
                          title: const Text('Tomorrow Morning (7:00 AM - 10:00 AM)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Fresh morning harvest batch', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          onChanged: (val) => setState(() => _selectedSlot = val!),
                        ),
                        RadioListTile<String>(
                          value: 'SLOT_EVENING',
                          groupValue: _selectedSlot,
                          activeColor: const Color(0xFF0F9D58),
                          title: const Text('Tomorrow Evening (5:00 PM - 8:00 PM)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Standard delivery slot', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          onChanged: (val) => setState(() => _selectedSlot = val!),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Payment Options
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Payment Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 10),
                        RadioListTile<String>(
                          value: 'UPI',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(0xFF0F9D58),
                          title: const Text('UPI (PhonePe, Google Pay, Paytm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          secondary: const Icon(Icons.qr_code, color: Colors.purple),
                          onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                        ),
                        RadioListTile<String>(
                          value: 'CARD',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(0xFF0F9D58),
                          title: const Text('Credit / Debit Cards', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          secondary: const Icon(Icons.credit_card, color: Colors.blue),
                          onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                        ),
                        RadioListTile<String>(
                          value: 'COD',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(0xFF0F9D58),
                          title: const Text('Cash on Delivery (COD)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          secondary: const Icon(Icons.payments, color: Colors.green),
                          onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Order Items Summary List
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Order Items (${cart.totalCount})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('₹${cart.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...cart.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity}x ${item.productTitle}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              Text('₹${item.totalPrice.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₹${cart.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                const Text('TOTAL PAYABLE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      setState(() => _isSubmitting = true);
                      final order = await _repository.placeOrder(
                        paymentMethod: _selectedPaymentMethod,
                        slotId: _selectedSlot,
                        addressLine: 'Flat 402, HSR Layout, Bengaluru',
                      );
                      setState(() => _isSubmitting = false);

                      if (order != null) {
                        cart.clearCart();
                        if (mounted) {
                          context.go('/ecommerce/order-tracking/${order.id}');
                        }
                      }
                    },
              child: const Text('PLACE ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

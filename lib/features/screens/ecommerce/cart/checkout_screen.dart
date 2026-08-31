import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/core/providers/location_provider.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:hema_fruits/shared/widgets/location_picker_sheet.dart';
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
  final TextEditingController _notesController = TextEditingController();

  String _selectedSlot = 'EXPRESS';
  String _selectedPaymentMethod = 'UPI';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<EcommCartProvider>();
    final location = context.watch<LocationProvider>();
    final loc = location.currentLocation;

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
                  // ── ADDRESS CARD (Live from LocationProvider) ─────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                              onPressed: () => context.push('/ecommerce/addresses'),
                              child: const Text('CHANGE', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cart.addresses.isEmpty
                              ? 'No Delivery Address Added'
                              : '${cart.selectedAddress['fullName'] ?? ''} • ${cart.selectedAddress['phone'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cart.addresses.isEmpty
                              ? 'Please click CHANGE to add a delivery address.'
                              : '${cart.selectedAddress['addressLine'] ?? ''}, ${cart.selectedAddress['city'] ?? ''}, ${cart.selectedAddress['state'] ?? ''} - ${cart.selectedAddress['pincode'] ?? ''}',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        // Mode badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                loc.isServiceable ? '⚡ Serviceable for 2-Hour Express Delivery' : '📦 Standard Delivery Slot',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    loc.mode == LocationDetectionMode.autoDetect
                                        ? Icons.gps_fixed
                                        : loc.mode == LocationDetectionMode.mapPicker
                                            ? Icons.map_rounded
                                            : Icons.search_rounded,
                                    size: 11,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    loc.mode == LocationDetectionMode.autoDetect
                                        ? 'GPS Detected'
                                        : loc.mode == LocationDetectionMode.mapPicker
                                            ? 'Map Pin'
                                            : 'Typed',
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── DELIVERY SLOT SELECTOR ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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

                  // ── PAYMENT OPTIONS ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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

                  // Special Notes Input Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes, color: Color(0xFF0F9D58), size: 20),
                            SizedBox(width: 8),
                            Text('Delivery Instructions / Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'e.g. Leave at the gate, call before delivery, etc.',
                            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                            fillColor: const Color(0xFFF8F9FA),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            contentPadding: const EdgeInsets.all(10),
                          ),
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
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                              Expanded(child: Text('${item.quantity}x ${item.productTitle}', style: const TextStyle(fontSize: 12, color: Colors.black87))),
                              Text('₹${item.totalPrice.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                        const Divider(height: 16),
                        _priceSummaryRow('Item Total', '₹${cart.itemTotal.toInt()}'),
                        if (cart.discountTotal > 0)
                          _priceSummaryRow('Discount', '-₹${cart.discountTotal.toInt()}', color: Colors.green),
                        _priceSummaryRow('Delivery Fee', cart.deliveryFee == 0 ? 'FREE ⚡' : '₹${cart.deliveryFee.toInt()}', color: cart.deliveryFee == 0 ? Colors.green : null),
                        _priceSummaryRow('Packaging Fee', '₹${cart.packagingFee.toInt()}'),
                        if (cart.appliedCoupon.isNotEmpty)
                          _priceSummaryRow('Coupon (${cart.appliedCoupon})', '-₹${cart.couponDiscount.toInt()}', color: Colors.green),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL PAYABLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('₹${cart.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B5E20))),
                          ],
                        ),
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
                      final activeAddress = cart.selectedAddress;
                      final addressLine = activeAddress['addressLine'] ?? '';
                      final city = activeAddress['city'] ?? '';
                      final state = activeAddress['state'] ?? '';
                      final pincode = activeAddress['pincode'] ?? '';
                      final customerName = activeAddress['fullName'] ?? '';
                      final customerPhone = activeAddress['phone'] ?? '';
                      
                      final notes = _notesController.text.trim();
                      final finalAddressLine = notes.isNotEmpty ? '$addressLine. Notes: $notes' : addressLine;

                      final order = await _repository.placeOrder(
                        paymentMethod: _selectedPaymentMethod,
                        slotId: _selectedSlot,
                        addressLine: finalAddressLine,
                        city: city,
                        state: state,
                        pincode: pincode,
                        customerName: customerName,
                        customerPhone: customerPhone,
                      );
                      setState(() => _isSubmitting = false);

                      if (order != null) {
                        cart.clearCart();
                        if (mounted) {
                          context.go('/ecommerce/order-success/${order.id}');
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

  Widget _priceSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}

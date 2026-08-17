import 'package:cached_network_image/cached_network_image.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<EcommCartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Fresh Basket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Your Basket is Empty!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add farm fresh fruits, vegetables & dry nuts to continue.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D58),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => context.pop(),
                    child: const Text('Browse Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Free Shipping Progress Bar Header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: const Color(0xFFE8F5E9),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping, color: Color(0xFF0F9D58), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cart.freeDeliveryProgress >= 1.0
                                  ? '🎉 You unlocked FREE Express Delivery!'
                                  : 'Add ₹${cart.amountNeededForFreeDelivery.toStringAsFixed(0)} more for FREE Express Delivery',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1B5E20)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: cart.freeDeliveryProgress,
                        backgroundColor: Colors.white,
                        color: const Color(0xFF0F9D58),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cart Items List
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cart.items.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              return Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: item.imageUrl,
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(color: Colors.grey[100]),
                                        errorWidget: (context, url, err) => Container(color: Colors.grey[200]),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productTitle,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '₹${item.unitPrice.toInt()} per unit',
                                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Total: ₹${item.totalPrice.toInt()}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B5E20)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F9D58),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: () => cart.updateQuantity(item.variantId, -1),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                            onPressed: () => cart.updateQuantity(item.variantId, 1),
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

                        const SizedBox(height: 14),

                        // Coupon Bar Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer, color: Color(0xFF0F9D58)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  decoration: const InputDecoration(
                                    hintText: 'Apply Promo Coupon (e.g. FRESH100)',
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (_couponController.text.isNotEmpty) {
                                    cart.applyCoupon(_couponController.text.trim().toUpperCase());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(cart.appliedCoupon.isNotEmpty ? 'Coupon ${cart.appliedCoupon} Applied!' : 'Invalid Coupon Code'),
                                        backgroundColor: cart.appliedCoupon.isNotEmpty ? const Color(0xFF1B5E20) : Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('APPLY', style: TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Bill Details Card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Item Subtotal', style: TextStyle(color: Colors.black87, fontSize: 13)),
                                  Text('₹${cart.itemTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Delivery Fee', style: TextStyle(color: Colors.black87, fontSize: 13)),
                                  Text(
                                    cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
                                    style: TextStyle(fontSize: 13, color: cart.deliveryFee == 0 ? const Color(0xFF0F9D58) : Colors.black87, fontWeight: cart.deliveryFee == 0 ? FontWeight.bold : FontWeight.normal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Handling & Eco Packaging', style: TextStyle(color: Colors.black87, fontSize: 13)),
                                  Text('₹${cart.packagingFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              if (cart.couponDiscount > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Coupon Discount', style: TextStyle(color: Color(0xFF0F9D58), fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text('-₹${cart.couponDiscount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF0F9D58), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('To Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    '₹${cart.grandTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B5E20)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Proceed Bar
                Container(
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
                          const Text('VIEW BILL DETAILS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () => context.push('/ecommerce/checkout'),
                        child: const Row(
                          children: [
                            Text('PROCEED TO CHECKOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                          ],
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hema_fruits/core/providers/ecommerce_provider.dart';
import 'package:hema_fruits/shared/widgets/empty_state_widget.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<EcommCartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('My Fresh Basket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50), size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: cart.items.isEmpty
          ? EmptyStateWidget(
              icon: Icons.shopping_basket_outlined,
              title: 'Your Basket is Empty!',
              message: 'Add farm fresh fruits, vegetables & organic dry nuts to continue.',
              buttonText: 'Explore Fresh Store',
              onAction: () => context.pop(),
            )
          : Column(
              children: [
                // Free Shipping Progress Bar Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    border: Border(bottom: BorderSide(color: const Color(0xFF1E5E42).withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping_rounded, color: Color(0xFF1E5E42), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              cart.freeDeliveryProgress >= 1.0
                                  ? '🎉 You unlocked FREE Express Delivery!'
                                  : 'Add ₹${cart.amountNeededForFreeDelivery.toStringAsFixed(0)} more for FREE Express Delivery',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E5E42)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cart.freeDeliveryProgress,
                          backgroundColor: Colors.white,
                          color: const Color(0xFF1E5E42),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cart Items List
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cart.items.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final item = cart.items[index];
                              return Dismissible(
                                key: ValueKey(item.variantId),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (direction) {
                                  cart.removeItem(item.variantId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item.productTitle} removed from basket')),
                                  );
                                },
                                child: Padding(
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
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Coupon Input Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer_rounded, color: Color(0xFF1E5E42), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  decoration: InputDecoration(
                                    hintText: 'Apply Promo Coupon (e.g. FRESH100)',
                                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                                        content: Text(cart.appliedCoupon.isNotEmpty ? 'Coupon ${cart.appliedCoupon} Applied Successfully!' : 'Invalid Coupon Code'),
                                        backgroundColor: cart.appliedCoupon.isNotEmpty ? const Color(0xFF1E5E42) : Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('APPLY', style: TextStyle(color: Color(0xFF1E5E42), fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bill Details Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2C3E50))),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Item Subtotal', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  Text('₹${cart.itemTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Express Delivery Fee', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  Text(
                                    cart.deliveryFee == 0 ? 'FREE' : '₹${cart.deliveryFee.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cart.deliveryFee == 0 ? const Color(0xFF1E5E42) : Colors.black87,
                                      fontWeight: cart.deliveryFee == 0 ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Handling & Eco Packaging', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                  Text('₹${cart.packagingFee.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              if (cart.couponDiscount > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Coupon Savings', style: TextStyle(color: Color(0xFF1E5E42), fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text('-₹${cart.couponDiscount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E5E42), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                              Divider(height: 24, color: Colors.grey[200]),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('To Pay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2C3E50))),
                                  Text(
                                    '₹${cart.grandTotal.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Color(0xFF1E5E42)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),
                        _buildSavedForLater(context),
                      ],
                    ),
                  ),
                ),

                // Bottom Proceed Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('₹${cart.grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E5E42))),
                          const Text('TOTAL PAYABLE', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5E42),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 2,
                        ),
                        onPressed: () => context.push('/ecommerce/checkout'),
                        child: const Row(
                          children: [
                            Text('PROCEED TO CHECKOUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
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
  Widget _buildSavedForLater(BuildContext context) {
    final catalog = context.watch<EcommCatalogProvider>();
    final cart = context.read<EcommCartProvider>();
    final savedItems = catalog.products.where((p) => catalog.wishlistProductIds.contains(p.id)).toList();

    if (savedItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Saved for Later (Wishlist)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: savedItems.length,
            itemBuilder: (context, index) {
              final product = savedItems[index];
              final variant = product.defaultVariant;

              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: product.images.isNotEmpty ? product.images.first : '',
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text('₹${variant.sellingPrice.toInt()} (${variant.formattedWeight})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F9D58),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                cart.addItem(product, variant);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${product.title} added to basket')),
                                );
                              },
                              child: const Text('Move to Basket', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
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
        const SizedBox(height: 10),
      ],
    );
  }
}

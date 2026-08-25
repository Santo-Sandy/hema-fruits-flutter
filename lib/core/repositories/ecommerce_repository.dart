import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:dio/dio.dart';

/// All methods throw on failure — no hardcoded fallback data.
/// The provider layer catches these and exposes an [error] state to the UI.
class EcommerceRepository {
  final Dio _dio = AppConfig.instance.dio;

  // ── CATEGORY APIs ─────────────────────────────────────────────────────────

  Future<List<StoreCategory>> getCategories() async {
    final res = await _dio.get('/api/v1/store/categories');
    if (res.data != null && res.data['categories'] != null) {
      final List list = res.data['categories'];
      return list.map((e) => StoreCategory.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> createCategory(Map<String, dynamic> categoryData) async {
    final res = await _dio.post('/api/v1/store/categories', data: categoryData);
    return res.data != null && res.data['success'] == true;
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/api/v1/store/categories/$id', data: data);
    return res.data != null && res.data['success'] == true;
  }

  Future<bool> deleteCategory(String id) async {
    final res = await _dio.delete('/api/v1/store/categories/$id');
    return res.data != null && res.data['success'] == true;
  }

  // ── PRODUCT APIs ──────────────────────────────────────────────────────────

  Future<List<StoreProduct>> getProducts({
    String? categoryId,
    String? search,
    bool? organic,
  }) async {
    final res = await _dio.get('/api/v1/store/products', queryParameters: {
      if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (organic == true) 'organic': 'true',
    });
    if (res.data != null && res.data['products'] != null) {
      final List list = res.data['products'];
      return list.map((e) => StoreProduct.fromJson(e)).toList();
    }
    return [];
  }

  Future<StoreProduct?> getProductById(String id) async {
    final res = await _dio.get('/api/v1/store/products/$id');
    if (res.data != null && res.data['product'] != null) {
      return StoreProduct.fromJson(res.data['product']);
    }
    return null;
  }

  Future<bool> createProduct(Map<String, dynamic> productData) async {
    final res = await _dio.post('/api/v1/store/products', data: productData);
    return res.data != null && res.data['success'] == true;
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> productData) async {
    final res = await _dio.put('/api/v1/store/products/$id', data: productData);
    return res.data != null && res.data['success'] == true;
  }

  Future<bool> deleteProduct(String id) async {
    final res = await _dio.delete('/api/v1/store/products/$id');
    return res.data != null && res.data['success'] == true;
  }

  // ── BANNER APIs ───────────────────────────────────────────────────────────

  Future<List<StoreBanner>> getBanners() async {
    final res = await _dio.get('/api/v1/store/banners');
    if (res.data != null && res.data['banners'] != null) {
      final List list = res.data['banners'];
      return list.map((e) => StoreBanner.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> createBanner(Map<String, dynamic> bannerData) async {
    final res = await _dio.post('/api/v1/store/banners', data: bannerData);
    return res.data != null && res.data['success'] == true;
  }

  Future<bool> deleteBanner(String id) async {
    final res = await _dio.delete('/api/v1/store/banners/$id');
    return res.data != null && res.data['success'] == true;
  }

  // ── CART APIs ─────────────────────────────────────────────────────────────

  Future<CartSummaryModel?> getCart() async {
    final res = await _dio.get('/api/v1/store/cart');
    if (res.data != null && res.data['cart'] != null) {
      return CartSummaryModel.fromJson(res.data['cart']);
    }
    return null;
  }

  Future<CartSummaryModel?> updateCartItem(CartItemModel item) async {
    final res = await _dio.post('/api/v1/store/cart/item', data: item.toJson());
    if (res.data != null && res.data['cart'] != null) {
      return CartSummaryModel.fromJson(res.data['cart']);
    }
    return null;
  }

  Future<bool> removeCartItem(String variantId) async {
    final res = await _dio.delete('/api/v1/store/cart/item/$variantId');
    return res.data != null && res.data['success'] == true;
  }

  Future<bool> clearCart() async {
    final res = await _dio.delete('/api/v1/store/cart');
    return res.data != null && res.data['success'] == true;
  }

  Future<bool> applyCoupon(String couponCode) async {
    final res = await _dio.post('/api/v1/store/cart/coupon', data: {'coupon': couponCode});
    return res.data != null && res.data['success'] == true;
  }

  // ── ORDER APIs ────────────────────────────────────────────────────────────

  Future<StoreOrderModel?> placeOrder({
    required String paymentMethod,
    required String slotId,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    String? customerName,
    String? customerPhone,
  }) async {
    final res = await _dio.post('/api/v1/store/orders', data: {
      'payment_method': paymentMethod,
      'delivery_slot': {
        'slot_id': slotId,
        'time_range': _slotLabel(slotId),
      },
      'delivery_address': {
        'full_name': customerName ?? '',
        'phone': customerPhone ?? '',
        'address_line': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
      },
    });
    if (res.data != null && res.data['order'] != null) {
      return StoreOrderModel.fromJson(res.data['order']);
    }
    return null;
  }

  Future<List<StoreOrderModel>> getUserOrders() async {
    final res = await _dio.get('/api/v1/store/orders');
    if (res.data != null && res.data['orders'] != null) {
      final List list = res.data['orders'];
      return list.map((e) => StoreOrderModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<StoreOrderModel?> getOrderById(String orderId) async {
    final res = await _dio.get('/api/v1/store/orders/$orderId');
    if (res.data != null && res.data['order'] != null) {
      return StoreOrderModel.fromJson(res.data['order']);
    }
    return null;
  }

  Future<bool> cancelOrder(String orderId) async {
    final res = await _dio.delete('/api/v1/store/orders/$orderId');
    return res.data != null && res.data['success'] == true;
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  String _slotLabel(String slotId) {
    switch (slotId) {
      case 'EXPRESS':
        return 'Express 2 Hours';
      case 'SLOT_MORNING':
        return 'Tomorrow 7:00 AM – 10:00 AM';
      case 'SLOT_EVENING':
        return 'Tomorrow 5:00 PM – 8:00 PM';
      default:
        return slotId;
    }
  }
}

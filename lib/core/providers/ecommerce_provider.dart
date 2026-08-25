import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:flutter/material.dart';

class EcommCatalogProvider extends ChangeNotifier {
  final EcommerceRepository _repository = EcommerceRepository();

  List<StoreCategory> _categories = [];
  List<StoreProduct> _products = [];
  List<StoreBanner> _banners = [];

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _selectedCategoryId = '';
  String _searchQuery = '';
  bool _isOrganicOnly = false;

  List<StoreCategory> get categories => _categories;
  List<StoreProduct> get products => _products;
  List<StoreBanner> get banners => _banners;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isOrganicOnly => _isOrganicOnly;

  Future<void> initCatalog() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getBanners(),
        _repository.getProducts(),
      ]);
      _categories = results[0] as List<StoreCategory>;
      _banners = results[1] as List<StoreBanner>;
      _products = results[2] as List<StoreProduct>;
    } catch (e) {
      _hasError = true;
      _errorMessage = _parseError(e);
      debugPrint('Catalog init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(String categoryId) {
    _selectedCategoryId = (_selectedCategoryId == categoryId) ? '' : categoryId;
    fetchFilteredProducts();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchFilteredProducts();
  }

  void toggleOrganicFilter() {
    _isOrganicOnly = !_isOrganicOnly;
    fetchFilteredProducts();
  }

  Future<void> fetchFilteredProducts() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _products = await _repository.getProducts(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
        organic: _isOrganicOnly,
      );
    } catch (e) {
      _hasError = true;
      _errorMessage = _parseError(e);
      _products = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => initCatalog();

  // ── CRUD HELPERS ─────────────────────────────────────────────────────────

  Future<bool> addCategory(Map<String, dynamic> categoryData) async {
    try {
      final success = await _repository.createCategory(categoryData);
      if (success) await initCatalog();
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final success = await _repository.deleteCategory(id);
      if (success) await initCatalog();
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addProduct(Map<String, dynamic> productData) async {
    try {
      final success = await _repository.createProduct(productData);
      if (success) await fetchFilteredProducts();
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final success = await _repository.updateProduct(id, productData);
      if (success) await fetchFilteredProducts();
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final success = await _repository.deleteProduct(id);
      if (success) await fetchFilteredProducts();
      return success;
    } catch (e) {
      return false;
    }
  }

  String _parseError(Object e) {
    final s = e.toString();
    if (s.contains('503')) return 'Server unavailable. Please try again.';
    if (s.contains('401')) return 'Session expired. Please log in again.';
    if (s.contains('SocketException') || s.contains('connection')) {
      return 'No internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}

class EcommCartProvider extends ChangeNotifier {
  final EcommerceRepository _repository = EcommerceRepository();

  final List<CartItemModel> _items = [];
  String _appliedCoupon = '';
  double _couponDiscount = 0.0;
  final double _deliveryFee = 35.0;
  final double _packagingFee = 15.0;

  List<CartItemModel> get items => _items;
  String get appliedCoupon => _appliedCoupon;
  double get couponDiscount => _couponDiscount;
  double get deliveryFee => itemTotal >= 499 || items.isEmpty ? 0 : _deliveryFee;
  double get packagingFee => _packagingFee;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get itemTotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalMRP => _items.fold(0.0, (sum, item) => sum + (item.mrp * item.quantity));
  double get discountTotal => totalMRP - itemTotal;

  double get freeDeliveryThreshold => 499.0;
  double get amountNeededForFreeDelivery {
    if (itemTotal >= freeDeliveryThreshold || itemTotal == 0) return 0;
    return freeDeliveryThreshold - itemTotal;
  }
  double get freeDeliveryProgress {
    if (itemTotal >= freeDeliveryThreshold) return 1.0;
    if (itemTotal == 0) return 0.0;
    return itemTotal / freeDeliveryThreshold;
  }

  double get grandTotal {
    if (_items.isEmpty) return 0.0;
    double total = itemTotal + deliveryFee + packagingFee - _couponDiscount;
    return total < 0 ? 0 : total;
  }

  void addItem(StoreProduct product, ProductVariant variant) {
    final index = _items.indexWhere((element) => element.variantId == variant.id);
    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItemModel(
        productId: product.id,
        variantId: variant.id,
        productTitle: '${product.title} (${variant.formattedWeight})',
        imageUrl: product.images.isNotEmpty ? product.images.first : '',
        weightValue: variant.weightValue,
        weightUnit: variant.weightUnit,
        unitPrice: variant.sellingPrice,
        mrp: variant.mrp,
        quantity: 1,
        isPerishable: product.shelfLifeDays <= 7,
      ));
    }
    notifyListeners();
    _syncCartWithBackend();
  }

  void updateQuantity(String variantId, int delta) {
    final index = _items.indexWhere((element) => element.variantId == variantId);
    if (index >= 0) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        final removed = _items.removeAt(index);
        _repository.removeCartItem(removed.variantId).catchError((_) => false);
      }
      notifyListeners();
      _syncCartWithBackend();
    }
  }

  void removeItem(String variantId) {
    _items.removeWhere((element) => element.variantId == variantId);
    _repository.removeCartItem(variantId).catchError((_) => false);
    notifyListeners();
  }

  Future<void> applyCoupon(String couponCode) async {
    // Try backend first
    try {
      final success = await _repository.applyCoupon(couponCode);
      if (success) {
        _appliedCoupon = couponCode;
        if (couponCode == 'FRESH100') {
          _couponDiscount = 100.0;
        } else if (couponCode == 'FRESH50') {
          _couponDiscount = 50.0;
        } else {
          _appliedCoupon = '';
          _couponDiscount = 0.0;
        }
        notifyListeners();
        return;
      }
    } catch (_) {}
    // Local fallback
    if (couponCode == 'FRESH100') {
      _appliedCoupon = 'FRESH100';
      _couponDiscount = 100.0;
    } else if (couponCode == 'FRESH50') {
      _appliedCoupon = 'FRESH50';
      _couponDiscount = 50.0;
    } else {
      _appliedCoupon = '';
      _couponDiscount = 0.0;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = '';
    _couponDiscount = 0.0;
    _repository.clearCart().catchError((_) => false);
    notifyListeners();
  }

  Future<void> _syncCartWithBackend() async {
    for (final item in _items) {
      await _repository.updateCartItem(item).catchError((_) => null);
    }
  }
}

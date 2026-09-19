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

  // Wishlist state
  final List<String> _wishlistProductIds = [];

  String _selectedSellerId = '';

  List<StoreCategory> get categories => _categories;
  List<StoreProduct> get products => _products;
  List<StoreBanner> get banners => _banners;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get selectedCategoryId => _selectedCategoryId;
  String get selectedSellerId => _selectedSellerId;
  String get searchQuery => _searchQuery;
  bool get isOrganicOnly => _isOrganicOnly;
  List<String> get wishlistProductIds => _wishlistProductIds;

  Future<void> initCatalog() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCategories(),
        _repository.getBanners(),
        _repository.getProducts(sellerId: _selectedSellerId),
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

  void selectSellerId(String sellerId) {
    _selectedSellerId = (_selectedSellerId == sellerId) ? '' : sellerId;
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
        sellerId: _selectedSellerId,
      );
    } catch (e) {
      _hasError = true;
      _errorMessage = _parseError(e);
      _products = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<StoreProduct>> fetchProductsBySeller(String sellerId) async {
    try {
      return await _repository.getProducts(sellerId: sellerId);
    } catch (e) {
      return [];
    }
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

  Future<bool> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) async {
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

  // Wishlist actions
  bool isProductWishlisted(String productId) {
    return _wishlistProductIds.contains(productId);
  }

  void toggleWishlist(String productId) {
    if (_wishlistProductIds.contains(productId)) {
      _wishlistProductIds.remove(productId);
    } else {
      _wishlistProductIds.add(productId);
    }
    notifyListeners();
  }
}

class EcommCartProvider extends ChangeNotifier {
  final EcommerceRepository _repository = EcommerceRepository();

  final List<CartItemModel> _items = [];
  String _appliedCoupon = '';
  double _couponDiscount = 0.0;
  final double _deliveryFee = 35.0;
  final double _packagingFee = 15.0;

  // Saved Addresses state
  final List<Map<String, String>> _addresses = [
    {
      'id': 'addr_1',
      'name': 'Home 🏠',
      'fullName': 'Santo Kumar',
      'phone': '98765 43210',
      'addressLine':
          'Flat 402, Green Avenue, 12th Main Road, HSR Layout Sector 1',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'pincode': '560102',
      'isDefault': 'true',
    },
    {
      'id': 'addr_2',
      'name': 'Office 🏢',
      'fullName': 'Santo Kumar',
      'phone': '98765 43210',
      'addressLine': 'Building 4B, Ground Floor, Tech Park, Outer Ring Road',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'pincode': '560103',
      'isDefault': 'false',
    },
  ];
  int _selectedAddressIndex = 0;

  List<CartItemModel> get items => _items;
  String get appliedCoupon => _appliedCoupon;
  double get couponDiscount => _couponDiscount;
  double get deliveryFee =>
      itemTotal >= 499 || items.isEmpty ? 0 : _deliveryFee;
  double get packagingFee => items.isEmpty ? 0 : _packagingFee;

  // Address Getters
  List<Map<String, String>> get addresses => _addresses;
  int get selectedAddressIndex => _selectedAddressIndex;
  Map<String, String> get selectedAddress =>
      _addresses.isNotEmpty ? _addresses[_selectedAddressIndex] : {};

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);
  int get itemCount => totalCount;

  double get itemTotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalMRP =>
      _items.fold(0.0, (sum, item) => sum + (item.mrp * item.quantity));
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

  // Address Actions
  void selectAddress(int index) {
    if (index >= 0 && index < _addresses.length) {
      _selectedAddressIndex = index;
      notifyListeners();
    }
  }

  void addAddress(Map<String, String> address) {
    _addresses.add(address);
    notifyListeners();
  }

  void deleteAddress(String id) {
    _addresses.removeWhere((element) => element['id'] == id);
    if (_selectedAddressIndex >= _addresses.length) {
      _selectedAddressIndex = 0;
    }
    notifyListeners();
  }

  void clearLocalCart() {
    _items.clear();
    _appliedCoupon = '';
    _couponDiscount = 0.0;
    notifyListeners();
  }

  Future<void> fetchCart() async {
    final res = await _repository.getCart();
    if (res != null) {
      _updateFromSummary(res);
    }
  }

  void _updateFromSummary(CartSummaryModel summary) {
    _items.clear();
    _items.addAll(summary.items);
    _appliedCoupon = summary.appliedCoupon;
    _couponDiscount = summary.couponDiscount;
    notifyListeners();
  }

  Future<void> _syncItem(CartItemModel item) async {
    final res = await _repository.updateCartItem(item);
    if (res != null) {
      _updateFromSummary(res);
    }
  }

  Future<void> _removeItemFromBackend(String variantId) async {
    final res = await _repository.removeCartItem(variantId);
    if (res != null) {
      _updateFromSummary(res);
    }
  }

  void addItem(StoreProduct product, ProductVariant variant) {
    final index = _items.indexWhere(
      (element) => element.variantId == variant.id,
    );
    CartItemModel item;
    if (index >= 0) {
      _items[index].quantity += 1;
      item = _items[index];
    } else {
      item = CartItemModel(
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
      );
      _items.add(item);
    }
    notifyListeners();
    _syncItem(item);
  }

  void updateQuantity(String variantId, int delta) {
    final index = _items.indexWhere(
      (element) => element.variantId == variantId,
    );
    if (index >= 0) {
      _items[index].quantity += delta;
      final item = _items[index];
      if (item.quantity <= 0) {
        _items.removeAt(index);
        notifyListeners();
        _removeItemFromBackend(variantId);
      } else {
        notifyListeners();
        _syncItem(item);
      }
    }
  }

  void removeItem(String variantId) {
    _items.removeWhere((element) => element.variantId == variantId);
    notifyListeners();
    _removeItemFromBackend(variantId);
  }

  Future<void> applyCoupon(String couponCode) async {
    // Try backend first
    try {
      final res = await _repository.applyCoupon(couponCode);
      if (res != null) {
        _updateFromSummary(res);
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

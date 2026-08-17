import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:hema_fruits/core/repositories/ecommerce_repository.dart';
import 'package:flutter/material.dart';

class EcommCatalogProvider extends ChangeNotifier {
  final EcommerceRepository _repository = EcommerceRepository();

  List<StoreCategory> _categories = [];
  List<StoreProduct> _products = [];
  List<StoreBanner> _banners = [];

  bool _isLoading = false;
  String _selectedCategoryId = '';
  String _searchQuery = '';
  bool _isOrganicOnly = false;

  List<StoreCategory> get categories => _categories;
  List<StoreProduct> get products => _products;
  List<StoreBanner> get banners => _banners;
  bool get isLoading => _isLoading;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isOrganicOnly => _isOrganicOnly;

  Future<void> initCatalog() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _repository.getCategories();
      _banners = await _repository.getBanners();
      _products = await _repository.getProducts();
    } catch (e) {
      debugPrint('Catalog init error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(String categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = '';
    } else {
      _selectedCategoryId = categoryId;
    }
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
    notifyListeners();

    _products = await _repository.getProducts(
      categoryId: _selectedCategoryId,
      search: _searchQuery,
      organic: _isOrganicOnly,
    );

    _isLoading = false;
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
        _items.removeAt(index);
      }
      notifyListeners();
      _syncCartWithBackend();
    }
  }

  void removeItem(String variantId) {
    _items.removeWhere((element) => element.variantId == variantId);
    notifyListeners();
    _syncCartWithBackend();
  }

  void applyCoupon(String couponCode) {
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
    notifyListeners();
  }

  Future<void> _syncCartWithBackend() async {
    for (final item in _items) {
      await _repository.updateCartItem(item);
    }
  }
}

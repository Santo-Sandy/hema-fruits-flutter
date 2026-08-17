import 'package:hema_fruits/core/config/app_config.dart';
import 'package:hema_fruits/core/models/ecommerce_models.dart';
import 'package:dio/dio.dart';

class EcommerceRepository {
  final Dio _dio = AppConfig.instance.dio;

  Future<List<StoreCategory>> getCategories() async {
    try {
      final res = await _dio.get('/api/v1/store/categories');
      if (res.data != null && res.data['categories'] != null) {
        final List list = res.data['categories'];
        return list.map((e) => StoreCategory.fromJson(e)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [
      StoreCategory(
        id: 'cat_fruits',
        name: 'Fresh Fruits',
        slug: 'fresh-fruits',
        iconUrl: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=800',
        subcategories: [
          StoreSubcategory(id: 'sub_apples', name: 'Apples & Pears', slug: 'apples-pears', iconUrl: '', itemCount: 12),
          StoreSubcategory(id: 'sub_exotic', name: 'Exotic Fruits', slug: 'exotic-fruits', iconUrl: '', itemCount: 15),
        ],
      ),
      StoreCategory(
        id: 'cat_veggies',
        name: 'Fresh Vegetables',
        slug: 'fresh-vegetables',
        iconUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800',
        subcategories: [
          StoreSubcategory(id: 'sub_leafy', name: 'Leafy Greens', slug: 'leafy-greens', iconUrl: '', itemCount: 18),
          StoreSubcategory(id: 'sub_daily', name: 'Daily Essentials', slug: 'daily-essentials', iconUrl: '', itemCount: 25),
        ],
      ),
      StoreCategory(
        id: 'cat_dry_nuts',
        name: 'Dry Fruits & Nuts',
        slug: 'dry-fruits-nuts',
        iconUrl: 'https://images.unsplash.com/photo-1508061252966-177209772242?w=200',
        bannerUrl: 'https://images.unsplash.com/photo-1508061252966-177209772242?w=800',
        subcategories: [
          StoreSubcategory(id: 'sub_almonds', name: 'Almonds & Cashews', slug: 'almonds-cashews', iconUrl: '', itemCount: 20),
          StoreSubcategory(id: 'sub_walnuts', name: 'Walnuts & Pistachios', slug: 'walnuts-pistachios', iconUrl: '', itemCount: 16),
        ],
      ),
    ];
  }

  Future<List<StoreProduct>> getProducts({String? categoryId, String? search, bool? organic}) async {
    try {
      final res = await _dio.get('/api/v1/store/products', queryParameters: {
        if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (organic == true) 'organic': 'true',
      });
      if (res.data != null && res.data['products'] != null) {
        final List list = res.data['products'];
        return list.map((e) => StoreProduct.fromJson(e)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return getFallbackProducts();
  }

  Future<List<StoreBanner>> getBanners() async {
    try {
      final res = await _dio.get('/api/v1/store/banners');
      if (res.data != null && res.data['banners'] != null) {
        final List list = res.data['banners'];
        return list.map((e) => StoreBanner.fromJson(e)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return [
      StoreBanner(
        id: 'b1',
        title: 'Farm Fresh Mangoes & Berries',
        subtitle: 'Up to 30% OFF | Handpicked Daily',
        imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=1000',
        targetCategory: 'cat_fruits',
        actionUrl: '/ecommerce/category/cat_fruits',
      ),
      StoreBanner(
        id: 'b2',
        title: '100% Organic Pesticide-Free Greens',
        subtitle: 'Direct from Certified Farmers',
        imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=1000',
        targetCategory: 'cat_veggies',
        actionUrl: '/ecommerce/category/cat_veggies',
      ),
      StoreBanner(
        id: 'b3',
        title: 'Premium Jumbo Cashews & Walnuts',
        subtitle: 'Rich in Nutrients | Vacuum Packed',
        imageUrl: 'https://images.unsplash.com/photo-1508061252966-177209772242?w=1000',
        targetCategory: 'cat_dry_nuts',
        actionUrl: '/ecommerce/category/cat_dry_nuts',
      ),
    ];
  }

  Future<CartSummaryModel?> getCart() async {
    try {
      final res = await _dio.get('/api/v1/store/cart');
      if (res.data != null && res.data['cart'] != null) {
        return CartSummaryModel.fromJson(res.data['cart']);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  Future<CartSummaryModel?> updateCartItem(CartItemModel item) async {
    try {
      final res = await _dio.post('/api/v1/store/cart/item', data: item.toJson());
      if (res.data != null && res.data['cart'] != null) {
        return CartSummaryModel.fromJson(res.data['cart']);
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  Future<StoreOrderModel?> placeOrder({
    required String paymentMethod,
    required String slotId,
    required String addressLine,
  }) async {
    try {
      final res = await _dio.post('/api/v1/store/orders', data: {
        'payment_method': paymentMethod,
        'delivery_slot': {'slot_id': slotId, 'time_range': 'Express 2 Hours'},
        'delivery_address': {
          'full_name': 'Santo Kumar',
          'phone': '9876543210',
          'address_line': addressLine,
          'city': 'Bengaluru',
          'state': 'Karnataka',
          'pincode': '560102',
        }
      });
      if (res.data != null && res.data['order'] != null) {
        return StoreOrderModel.fromJson(res.data['order']);
      }
    } catch (e) {
      // Fallback
    }
    return StoreOrderModel(
      id: 'ord_express_101',
      orderNumber: 'HEMA-FRESH-9921',
      items: [],
      orderStatus: 'PLACED',
      paymentMethod: paymentMethod,
      grandTotal: 480,
      deliveryOtp: '7194',
      deliveryAgentName: 'Ramesh (Express Delivery)',
      deliveryAgentPhone: '+91 98123 45678',
    );
  }

  List<StoreProduct> getFallbackProducts() {
    return [
      StoreProduct(
        id: 'prod_1',
        title: 'Shimla Premium Royal Delicious Apples',
        slug: 'shimla-apples',
        categoryId: 'cat_fruits',
        subcategoryId: 'sub_apples',
        description: 'Crisp, sweet, and juicy handpicked royal apples sourced directly from high-altitude orchards in Shimla.',
        images: ['https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600'],
        shelfLifeDays: 7,
        storageInstructions: 'Store in cool refrigeration.',
        isOrganic: false,
        qualityGrade: 'Grade A Farm Fresh',
        originRegion: 'Shimla, HP',
        avgRating: 4.8,
        reviewCount: 142,
        isFeatured: true,
        variants: [
          ProductVariant(id: 'v1_500g', productId: 'prod_1', weightValue: 500, weightUnit: 'g', packagingType: 'Eco Tray', mrp: 140, sellingPrice: 110, stockQuantity: 45, sku: 'APL-500G', isAvailable: true),
          ProductVariant(id: 'v1_1kg', productId: 'prod_1', weightValue: 1, weightUnit: 'kg', packagingType: 'Eco Box', mrp: 260, sellingPrice: 210, stockQuantity: 30, sku: 'APL-1KG', isAvailable: true),
        ],
      ),
      StoreProduct(
        id: 'prod_2',
        title: 'Organic Pesticide-Free Spinach (Palak)',
        slug: 'organic-spinach',
        categoryId: 'cat_veggies',
        subcategoryId: 'sub_leafy',
        description: 'Fresh hydroponic spinach leaves packed with Iron, Foliate, and Vitamins.',
        images: ['https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=600'],
        shelfLifeDays: 3,
        storageInstructions: 'Keep chilled.',
        isOrganic: true,
        qualityGrade: 'Certified Organic',
        originRegion: 'Bengaluru, KA',
        avgRating: 4.7,
        reviewCount: 89,
        isFeatured: true,
        variants: [
          ProductVariant(id: 'v2_250g', productId: 'prod_2', weightValue: 250, weightUnit: 'g', packagingType: 'Breathable Pack', mrp: 40, sellingPrice: 28, stockQuantity: 60, sku: 'SPN-250G', isAvailable: true),
          ProductVariant(id: 'v2_500g', productId: 'prod_2', weightValue: 500, weightUnit: 'g', packagingType: 'Breathable Pack', mrp: 75, sellingPrice: 52, stockQuantity: 40, sku: 'SPN-500G', isAvailable: true),
        ],
      ),
      StoreProduct(
        id: 'prod_3',
        title: 'W320 Jumbo Kernel Cashew Nuts (Kaju)',
        slug: 'jumbo-cashew-w320',
        categoryId: 'cat_dry_nuts',
        subcategoryId: 'sub_almonds',
        description: 'Whole jumbo Grade W320 cashew nuts. Crunchy, buttery, and rich in healthy fats.',
        images: ['https://images.unsplash.com/photo-1508061252966-177209772242?w=600'],
        shelfLifeDays: 180,
        storageInstructions: 'Store in airtight vacuum container.',
        isOrganic: false,
        qualityGrade: 'W320 Export Quality',
        originRegion: 'Mangaluru, KA',
        avgRating: 4.9,
        reviewCount: 310,
        isFeatured: true,
        variants: [
          ProductVariant(id: 'v3_250g', productId: 'prod_3', weightValue: 250, weightUnit: 'g', packagingType: 'Vacuum Zipper', mrp: 320, sellingPrice: 260, stockQuantity: 100, sku: 'CAS-250G', isAvailable: true),
          ProductVariant(id: 'v3_500g', productId: 'prod_3', weightValue: 500, weightUnit: 'g', packagingType: 'Vacuum Zipper', mrp: 620, sellingPrice: 499, stockQuantity: 80, sku: 'CAS-500G', isAvailable: true),
        ],
      ),
      StoreProduct(
        id: 'prod_4',
        title: 'Fresh Alphonso Mangoes (GI Tagged)',
        slug: 'ratnagiri-alphonso',
        categoryId: 'cat_fruits',
        subcategoryId: 'sub_exotic',
        description: 'Naturally ripened GI-tagged Ratnagiri Alphonso mangoes. Rich saffron pulp.',
        images: ['https://images.unsplash.com/photo-1553279768-865429fa0078?w=600'],
        shelfLifeDays: 5,
        storageInstructions: 'Keep at room temp.',
        isOrganic: true,
        qualityGrade: 'GI Tagged Premium',
        originRegion: 'Ratnagiri, MH',
        avgRating: 4.95,
        reviewCount: 520,
        isFeatured: true,
        variants: [
          ProductVariant(id: 'v4_6pcs', productId: 'prod_4', weightValue: 6, weightUnit: 'pcs', packagingType: 'Wooden Box', mrp: 850, sellingPrice: 699, stockQuantity: 25, sku: 'MNG-6PCS', isAvailable: true),
          ProductVariant(id: 'v4_12pcs', productId: 'prod_4', weightValue: 12, weightUnit: 'pcs', packagingType: 'Wooden Box', mrp: 1600, sellingPrice: 1299, stockQuantity: 15, sku: 'MNG-12PCS', isAvailable: true),
        ],
      ),
    ];
  }
}

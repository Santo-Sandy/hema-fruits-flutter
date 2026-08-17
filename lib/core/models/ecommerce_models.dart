class StoreSubcategory {
  final String id;
  final String name;
  final String slug;
  final String iconUrl;
  final int itemCount;

  StoreSubcategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconUrl,
    required this.itemCount,
  });

  factory StoreSubcategory.fromJson(Map<String, dynamic> json) {
    return StoreSubcategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      itemCount: json['item_count'] ?? 0,
    );
  }
}

class StoreCategory {
  final String id;
  final String name;
  final String slug;
  final String iconUrl;
  final String bannerUrl;
  final List<StoreSubcategory> subcategories;

  StoreCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.iconUrl,
    required this.bannerUrl,
    required this.subcategories,
  });

  factory StoreCategory.fromJson(Map<String, dynamic> json) {
    return StoreCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      bannerUrl: json['banner_url'] ?? '',
      subcategories: (json['subcategories'] as List? ?? [])
          .map((e) => StoreSubcategory.fromJson(e))
          .toList(),
    );
  }
}

class ProductVariant {
  final String id;
  final String productId;
  final double weightValue;
  final String weightUnit;
  final String packagingType;
  final double mrp;
  final double sellingPrice;
  final int stockQuantity;
  final String sku;
  final bool isAvailable;

  ProductVariant({
    required this.id,
    required this.productId,
    required this.weightValue,
    required this.weightUnit,
    required this.packagingType,
    required this.mrp,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.sku,
    required this.isAvailable,
  });

  String get formattedWeight => '${weightValue.toInt() == weightValue ? weightValue.toInt() : weightValue} $weightUnit';

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      weightValue: (json['weight_value'] ?? 0.0).toDouble(),
      weightUnit: json['weight_unit'] ?? 'g',
      packagingType: json['packaging_type'] ?? '',
      mrp: (json['mrp'] ?? 0.0).toDouble(),
      sellingPrice: (json['selling_price'] ?? 0.0).toDouble(),
      stockQuantity: json['stock_quantity'] ?? 0,
      sku: json['sku'] ?? '',
      isAvailable: json['is_available'] ?? true,
    );
  }
}

class StoreProduct {
  final String id;
  final String title;
  final String slug;
  final String categoryId;
  final String subcategoryId;
  final String description;
  final List<String> images;
  final int shelfLifeDays;
  final String storageInstructions;
  final bool isOrganic;
  final String qualityGrade;
  final String originRegion;
  final List<ProductVariant> variants;
  final double avgRating;
  final int reviewCount;
  final bool isFeatured;

  StoreProduct({
    required this.id,
    required this.title,
    required this.slug,
    required this.categoryId,
    required this.subcategoryId,
    required this.description,
    required this.images,
    required this.shelfLifeDays,
    required this.storageInstructions,
    required this.isOrganic,
    required this.qualityGrade,
    required this.originRegion,
    required this.variants,
    required this.avgRating,
    required this.reviewCount,
    required this.isFeatured,
  });

  ProductVariant get defaultVariant => variants.isNotEmpty ? variants.first : ProductVariant(id: '', productId: '', weightValue: 1, weightUnit: 'kg', packagingType: 'Box', mrp: 0, sellingPrice: 0, stockQuantity: 0, sku: '', isAvailable: false);

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      categoryId: json['category_id'] ?? '',
      subcategoryId: json['subcategory_id'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      shelfLifeDays: json['shelf_life_days'] ?? 3,
      storageInstructions: json['storage_instructions'] ?? '',
      isOrganic: json['is_organic'] ?? false,
      qualityGrade: json['quality_grade'] ?? 'Farm Fresh',
      originRegion: json['origin_region'] ?? '',
      variants: (json['variants'] as List? ?? [])
          .map((e) => ProductVariant.fromJson(e))
          .toList(),
      avgRating: (json['avg_rating'] ?? 4.5).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
    );
  }
}

class StoreBanner {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String targetCategory;
  final String actionUrl;

  StoreBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.targetCategory,
    required this.actionUrl,
  });

  factory StoreBanner.fromJson(Map<String, dynamic> json) {
    return StoreBanner(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
      targetCategory: json['target_category'] ?? '',
      actionUrl: json['action_url'] ?? '',
    );
  }
}

class CartItemModel {
  final String productId;
  final String variantId;
  final String productTitle;
  final String imageUrl;
  final double weightValue;
  final String weightUnit;
  final double unitPrice;
  final double mrp;
  int quantity;
  final bool isPerishable;

  CartItemModel({
    required this.productId,
    required this.variantId,
    required this.productTitle,
    required this.imageUrl,
    required this.weightValue,
    required this.weightUnit,
    required this.unitPrice,
    required this.mrp,
    required this.quantity,
    required this.isPerishable,
  });

  double get totalPrice => unitPrice * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: json['product_id'] ?? '',
      variantId: json['variant_id'] ?? '',
      productTitle: json['product_title'] ?? '',
      imageUrl: json['image_url'] ?? '',
      weightValue: (json['weight_value'] ?? 0.0).toDouble(),
      weightUnit: json['weight_unit'] ?? 'g',
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      mrp: (json['mrp'] ?? 0.0).toDouble(),
      quantity: json['quantity'] ?? 1,
      isPerishable: json['is_perishable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'variant_id': variantId,
    'product_title': productTitle,
    'image_url': imageUrl,
    'weight_value': weightValue,
    'weight_unit': weightUnit,
    'unit_price': unitPrice,
    'mrp': mrp,
    'quantity': quantity,
    'is_perishable': isPerishable,
  };
}

class CartSummaryModel {
  final List<CartItemModel> items;
  final double itemTotal;
  final double totalMRP;
  final double discountTotal;
  final double deliveryFee;
  final double packagingFee;
  final String appliedCoupon;
  final double couponDiscount;
  final double grandTotal;

  CartSummaryModel({
    required this.items,
    required this.itemTotal,
    required this.totalMRP,
    required this.discountTotal,
    required this.deliveryFee,
    required this.packagingFee,
    required this.appliedCoupon,
    required this.couponDiscount,
    required this.grandTotal,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    return CartSummaryModel(
      items: (json['items'] as List? ?? [])
          .map((e) => CartItemModel.fromJson(e))
          .toList(),
      itemTotal: (json['item_total'] ?? 0.0).toDouble(),
      totalMRP: (json['total_mrp'] ?? 0.0).toDouble(),
      discountTotal: (json['discount_total'] ?? 0.0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0.0).toDouble(),
      packagingFee: (json['packaging_fee'] ?? 0.0).toDouble(),
      appliedCoupon: json['applied_coupon'] ?? '',
      couponDiscount: (json['coupon_discount'] ?? 0.0).toDouble(),
      grandTotal: (json['grand_total'] ?? 0.0).toDouble(),
    );
  }
}

class StoreOrderModel {
  final String id;
  final String orderNumber;
  final List<CartItemModel> items;
  final String orderStatus;
  final String paymentMethod;
  final double grandTotal;
  final String deliveryOtp;
  final String deliveryAgentName;
  final String deliveryAgentPhone;

  StoreOrderModel({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.orderStatus,
    required this.paymentMethod,
    required this.grandTotal,
    required this.deliveryOtp,
    required this.deliveryAgentName,
    required this.deliveryAgentPhone,
  });

  factory StoreOrderModel.fromJson(Map<String, dynamic> json) {
    return StoreOrderModel(
      id: json['id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => CartItemModel.fromJson(e))
          .toList(),
      orderStatus: json['order_status'] ?? 'PLACED',
      paymentMethod: json['payment_method'] ?? 'UPI',
      grandTotal: (json['grand_total'] ?? 0.0).toDouble(),
      deliveryOtp: json['delivery_otp'] ?? '1234',
      deliveryAgentName: json['delivery_agent_name'] ?? 'Express Partner',
      deliveryAgentPhone: json['delivery_agent_phone'] ?? '',
    );
  }
}

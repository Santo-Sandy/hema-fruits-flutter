# 🍎 Hema Fruits - Quick E-Commerce Mobile App

A production-grade, quick-commerce mobile application built with **Flutter**, designed specifically for ordering **Fresh Fruits, Fresh Vegetables, and Dry Nuts & Fruits**. The platform delivers an intuitive shopping experience with weight-variant pickers, express 2-hour delivery slot scheduling, interactive cart calculations, live visual order tracking, and a 24-hour perishable item return guarantee.

---

## 🌟 Key Features

### 🛒 1. Modern Store Discovery
- **Hero Promo Banner Slider**: Dynamic promotional banners highlighting daily fresh harvests, seasonal discounts, and organic farms.
- **Express Pincode Serviceability**: Real-time address locator ("Deliver to HSR Layout in 2 Hours ⚡").
- **Interactive Category Pills**: Seamless category filtering across **Fresh Fruits 🍎**, **Fresh Vegetables 🥦**, **Dry Fruits & Nuts 🥜**, and **100% Organic Pesticide-Free Greens 🍃**.
- **Voice & Smart Text Search**: Fast catalog search by product name, variety, or origin.
- **Floating Cart Indicator**: Sticky bottom bar displaying active item count, live grand total, and free delivery progress.

### 📦 2. Rich Product Details (PDP)
- **High-Res Gallery**: Crisp product image preview with quality badges (**Grade A Farm Fresh**, **GI Tagged Alphonso**, **Certified Organic**).
- **Weight & Packaging Selector**: Choice chips for weight variants (e.g., 250g, 500g, 1kg, 6 pcs box, 12 pcs dozen) with dynamic price calculation.
- **Freshness & Shelf-Life Metrics**: Transparent shelf-life guidance ("Best consumed within 3 days") and storage instructions.
- **Farm Origin Transparency**: Sourcing origin tags (e.g. *Shimla, HP*, *Ratnagiri, MH*, *Mangaluru, KA*).

### 💳 3. Reactive Shopping Basket & Checkout
- **Free Shipping Meter**: Interactive progress indicator encouraging cart additions ("Add ₹45 more for FREE Express Shipping").
- **Quantity Stepper**: Instant item increment/decrement (+ / -) with automatic bill recalculation.
- **Promo Coupon Engine**: Discount validation supporting codes like `FRESH100` and `FRESH50`.
- **Delivery Window Picker**: Express 2-Hour Delivery, Morning (7 AM - 10 AM), and Evening (5 PM - 8 PM) slots.
- **Payment Options**: Deep-linked UPI (PhonePe, Google Pay, Paytm), Credit/Debit Cards, and Cash on Delivery (COD).

### 🚚 4. Live Visual Order Tracker & 24h Return System
- **Visual Step Timeline**: Real-time progress bar:
  1. `Order Placed` ✅
  2. `Freshness Checked & Packed` 🥦
  3. `Out for Express Delivery` 🚚
  4. `Delivered to Doorstep` 📦
- **Delivery OTP Security**: 4-digit verification code (`7194`) to share with the delivery executive upon arrival.
- **Direct Agent Contact**: 1-tap call button for the assigned delivery executive.
- **24-Hour Perishable Guarantee**: Direct return request workflow with photo proof upload for spoiled or damaged items.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: [Flutter SDK](https://flutter.dev) (Dart 3.x)
- **State Management**: `Provider` & `ChangeNotifier` (`EcommCatalogProvider`, `EcommCartProvider`)
- **Navigation**: `GoRouter` with deep linking support
- **Networking**: `Dio` HTTP client with `PrettyDioLogger` interceptors
- **Local Storage**: `shared_preferences`, `hive`, `flutter_secure_storage`
- **Push Notifications**: Firebase Cloud Messaging (FCM) & `flutter_local_notifications`

---

## 📂 Project Structure

```
hema-fruits-flutter/
├── lib/
│   ├── core/
│   │   ├── config/              # App environment configs & Dio setup (app_config.dart)
│   │   ├── models/              # Store, Product, Cart & Order models (ecommerce_models.dart)
│   │   ├── providers/           # Catalog & Reactive Cart State (ecommerce_provider.dart)
│   │   ├── repositories/        # API network repository & fallbacks (ecommerce_repository.dart)
│   │   └── router/              # GoRouter configuration & routes (router_config.dart)
│   ├── features/
│   │   └── screens/
│   │       └── ecommerce/
│   │           ├── home/        # Store Landing (ecomm_home_screen.dart)
│   │           ├── product/     # Product Detail Page (product_detail_screen.dart)
│   │           ├── cart/        # Basket & Checkout (cart_screen.dart, checkout_screen.dart)
│   │           └── orders/      # Live Tracking & Returns (order_tracking_screen.dart)
│   └── main.dart                # App entrypoint & MultiProvider setup
├── pubspec.yaml                 # Dependencies & asset declarations
└── README.md                    # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.10.8` or higher installed
- Android Studio / Xcode configured for mobile deployment
- Go Backend API (`hema-fruits-go`) running on `http://localhost:7002` (or configured URL)

### Installation Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-org/hema-fruits-flutter.git
   cd hema-fruits-flutter
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Code Analysis**:
   ```bash
   flutter analyze
   ```

4. **Launch the App**:
   ```bash
   flutter run
   ```

---

## 📄 License
This project is proprietary and maintained for Hema Fruits & Veggies E-Commerce operations.

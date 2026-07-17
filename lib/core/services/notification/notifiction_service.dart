import 'package:cashew_marketplace/core/router/router_config.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:flutter/material.dart';

class NotificationNavigationService {
  /// Single entry point for all FCM-driven navigation

  static Map<String, dynamic>? _pendingData;

  static Future<void> handle(Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final router = appRouter;

    if (!_isRouterReady()) {
      debugPrint("FCM Nav: Router not ready → queueing");
      _pendingData = data;
      return;
    }

    _navigate(data);
  }

  static bool _isRouterReady() {
    try {
      return appRouter.routerDelegate.navigatorKey.currentContext != null;
    } catch (_) {
      return false;
    }
  }

  static void consumePending() {
    if (_pendingData == null) return;

    debugPrint("FCM: Executing pending navigation");

    _navigate(_pendingData!);
    _pendingData = null;
  }

  static void _navigate(Map<String, dynamic> data) {
    final name = data['name'];

    switch (name) {
      case 'quotes':
        _handleQuotes(data);
        break;

      case 'stock_quotes':
        _handleStockQuotes(data);
        break;

      case '/stock':
        _push(
          RoutePath.sellerResponseviewscreen,
          extra: ['${data['requirementId']}', '${data['_id']}'],
        );
        break;

      case 'stocks':
        _push(RoutePath.viewscreen, extra: '${data['_id']}');
        break;

      case 'requirements':
        _push(RoutePath.sellerviewscreen, extra: '${data['_id']}');
        break;

      default:
        debugPrint("FCM: Unknown route $name");
    }
  }

  static void setPending(Map<String, dynamic> data) {
    _pendingData = data;
  }
  // static Future<void> handle(Map<String, dynamic> data) async {
  //   if (data.isEmpty) return;

  //   final name = data['name'] as String?;
  //   if (name == null) {
  //     debugPrint("FCM Nav: Missing 'name' key in payload");
  //     return;
  //   }

  //   debugPrint("FCM Nav: Handling route for '$name'");

  //   switch (name) {
  //     case 'quotes':
  //       await _handleQuotes(data);
  //     case 'stock_quotes':
  //       await _handleStockQuotes(data);
  //     case '/stock':
  //       _push(
  //         RoutePath.sellerResponseviewscreen,
  //         extra: [data['requirementId'] ?? '', data['_id'] ?? ''],
  //       );
  //     case 'stocks':
  //       _push(RoutePath.viewscreen, extra: data['_id'] ?? '');
  //     case 'requirements':
  //       _push(RoutePath.sellerviewscreen, extra: data['_id'] ?? '');
  //     default:
  //       debugPrint("FCM Nav: Unknown route '$name'");
  //   }
  // }

  static Future<void> _handleQuotes(Map<String, dynamic> data) async {
    final userData = await SecureStorageService.getUserData();
    final userId = userData['_id'] ?? '';
    final isMerchant = userId == data['merchantId'];

    if (isMerchant) {
      _push(
        RoutePath.sellerResponseviewscreen,
        extra: ['${data['requirementId'] ?? ''}', '${data['_id'] ?? ''}'],
      );
    } else {
      _push(
        RoutePath.myResponseBuyerpost,
        extra: ['${data['requirementId'] ?? ''}', '${data['_id'] ?? ''}'],
      );
    }
  }

  static Future<void> _handleStockQuotes(Map<String, dynamic> data) async {
    final userData = await SecureStorageService.getUserData();
    final userId = userData['_id'] ?? '';
    final isBuyer = userId == data['buyerId'];

    if (isBuyer) {
      _push(
        RoutePath.buyerResponseviewscreen,
        extra: ['${data['stockId'] ?? ''}', '${data['_id'] ?? ''}'],
      );
    } else {
      _push(
        RoutePath.myResponseSellerpost,
        extra: ['${data['stockId'] ?? ''}', '${data['_id'] ?? ''}'],
      );
    }
  }

  /// Safe push — waits for router to be ready
  static void _push(String path, {Object? extra}) {
    final router = appRouter;

    // If router isn't ready yet (cold start), defer by one frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        router.push(path, extra: extra);
      } catch (e) {
        debugPrint("FCM Nav: Navigation failed → $e");
      }
    });
  }
}

// import 'dart:io';

// import 'package:cashew_marketplace/core/providers/notification_provider.dart';
// import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
// import 'package:cashew_marketplace/core/router/router_setup.dart';
// import 'package:cashew_marketplace/core/services/device_service.dart';
// import 'package:cashew_marketplace/core/services/feature_services.dart';
// import 'package:cashew_marketplace/core/services/notification_handler.dart';
// import 'package:cashew_marketplace/core/utils/context_manager.dart';
// import 'package:cashew_marketplace/features/screens/notification/notification_history.dart';
// import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';

// class FCMService {
//   static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

//   /// Attach BuildContext for toast UI
//   // static void setContext(BuildContext context) {
//   //   _context = context;
//   // }

//   /// Initialize FCM
//   static Future<void> initialize() async {
//     await _requestPermissions();
//     await _initMessaging();
//   }

//   /// Request permissions (iOS only)
//   static Future<void> _requestPermissions() async {
//     await _fcm.requestPermission(alert: true, badge: true, sound: true);
//   }

//   /// Setup listeners & register token
//   static Future<void> _initMessaging() async {
//     final loggedIn = await SecureStorageService.getToken();
//     if (loggedIn == null) return;

//     // Ensure token exists and is synced
//     await _registerToken();

//     // Token refresh
//     _fcm.onTokenRefresh.listen((token) => _registerToken(token));

//     // Foreground notifications
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//     // Background notifications
//     FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

//     // Notification tap when app killed
//     final initialMessage = await _fcm.getInitialMessage();
//     if (initialMessage != null) _handleNotificationTap(initialMessage);

//     // Notification tap when app is in background
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
//   }

//   /// Register token (initial or refreshed)
//   static Future<void> _registerToken([String? newToken]) async {
//     try {
//       final token = newToken ?? await _fcm.getToken();
//       if (token == null || token.isEmpty) {
//         debugPrint("FCM: Token is null or empty");
//         return;
//       }

//       debugPrint("FCM: Token registered $token");

//       await _sendTokenToAPI(token);
//       await SecureStorageService.saveFCMToken(token);
//     } catch (e, stackTrace) {
//       debugPrint("FCM: Error while registering token");
//       debugPrint("FCM: Exception -> $e");
//       debugPrint("FCM: StackTrace -> $stackTrace");
//     }
//   }

//   /// Delete token (logout case)
//   static Future<void> deleteToken() async {
//     if (Platform.isIOS) {
//       final apns = await _fcm.getAPNSToken();
//       if (apns == null) {
//         debugPrint('FCM: APNS not ready, skipping deleteToken');
//         return;
//       }
//     }
//     await _fcm.deleteToken();
//     await SecureStorageService.saveFCMToken(null);
//   }

//   /// Foreground message
//   static void _handleForegroundMessage(RemoteMessage message) {
//     debugPrint("FCM: Foreground message ${message.messageId}");
//     _loadNotifications(message);
//     NotificationHandler.handleForegroundNotification(message);
//   }

//   /// Notification tap
//   static void _handleNotificationTap(RemoteMessage message) async{
//     debugPrint("FCM: Notification tapped ${message.messageId}");
//     _loadNotifications(message);

//      ContextManager contexts = ContextManager();
//         final context = contexts.getScreenContext(contexts.currentPage);
//         if (context == null) {
//           debugPrint("FCM: No context for navigation");
//           return;
//         }

//         final data = message.data;
//         final role = context.read<SwapUserProvider>().swapedUser;
//         SwapUserProvider swapProvider = context.read<SwapUserProvider>();
//         if (role != data['role']) {
//           swapProvider.toggleUser();
//         }
//         if (data['name'] == 'quotes') {
//           final userData = await SecureStorageService.getUserData();
//           final userId = userData['_id'] ?? '';
//           if (userId == data['merchantId']) {
//             swapProvider.toggleUser();
//             context.push(
//               RoutePath.sellerResponseviewscreen,
//               extra: ["${data['requirementId']}", "${data['_id']}"],
//             );
//             return;
//           } else {
//             //ok
//             context.push(
//               RoutePath.myResponseBuyerpost,
//               extra: ["${data['requirementId']}", "${data['_id']}"],
//             );
//             return;
//           }
//         }
//         if (data['name'] == '/stock') {
//           swapProvider.toggleUser();
//           context.push(
//             RoutePath.sellerResponseviewscreen,
//             extra: ["${data['requirementId']}", "${data['_id']}"],
//           );
//         }
//         if (data['name'] == 'stock_quotes') {
//           final userData = await SecureStorageService.getUserData();
//           final userId = userData['_id'] ?? '';
//           if (userId == data['buyerId']) {
//             swapProvider.toggleUser();
//             context.push(
//               RoutePath.buyerResponseviewscreen,
//               extra: ['${data['stockId']}', '${data['_id']}'],
//             );
//             return;
//           } else {
//             //ok
//             context.push(
//               RoutePath.myResponseSellerpost,
//               extra: ['${data['stockId']}', '${data['_id']}'],
//             );
//             return;
//           }
//         }
//         //ok
//         if (data['name'] == 'stocks') {
//           context.push(RoutePath.viewscreen, extra: data['_id']);
//           return;
//         }
//         //ok
//         if (data['name'] == 'requirements') {
//           context.push(RoutePath.sellerviewscreen, extra: data['_id']);
//           return;
//         }
//   }

//   /// Load all notifications (Provider)
//   static void _loadNotifications(RemoteMessage message) {
//     NotificationProvider? _notificationProvider = NotificationProvider();

//     try {
//       _notificationProvider.addNotification(message);
//     } catch (e) {
//       debugPrint("FCM: Error loading notifications → $e");
//     }
//   }

//   /// Send token to API
//   static Future<void> _sendTokenToAPI(String token) async {
//     try {
//       final oldToken = await SecureStorageService.getFCMToken();
//       if (oldToken == token) {
//         debugPrint("FCM: Token unchanged, not sending to API");
//         return;
//       }

//       final device = await DeviceService().deviceDetails();
//       final payload = {
//         "platform": "android",
//         "app_id": "Marketplace",
//         "imei": device.id,
//         "device_model": device.model,
//         "fcm_token": token,
//       };
//       ApiDioPostService apiService = ApiDioPostService();
//       final response = await apiService.getdata(
//         endpoint: "fcm/register",
//         data: payload,
//       );
//       await SecureStorageService.saveDocId(response['data']['doc_id'].toString());
//       // await _api.postMethodReturn("message/register", payload);
//     } catch (e) {
//       debugPrint("FCM: Error sending token to API → $e");
//     }
//   }

//   static Future<void> signOut() async {
//     ApiDioPostService apiService = ApiDioPostService();
//     String id = await SecureStorageService.getDocId() ?? "";
//     await apiService.getdata(endpoint: "fcm/logout/$id", data: {});
//     await deleteToken();
//   }

//   /// Save token after login
//   static Future<void> saveTokenAfterLogin() async {
//     final storedToken = await SecureStorageService.getFCMToken();
//     if (storedToken == null) return;
//     await _sendTokenToAPI(storedToken);
//   }

//   /// Public getter
//   static Future<String?> getToken() => _fcm.getToken();
// }

// /// Background handler
// @pragma('vm:entry-point')
// Future<void> _handleBackgroundMessage(RemoteMessage message) async {
//   debugPrint("FCM: Background message ${message.messageId}");

//   // Navigate to respective screen based on notification data
//   ContextManager contexts = ContextManager();
//         final context = contexts.getScreenContext(contexts.currentPage);
//         if (context == null) {
//           debugPrint("FCM: No context for navigation");
//           return;
//         }

//         final data = message.data;
//         final role = context.read<SwapUserProvider>().swapedUser;
//         if (role != data['role']) {
//           SwapUserProvider swapProvider = context.read<SwapUserProvider>();
//           swapProvider.toggleUser();
//         }
//         if (data['name'] == 'quotes') {
//           context.push(
//             RoutePath.myResponseBuyerpost,
//             extra: ["${data['requirementId']}", "${data['_id']}"],
//           );
//           return;
//         }
//         if (data['name'] == 'stock_quotes') {
//           context.push(
//             RoutePath.myResponseSellerpost,
//             extra: ['${data['stockId']}', '${data['_id']}'],
//           );
//           return;
//         }
//         if (data['name'] == 'stocks') {
//           context.push(RoutePath.viewscreen, extra: data['_id']);
//           return;
//         }
//         if (data['name'] == 'requirements') {
//           context.push(RoutePath.sellerviewscreen, extra: data['_id']);
//           return;
//         }

//   // if (route.isNotEmpty) {
//   //   debugPrint("FCM: Background notification has route: $route");
//   // }
// }

// class FcmServiceToken {
//   static String? _token;

//   static Future<String?> getToken() async {
//     if (_token != null) return _token;

//     _token = await FirebaseMessaging.instance.getToken();
//     return _token;
//   }
// }

import 'dart:io';
import 'package:cashew_marketplace/core/providers/notification_provider.dart';
import 'package:cashew_marketplace/core/providers/swap_user_provider.dart';
import 'package:cashew_marketplace/core/router/router_setup.dart';
import 'package:cashew_marketplace/core/services/device_service.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/core/services/notification/notification_handler.dart';
import 'package:cashew_marketplace/core/services/notification/notifiction_service.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  final data = message.data;
  if (data.isNotEmpty) {
    debugPrint("FCM: Background payload saved → ${message.messageId}");
  }
}

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static NotificationProvider? _notificationProvider;

  /// Call this once from the widget tree (e.g., in main app widget's initState)
  /// to wire up the singleton reference.
  static void registerNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

  /// Initialize FCM — call after user login
  static Future<void> initialize() async {
    await _requestPermissions();
    await _initMessaging();
  }

  static Future<void> _requestPermissions() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<void> _initMessaging() async {
    final loggedIn = await SecureStorageService.getToken();
    if (loggedIn == null) return;

    await _registerToken();

    _fcm.onTokenRefresh.listen((token) async {
      try {
        await _registerToken(token);
      } catch (e) {
        debugPrint("FCM: onTokenRefresh error → $e");
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // App was killed — tapped on notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("FCM: Cold start notification → ${initialMessage.messageId}");
      _addToNotificationProvider(initialMessage);
      await NotificationNavigationService.handle(initialMessage.data);
    }

    // App was BACKGROUNDED → user taps notification → app resumes
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      debugPrint("FCM: Background tap → ${message.messageId}");
      _addToNotificationProvider(message);
      await NotificationNavigationService.handle(message.data);
    });
  }

  /// Check for a notification persisted while the app was in background/killed

  static Future<void> _registerToken([String? newToken]) async {
    try {
      final token = newToken ?? await FcmServiceToken.getToken();
      if (token == null || token.isEmpty) {
        debugPrint("FCM: Token is null or empty");
        return;
      }
      debugPrint("FCM: Token → $token");
      await _sendTokenToAPI(token);
      await SecureStorageService.saveFCMToken(token);
    } catch (e, stackTrace) {
      debugPrint("FCM: Error registering token → $e");
      debugPrint("FCM: StackTrace → $stackTrace");
    }
  }

  static Future<void> deleteToken() async {
    if (Platform.isIOS) {
      final apns = await _fcm.getAPNSToken();
      if (apns == null) {
        debugPrint('FCM: APNS not ready, skipping deleteToken');
        return;
      }
    }
    await _fcm.deleteToken();
    FcmServiceToken.clearToken();
    await SecureStorageService.saveFCMToken(null);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint("FCM: Foreground message → ${message.messageId}");
    _addToNotificationProvider(message);
    NotificationHandler.handleForegroundNotification(message);
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    debugPrint("FCM: Notification tapped → ${message.messageId}");
    _addToNotificationProvider(message);
    await _navigateFromData(message.data);
  }

  static Future<void> _navigateFromData(Map<String, dynamic> data) async {
    if (data.isEmpty) return;

    final contextManager = ContextManager();
    final context = contextManager.getScreenContext(contextManager.currentPage);
    if (context == null) {
      debugPrint("FCM: No context available for navigation");
      return;
    }

    final swapProvider = context.read<SwapUserProvider>();
    final notificationRole = data['role'];

    if (notificationRole != null &&
        notificationRole != swapProvider.swapedUser) {
      // swapProvider.toggleUser();
    }

    final name = data['name'] as String?;
    if (name == null) return;

    switch (name) {
      case 'quotes':
        await _handleQuotesTap(context, data, swapProvider);
      case 'stock_quotes':
        await _handleStockQuotesTap(context, data, swapProvider);
      case '/stock':
        // Seller always views this
        context.push(
          RoutePath.sellerResponseviewscreen,
          extra: ['${data['requirementId'] ?? ''}', '${data['_id'] ?? ''}'],
        );
      case 'stocks':
        context.push(RoutePath.viewscreen, extra: '${data['_id']}');
      case 'requirements':
        context.push(RoutePath.sellerviewscreen, extra: '${data['_id']}');
      default:
        debugPrint("FCM: Unknown notification name → $name");
    }
  }

  static Future<void> _handleQuotesTap(
    BuildContext context,
    Map<String, dynamic> data,
    SwapUserProvider swapProvider,
  ) async {
    final userData = await SecureStorageService.getUserData();
    final userId = userData['_id'] ?? '';
    final isMerchant = userId == data['merchantId'];

    if (isMerchant) {
      // if (swapProvider.swapedUser != 'seller') swapProvider.toggleUser();
      context.push(
        RoutePath.sellerResponseviewscreen,
        extra: ['${data['requirementId'] ?? ''}', '${data['_id'] ?? ''}'],
      );
    } else {
      context.push(
        RoutePath.myResponseBuyerpost,
        extra: ['${data['requirementId'] ?? ''}', '${data['_id'] ?? ''}'],
      );
    }
  }

  static Future<void> _handleStockQuotesTap(
    BuildContext context,
    Map<String, dynamic> data,
    SwapUserProvider swapProvider,
  ) async {
    final userData = await SecureStorageService.getUserData();
    final userId = userData['_id'] ?? '';
    final isBuyer = userId == data['buyerId'];

    if (isBuyer) {
      // if (swapProvider.swapedUser != 'buyer') swapProvider.toggleUser();
      context.push(
        RoutePath.buyerResponseviewscreen,
        extra: ['${data['stockId'] ?? ''}', "${data['_id'] ?? ''}"],
      );
    } else {
      context.push(
        RoutePath.myResponseSellerpost,
        extra: ["${data['stockId'] ?? ''}", '${data['_id'] ?? ''}'],
      );
    }
  }

  static void _addToNotificationProvider(RemoteMessage message) {
    if (_notificationProvider == null) {
      debugPrint(
        "FCM: NotificationProvider not registered — call registerNotificationProvider()",
      );
      return;
    }
    try {
      _notificationProvider!.addNotification(message);
    } catch (e) {
      debugPrint("FCM: Error adding notification → $e");
    }
  }

  static Future<void> _sendTokenToAPI(String token) async {
    try {
      final oldToken = await SecureStorageService.getFCMToken();
      if (oldToken == token) {
        debugPrint("FCM: Token unchanged, skipping API call");
        return;
      }

      final device = await DeviceService().deviceDetails();
      final payload = {
        "platform": Platform.isIOS ? "ios" : "android",
        "app_id": "Marketplace",
        "imei": device.id,
        "device_model": device.model,
        "fcm_token": token,
      };

      final apiService = ApiDioPostService();
      final response = await apiService.getdata(
        endpoint: "fcm/register",
        data: payload,
      );
      await SecureStorageService.saveDocId(
        response['data']['doc_id'].toString(),
      );
    } catch (e) {
      debugPrint("FCM: Error sending token to API → $e");
    }
  }

  static Future<void> signOut() async {
    final apiService = ApiDioPostService();
    final id = await SecureStorageService.getDocId() ?? "";
    await apiService.getdata(endpoint: "fcm/logout/$id", data: {});
    await deleteToken();
  }

  static Future<void> saveTokenAfterLogin() async {
    final storedToken = await SecureStorageService.getFCMToken();
    if (storedToken == null) return;
    await _sendTokenToAPI(storedToken);
  }

  static Future<String?> getToken() => FcmServiceToken.getToken();
}

class FcmServiceToken {
  static String? _token;

  static void clearToken() {
    _token = null;
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;

    if (Platform.isIOS) {
      // On iOS, we must ensure the APNS token is available before calling getToken()
      // to avoid throwing a `firebase_messaging/apns-token-not-set` exception.
      String? apnsToken;
      int retryCount = 0;
      const maxRetries = 15; // Wait up to 3 seconds (15 * 200ms)

      while (retryCount < maxRetries) {
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken != null) {
            debugPrint("FcmServiceToken: APNS token is available.");
            break;
          }
        } catch (e) {
          debugPrint("FcmServiceToken: Error getting APNS token: $e");
        }
        await Future.delayed(const Duration(milliseconds: 200));
        retryCount++;
      }

      if (apnsToken == null) {
        debugPrint("FcmServiceToken: APNS token not set yet. Skipping FCM getToken to avoid exception.");
        return null;
      }
    }

    try {
      _token = await FirebaseMessaging.instance.getToken();
    } catch (e, stackTrace) {
      debugPrint("FcmServiceToken: Error getting FCM token: $e");
      debugPrint("FcmServiceToken: StackTrace: $stackTrace");
    }
    return _token;
  }
}

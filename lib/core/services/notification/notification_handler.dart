import 'package:hema_fruits/core/providers/notification_provider.dart';
import 'package:hema_fruits/core/providers/swap_user_provider.dart';
import 'package:hema_fruits/core/router/router_config.dart';
import 'package:hema_fruits/core/router/router_setup.dart';
import 'package:hema_fruits/core/services/filter_request.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/stream_refresher.dart';
import 'package:hema_fruits/features/screens/home/home_screen.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/toast_notification.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  static BuildContext? _context;

  factory NotificationHandler() {
    return _instance;
  }

  NotificationHandler._internal();

  /// Set the global context for showing toasts
  static void setContext(BuildContext context) {
    _context = context;
  }

  /// Clear the context
  static void clearContext() {
    _context = null;
  }

  static Future<void> fetchnotification() async {
    try {
      final userData = await SecureStorageService.getUserData();
      final userId = userData['_id'];

      final request = FilterRequest(userId: userId);
      final payload = request.getNotification();

      ContextManager contexts = ContextManager();
      _context = navigatorKey.currentContext;
      final provider = _context?.read<NotificationProvider>();

      await provider!.fetch(
        endpoint: "dataset/data/notifications",
        filterPayload: payload,
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  /// Handle foreground notification and show toast
  static void handleForegroundNotification(RemoteMessage message) async {
    if (_context == null) {
      debugPrint('NotificationHandler: No context available');
      return;
    }

    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    final data = message.data;

    // Determine notification type from data
    final type = await _getNotificationType(data);

    ContextManager contexts = ContextManager();
    _context = navigatorKey.currentContext;
    await fetchnotification();
    // await fetchdata(_context!, message);
    AppEvents.postRefreshController.add(null);
    _showToast(
      response: message,
      context: _context!,
      title: title,
      message: body,
      type: type,
    );

    debugPrint('NotificationHandler: Showing toast for ${message.messageId}');
  }

  // static Future<void> fetchdata(
  //   BuildContext context,
  //   RemoteMessage? response,
  // ) async {
  //   try {
  //     final context = navigatorKey.currentContext;
  //     if (context == null) {
  //       debugPrint("FCM: No context for navigation");
  //       return;
  //     }

  //     final data = response?.data ?? {};
  //     // final role = context.read<SwapUserProvider>().swapedUser;
  //     // SwapUserProvider swapProvider = context.read<SwapUserProvider>();
  //     // if (role != data!['role']) {
  //     //   // swapProvider.toggleUser();
  //     // }
  //     if (data['name'] == 'quotes') {
  //       final userData = await SecureStorageService.getUserData();
  //       final userId = userData['_id'] ?? '';
  //       if (userId == data['merchantId']) {
  //         // swapProvider.toggleUser();
  //         context.push(
  //           RoutePath.sellerResponseviewscreen,
  //           extra: ["${data['requirementId']}", "${data['_id']}"],
  //         );
  //         return;
  //       } else {
  //         //ok
  //         context.push(
  //           RoutePath.myResponseBuyerpost,
  //           extra: ["${data['requirementId']}", "${data['_id']}"],
  //         );
  //         return;
  //       }
  //     }
  //     if (data['name'] == '/stock') {
  //       // swapProvider.toggleUser();

  //     }
  //     if (data['name'] == 'stock_quotes') {
  //       final userData = await SecureStorageService.getUserData();
  //       final userId = userData['_id'] ?? '';
  //       if (userId == data['buyerId']) {
  //         // swapProvider.toggleUser();
  //         context.push(
  //           RoutePath.buyerResponseviewscreen,
  //           extra: ['${data['stockId']}', '${data['_id']}'],
  //         );
  //         return;
  //       } else {
  //         //ok
  //         context.push(
  //           RoutePath.myResponseSellerpost,
  //           extra: ['${data['stockId']}', '${data['_id']}'],
  //         );
  //         return;
  //       }
  //     }
  //     //ok
  //     if (data['name'] == 'stocks') {

  //     }
  //     //ok
  //     if (data['name'] == 'requirements') {

  //     }
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  // }

  /// Show toast notification
  static void _showToast({
    RemoteMessage? response,
    required BuildContext context,
    required String title,
    required String message,
    ToastType type = ToastType.general,
  }) {
    ToastService().show(
      context: context,
      title: title,
      message: message,
      type: type,
      actionLabel: 'View',
      onAction: () async {
        ContextManager contexts = ContextManager();
        final context = navigatorKey.currentContext;
        if (context == null) {
          debugPrint("FCM: No context for navigation");
          return;
        }

        final data = response?.data ?? {};
        // final role = context.read<SwapUserProvider>().swapedUser;
        // SwapUserProvider swapProvider = context.read<SwapUserProvider>();
        // if (role != data!['role']) {
        //   // swapProvider.toggleUser();
        // }
        if (data['name'] == 'quotes') {
          final userData = await SecureStorageService.getUserData();
          final userId = userData['_id'] ?? '';
          if (userId == data['merchantId']) {
            // swapProvider.toggleUser();
            context.push(
              RoutePath.sellerResponseviewscreen,
              extra: ["${data['requirementId']}", "${data['_id']}"],
            );
            return;
          } else {
            //ok
            context.push(
              RoutePath.myResponseBuyerpost,
              extra: ["${data['requirementId']}", "${data['_id']}"],
            );
            return;
          }
        }
        if (data['name'] == '/stock') {
          // swapProvider.toggleUser();
          context.push(
            RoutePath.sellerResponseviewscreen,
            extra: ["${data['requirementId']}", "${data['_id']}"],
          );
        }
        if (data['name'] == 'stock_quotes') {
          final userData = await SecureStorageService.getUserData();
          final userId = userData['_id'] ?? '';
          if (userId == data['buyerId']) {
            // swapProvider.toggleUser();
            context.push(
              RoutePath.buyerResponseviewscreen,
              extra: ['${data['stockId']}', '${data['_id']}'],
            );
            return;
          } else {
            //ok
            context.push(
              RoutePath.myResponseSellerpost,
              extra: ['${data['stockId']}', '${data['_id']}'],
            );
            return;
          }
        }
        //ok
        if (data['name'] == 'stocks') {
          context.push(RoutePath.viewscreen, extra: data['_id']);
          return;
        }
        //ok
        if (data['name'] == 'requirements') {
          context.push(RoutePath.sellerviewscreen, extra: data['_id']);
          return;
        }
      },
      duration: const Duration(seconds: 5),
    );
  }

  /// Determine toast type from notification data
  static Future<ToastType> _getNotificationType(
    Map<String, dynamic> data,
  ) async {
    final notificationType = data['name'] ?? 'general';

    switch (notificationType) {
      case 'stocks':
        return ToastType.stocks;
      case 'requirements':
        return ToastType.requirements;
      case 'quotes':
        return ToastType.quotes;
      case 'stock_quotes':
        final userData = await SecureStorageService.getUserData();
        final userId = userData['_id'] ?? '';
        if (userId == data['buyerId']) {
          return ToastType.res_stock_quotes;
        }
        return ToastType.stock_quotes;
      case '/stock':
        return ToastType.res_quotes;
      default:
        return ToastType.general;
    }
  }

  /// Show custom notification toast
  static void showNotification({
    required BuildContext context,
    required String title,
    required String message,
    ToastType type = ToastType.general,
  }) {
    _showToast(context: context, title: title, message: message, type: type);
  }
}

import 'package:hema_fruits/core/repositories/notification_repository.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:flutter/material.dart';

class NotificationProvider extends ChangeNotifier {
  List<dynamic> _notifications = [];
  bool isloading = false;

  List<dynamic> get notifications => _notifications;

  Future<void> fetch({
    required String endpoint,
    required Map<String, dynamic> filterPayload,
  }) async {
    try {
      isloading = true;
      notifyListeners();

      final response = await ApiDioPostService().getdata(
        endpoint: endpoint,
        data: filterPayload,
      );

      if (response['status'] == 200) {
        final List<dynamic> responseData = response['data'][0]['response'];
        _notifications = responseData;
        await NotificationRepository.instance.clearNotifications();
        await NotificationRepository.instance.saveNotifications(
          List<Map<String, dynamic>>.from(responseData),
        );
        if (responseData.isEmpty) {}
      }
    } catch (e) {
      debugPrintStack();
    } finally {
      _notifications = NotificationRepository.instance.getNotifications();
      isloading = false;
      notifyListeners();
    }
  }

  void addNotification(dynamic notification) async {
    if (notification != null) {
      _notifications.add(notification);
      await NotificationRepository.instance.saveNotification(
        Map<String, dynamic>.from(notification),
      );
      notifyListeners();
    }
  }

  void updateName(String name) {
    if (_notifications.isNotEmpty) {
      _notifications = _notifications
          .map((n) => n.copyWith(name: name))
          .toList();
      notifyListeners();
    }
  }

  void clearNotifications() async {
    _notifications.clear();
    await NotificationRepository.instance.clearNotifications();
    notifyListeners();
  }
}

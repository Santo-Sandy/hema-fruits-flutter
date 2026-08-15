import 'package:hema_fruits/shared/local_storage/hive_service.dart';
import 'package:hive/hive.dart';

class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  final HiveService _hive = HiveService.instance;

  static const String boxName = HiveBoxes.notifications;

  // Save Single Notification
  Future<void> saveNotification(Map<String, dynamic> notification) async {
    await _hive.put(
      boxName: boxName,
      key: notification['_id'],
      value: notification,
    );
  }

  // Save Multiple Notifications
  Future<void> saveNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    final Map<String, dynamic> data = {};

    for (final notification in notifications) {
      data[notification['_id']] = notification;
    }

    await _hive.putAll(boxName: boxName, values: data);
  }

  // Get Single Notification
  Map<String, dynamic>? getNotification(String notificationId) {
    final data = _hive.get<Map>(boxName: boxName, key: notificationId);

    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  // Get All Notifications
  List<Map<String, dynamic>> getNotifications() {
    final box = Hive.box(boxName);

    return box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Mark As Read
  Future<void> markAsRead(String notificationId) async {
    final notification = getNotification(notificationId);

    if (notification == null) return;

    notification['isRead'] = true;

    await saveNotification(notification);
  }

  // Mark All As Read
  Future<void> markAllAsRead() async {
    final notifications = getNotifications();

    for (final notification in notifications) {
      notification['isRead'] = true;

      await saveNotification(notification);
    }
  }

  // Delete Notification
  Future<void> deleteNotification(String notificationId) async {
    await _hive.delete(boxName: boxName, key: notificationId);
  }

  // Clear Notifications
  Future<void> clearNotifications() async {
    await _hive.clearBox(boxName: boxName);
  }

  // Unread Count
  int getUnreadCount() {
    return getNotifications().where((e) => e['isRead'] != true).length;
  }
}

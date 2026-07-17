import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const auth = 'auth_box';
  static const user = 'user_box';
  static const posts = 'posts_box';
  static const stock = 'stock_box';
  static const response = 'response_box';
  static const notifications = 'notifications_box';
  static const settings = 'settings_box';
  static const reports = 'reports_box';
  static const cache = 'cache_box';
  static const queue = 'queue_box';
}

class HiveKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const user = 'user';
}

class HiveService {
  HiveService._();

  static final HiveService instance = HiveService._();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox(HiveBoxes.auth),
      Hive.openBox(HiveBoxes.user),
      Hive.openBox(HiveBoxes.posts),
      Hive.openBox(HiveBoxes.stock),
      Hive.openBox(HiveBoxes.response),
      Hive.openBox(HiveBoxes.notifications),
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.reports),
      Hive.openBox(HiveBoxes.cache),
      Hive.openBox(HiveBoxes.queue),
    ]);

    _isInitialized = true;

    log("Hive Initialized");
  }

  Box _box(String boxName) {
    return Hive.box(boxName);
  }

  Future<void> put({
    required String boxName,
    required String key,
    required dynamic value,
  }) async {
    await _box(boxName).put(key, value);
  }

  Future<void> putAll({
    required String boxName,
    required Map<dynamic, dynamic> values,
  }) async {
    await _box(boxName).putAll(values);
  }

  T? get<T>({required String boxName, required String key}) {
    return _box(boxName).get(key);
  }

  List<dynamic> getAll({required String boxName}) {
    return _box(boxName).values.toList();
  }

  Future<void> delete({required String boxName, required String key}) async {
    await _box(boxName).delete(key);
  }

  Future<void> clearBox({required String boxName}) async {
    await _box(boxName).clear();
  }

  Future<void> clearAll() async {
    await Future.wait([
      _box(HiveBoxes.auth).clear(),
      _box(HiveBoxes.user).clear(),
      _box(HiveBoxes.posts).clear(),
      _box(HiveBoxes.stock).clear(),
      _box(HiveBoxes.response).clear(),
      _box(HiveBoxes.notifications).clear(),
      _box(HiveBoxes.settings).clear(),
      _box(HiveBoxes.reports).clear(),
      _box(HiveBoxes.cache).clear(),
      _box(HiveBoxes.queue).clear(),
    ]);
  }
}

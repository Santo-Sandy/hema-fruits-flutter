// core/services/fcm_lifecycle_observer.dart

import 'package:flutter/material.dart';

class FcmLifecycleObserver with WidgetsBindingObserver {
  static final FcmLifecycleObserver _instance = FcmLifecycleObserver._();
  factory FcmLifecycleObserver() => _instance;
  FcmLifecycleObserver._();

  void register() => WidgetsBinding.instance.addObserver(this);
  void unregister() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        // FCMService.consumePendingNotification();
      });
    }
  }
}

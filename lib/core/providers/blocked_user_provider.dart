import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/shared/models/blocked_user_model.dart';
import 'package:flutter/material.dart';

class BlockedUserProvider extends BaseProvider {
  List<BlockedUser> _blockedusers = [];
  bool isloading = false;

  List<BlockedUser> get blockedusers => _blockedusers;

  Future<void> fetch({
    required String endpoint,
    required Map<String, dynamic> filterPayload,
  }) async {
    try {
      isloading = true;
      final response = await ApiDioPostService().getdata(
        endpoint: endpoint,
        data: filterPayload,
      );

      if (response['status'] == 200) {
        final List<dynamic> responseData = response['data'][0]['response'];
        _blockedusers = responseData
            .map((json) => BlockedUser.fromJson(json as Map<String, dynamic>))
            .toList();
        await SettingsLocalRepository.instance.clearBlockedSettings();
        await SettingsLocalRepository.instance.saveBlockedSettings(
          responseData,
        );
      }
    } catch (e) {
      debugPrintStack();
    } finally {
      _blockedusers = SettingsLocalRepository.instance
          .getBlockedSettings()
          .map((json) => BlockedUser.fromJson(json as Map<String, dynamic>))
          .toList();
      isloading = false;
      notifyListeners();
    }
  }
}

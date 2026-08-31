import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/shared/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ColorProvider extends BaseProvider {
  bool isLoading = true;
  Map<String, dynamic> colors = {};

  Future<void> fetch({required String endpoint}) async {
    try {
      setLoading(true);
      isLoading = true;
      ApiDioGetService colorService = ApiDioGetService();

      final response = await colorService.getdata(endpoint: endpoint);

      Map<String, dynamic>? themeData;
      if (response is Map) {
        if (response['status'] == 200 && response['data'] is Map) {
          themeData = Map<String, dynamic>.from(response['data'] as Map);
        } else if (response['primaryColor'] != null) {
          themeData = Map<String, dynamic>.from(response);
        }
      }

      if (themeData != null) {
        colors = themeData;
        await SettingsLocalRepository.instance.clearThemeColors();
        await SettingsLocalRepository.instance.saveThemeColors(colors);
        AppColors.updateFromApi(colors);
      } else {
        final errMsg = (response is Map) ? (response['message'] ?? response['error'])?.toString() : null;
        setError(errMsg);
      }
    } catch (e) {
      debugPrintStack();
    }
    AppColors.updateFromApi(SettingsLocalRepository.instance.getThemeColors());
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }
}

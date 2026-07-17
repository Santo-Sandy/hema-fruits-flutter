import 'package:cashew_marketplace/core/providers/feature_providers.dart';
import 'package:cashew_marketplace/core/repositories/settings_repository.dart';
import 'package:cashew_marketplace/core/services/feature_services.dart';
import 'package:cashew_marketplace/shared/theme/app_colors.dart';
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

      if (response is Map && response['status'] == 200) {
        final responseData = response['data'];
        if (responseData is Map) {
          colors = Map<String, dynamic>.from(responseData);
          await SettingsLocalRepository.instance.clearThemeColors();
          await SettingsLocalRepository.instance.saveThemeColors(colors);
          AppColors.updateFromApi(colors);
        }
      } else {
        setError(response is Map ? response['message']?.toString() : null);
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

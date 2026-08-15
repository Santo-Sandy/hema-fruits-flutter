import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/repositories/user_repository.dart';
import 'package:hema_fruits/core/services/auth_service/auth_service.dart';
import 'package:hema_fruits/core/services/user_service.dart';
import 'package:hema_fruits/core/utils/context_manager.dart';
import 'package:hema_fruits/core/utils/initial_function.dart';
import 'package:hema_fruits/shared/local_storage/user_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileProvider extends BaseProvider {
  bool isLoading = false;
  Map<String, dynamic> userprofile = {};

  String country() {
    return userprofile['country'].toString();
  }

  String businessType() {
    return userprofile['registrationType'].toString();
  }

  Future<void> rewardfetch({required String endpoint}) async {
    setLoading(true);
    UserService userService = UserService();

    final response = await userService.getReward(endpoint: endpoint);

    if (response['status'] == 200) {
      final responseData = response['data'];
    } else {
      setError(response.statusMessage);
    }
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }

  Future<void> userprofilefetch({
    required String endpoint,
    required Map<String, dynamic> filterPayload,
  }) async {
    try {
      setLoading(true);
      UserService userService = UserService();

      final response = await userService.getUserProfile(
        endpoint: endpoint,
        data: filterPayload,
      );

      if (response['status'] == 200) {
        final responseData = response['data'][0]['response'];
        await SecureStorageService.saveUserProfileData(responseData[0]);
        await UserRepository.instance.clearMyProfile();
        await UserRepository.instance.saveMyProfile(
          Map<String, dynamic>.from(responseData[0]),
        );
        userprofile = Map<String, dynamic>.from(responseData[0]);
        if (userprofile['status'] == 'deactive' ||
            userprofile['role'] == 'admin') {
          final authservice = AuthService();
          await authservice.signOut();
          ContextManager contexts = ContextManager();
          final context = contexts.getScreenContext(contexts.currentPage);
          if (context == null) {
            debugPrint("FCM: No context for navigation");
            return;
          }
          bool login = false;
          try {
            login = await InitialFunction.layoutLogin();
          } catch (e) {
            debugPrintStack();
          }
          context.go('/login', extra: login);
        }
        notifyListeners();
      } else {
        setError(response.statusMessage);
      }
    } catch (e) {
      debugPrintStack();
    }
    userprofile = UserRepository.instance.getMyProfile() ?? {};
    setLoading(false);
    isLoading = false;
    notifyListeners();
  }
}

class Settingsprovider extends BaseProvider {
  Map<String, dynamic> settings = {};
  Future<Map<String, dynamic>> settingsfetch({
    required String endpoint,
    required Map<String, dynamic> filterPayload,
  }) async {
    try {
      setLoading(true);
      UserService userService = UserService();

      final response = await userService.getUserProfile(
        endpoint: endpoint,
        data: filterPayload,
      );

      if (response['status'] == 200) {
        final responseData = response['data'][0]['response'];

        // await SecureStorageService.saveUserProfileData(
        //   responseData[0],
        // ); //69bd3b3a4a4a2f760709b28e
        settings = Map<String, dynamic>.from(responseData[0]);
        await SettingsLocalRepository.instance.clearAdminSettings();
        await SettingsLocalRepository.instance.saveAdminSettings(settings);
        notifyListeners();
      } else {
        setError(response.statusMessage);
      }
    } catch (e) {
      debugPrintStack();
    } finally {
      settings = SettingsLocalRepository.instance.getAdminSettings();

      setLoading(false);
      notifyListeners();
    }
    return settings;
  }
}

import 'package:cashew_marketplace/core/services/auth_service/auth_service.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:flutter/material.dart';

class SwapUserProvider extends ChangeNotifier {
  String _swapedUser = 'both';
  String _productType = 'Both';
  bool isboth = true;
  String get productType => _productType;
  String get swapedUser => _swapedUser;
  Map<String, dynamic> userData = {};

  bool _showSwap = false;
  bool get showSwap => _showSwap;

  int _animationKey = 0;
  int get animationKey => _animationKey;

  /// Call this once after login / app start
  Future<void> initialize() async {
    userData = await SecureStorageService.getUserData();
    final userid = userData['_id'] ?? "";
    await getUser(userid);
    userData = await SecureStorageService.getUserData();
    final type = userData['businessType'] ?? '';
    final role = userData['role'] ?? '';

    _applyProfileRole(type: type, role: role, notify: true);
  }

  void updateRole(Map<String, dynamic> profile) {
    final type = profile['businessType'] ?? '';
    final role = profile['role'] ?? '';

    _applyProfileRole(type: type, role: role, notify: true);
  }

  void _applyProfileRole({
    required String type,
    required String role,
    required bool notify,
  }) {
    final previousProductType = _productType;
    final previousSwapedUser = _swapedUser;
    final previousShowSwap = _showSwap;

    if (type == 'RCN' || type == 'Kernel') {
      _productType = type;
    } else if (type == 'Both') {
      _productType = 'Both';
    }
    if (role == 'buyer' || role == 'processor') {
      _swapedUser = role;
      _showSwap = false;
    } else if (role == 'both') {
      _swapedUser = role;
    }

    final hasChanged =
        previousProductType != _productType ||
        previousSwapedUser != _swapedUser ||
        previousShowSwap != _showSwap;
    if (notify && hasChanged) notifyListeners();
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = "AUTH_TOKEN";
  static const String _docid = "DOCID";
  static const String _fcmTokenKey = "FCM_TOKEN";
  static const String _userData = "USERDATA";
  static const String _userProfileData = "USERDATA";
  static const String _profilestatus = "PROFILE_STATUS";
  static const String _companystatus = "COOMPANY_STATUS";

  // Save user data

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userData, value: jsonEncode(userData));
  }

  static Future<void> saveUserProfileData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userProfileData, value: jsonEncode(userData));
  }

  // Save token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> saveDocId(String? token) async {
    await _storage.write(key: _docid, value: token);
  }

  static Future<void> saveFCMToken(String? token) async {
    await _storage.write(key: _fcmTokenKey, value: token);
  }

  // Get token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<String?> getDocId() async {
    return await _storage.read(key: _docid);
  }

  static Future<String?> getFCMToken() async {
    return await _storage.read(key: _fcmTokenKey);
  }

  static Future<void> Saveprofilestatus(bool iscomplete) async {
    await _storage.write(key: _profilestatus, value: iscomplete.toString());
  }

  // Get profile status
  static Future<bool?> getprofilestatus() async {
    final status = await _storage.read(key: _profilestatus);
    return bool.tryParse(status ?? 'false');
  }

  static Future<void> companystatus(bool iscomplete) async {
    await _storage.write(key: _companystatus, value: iscomplete.toString());
  }

  // Get company status
  static Future<bool?> getcompanystatus() async {
    final status = await _storage.read(key: _companystatus);
    return bool.tryParse(status ?? 'false');
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final data = await _storage.read(key: _userData);
    if (data != null) {
      return jsonDecode(data);
    }
    return {};
  }

  static Future<Map<String, dynamic>> getUserProfileData() async {
    final data = await _storage.read(key: _userProfileData);
    if (data != null) {
      return jsonDecode(data);
    }
    return {};
  }

  // Referral Code
  static const String _referralCodeKey = "REFERRAL_CODE";

  static Future<void> saveReferralCode(String code) async {
    await _storage.write(key: _referralCodeKey, value: code);
  }

  static Future<String?> getReferralCode() async {
    return await _storage.read(key: _referralCodeKey);
  }

  static Future<void> clearReferralCode() async {
    await _storage.delete(key: _referralCodeKey);
  }

  // Clear everything
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

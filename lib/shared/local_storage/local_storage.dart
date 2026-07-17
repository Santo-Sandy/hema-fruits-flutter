import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  LocalStorage._();
  static final instance = LocalStorage._();

  late SharedPreferences _prefs;
  final _secure = const FlutterSecureStorage(
    // aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Keys
  static const _keyToken = 'token';
  static const _keyUser = 'user_json';
  static const _keyTheme = 'theme_mode';
  static const _keyOnboard = 'onboarding_done';
  static const _keyFcmToken = 'fcm_token';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Token (secure) ─────────────────────────────────────────
  Future<void> saveToken(String token) =>
      _secure.write(key: _keyToken, value: token);
  Future<String?> getToken() => _secure.read(key: _keyToken);
  Future<void> clearToken() => _secure.delete(key: _keyToken);

  // ── User JSON ──────────────────────────────────────────────
  Future<void> saveUser(String json) => _prefs.setString(_keyUser, json);
  String? getUserJson() => _prefs.getString(_keyUser);
  Future<void> clearUser() async => await _prefs.remove(_keyUser);

  // ── Theme ──────────────────────────────────────────────────
  Future<void> saveTheme(String value) => _prefs.setString(_keyTheme, value);
  String? getTheme() => _prefs.getString(_keyTheme);

  // ── Onboarding ─────────────────────────────────────────────
  Future<void> setOnboardingDone() => _prefs.setBool(_keyOnboard, true);
  bool isOnboardingDone() => _prefs.getBool(_keyOnboard) ?? false;

  // ── FCM Token ──────────────────────────────────────────────
  Future<void> saveFcmToken(String token) =>
      _prefs.setString(_keyFcmToken, token);
  String? getFcmToken() => _prefs.getString(_keyFcmToken);

  // ── Generic ────────────────────────────────────────────────
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool getBool(String key, {bool def = false}) => _prefs.getBool(key) ?? def;

  // ── Clear All ──────────────────────────────────────────────
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secure.deleteAll();
  }
}

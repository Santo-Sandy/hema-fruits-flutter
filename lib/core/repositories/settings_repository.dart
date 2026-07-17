import 'package:cashew_marketplace/shared/local_storage/hive_service.dart';

class SettingsLocalRepository {
  SettingsLocalRepository._();

  static final instance = SettingsLocalRepository._();

  final hive = HiveService.instance;

  static const boxName = HiveBoxes.settings;

  static const themeColorsKey = 'theme_colors';

  static const adminSettingsKey = 'admin_settings';
  static const blockedSettingsKey = 'blocked_settings';
  static const transactionSettingsKey = 'transaction_settings';
  static const dashboardSettingsKey = 'dashboard_settings';
  static const dashboardKernelSettingsKey = 'dashboard_Kernel_settings';
  static const languageSettingsKey = 'language_settings';
  static const originSettingsKey = 'origin_settings';
  static const countriesKey = 'countries_settings';

  // ==========================================
  // THEME COLORS
  // ==========================================

  Future<void> saveThemeColors(Map<String, dynamic> colors) async {
    await hive.put(boxName: boxName, key: themeColorsKey, value: colors);
  }

  Map<String, dynamic> getThemeColors() {
    return Map<String, dynamic>.from(
      hive.get<Map>(boxName: boxName, key: themeColorsKey) ?? {},
    );
  }

  Future<void> clearThemeColors() async {
    await hive.put(boxName: boxName, key: themeColorsKey, value: {});
  }

  // ==========================================
  // ADMIN SETTINGS
  // ==========================================

  Future<void> saveAdminSettings(Map<String, dynamic> settings) async {
    await hive.put(boxName: boxName, key: adminSettingsKey, value: settings);
  }

  Map<String, dynamic> getAdminSettings() {
    return Map<String, dynamic>.from(
      hive.get<Map>(boxName: boxName, key: adminSettingsKey) ?? {},
    );
  }

  Future<void> clearAdminSettings() async {
    await hive.put(boxName: boxName, key: adminSettingsKey, value: {});
  }

  // ==========================================
  // blocked SETTINGS
  // ==========================================

  Future<void> saveBlockedSettings(List<dynamic> settings) async {
    await hive.put(boxName: boxName, key: blockedSettingsKey, value: settings);
  }

  List<dynamic> getBlockedSettings() {
    return List<dynamic>.from(
      hive.get<List>(boxName: boxName, key: blockedSettingsKey) ?? [],
    );
  }

  Future<void> clearBlockedSettings() async {
    await hive.put(boxName: boxName, key: blockedSettingsKey, value: []);
  }

  // ==========================================
  // transaction SETTINGS
  // ==========================================

  Future<void> saveTransactionSettings(
    List<Map<String, dynamic>> settings,
  ) async {
    await hive.put(
      boxName: boxName,
      key: transactionSettingsKey,
      value: settings,
    );
  }

  List<Map<String, dynamic>> getTransactionSettings() {
    return List<Map<String, dynamic>>.from(
      hive.get<List>(boxName: boxName, key: transactionSettingsKey) ?? [],
    );
  }

  Future<void> clearTransactionSettings() async {
    await hive.put(boxName: boxName, key: transactionSettingsKey, value: []);
  }

  // ==========================================
  // dashboard SETTINGS
  // ==========================================
  Future<void> saveDasboardRCNSettings(List<dynamic> settings) async {
    await hive.put(
      boxName: boxName,
      key: dashboardSettingsKey,
      value: settings,
    );
  }

  List<dynamic> getDashboardRCNSettings() {
    return List<dynamic>.from(
      hive.get<List>(boxName: boxName, key: dashboardSettingsKey) ?? [],
    );
  }

  Future<void> clearDashboardRCNSettings() async {
    await hive.put(boxName: boxName, key: dashboardSettingsKey, value: []);
  }

  Future<void> saveDasboardKernelSettings(List<dynamic> settings) async {
    await hive.put(
      boxName: boxName,
      key: dashboardKernelSettingsKey,
      value: settings,
    );
  }

  List<dynamic> getDashboardKernelSettings() {
    return List<dynamic>.from(
      hive.get<List>(boxName: boxName, key: dashboardKernelSettingsKey) ?? [],
    );
  }

  Future<void> clearDashboardKernelSettings() async {
    await hive.put(
      boxName: boxName,
      key: dashboardKernelSettingsKey,
      value: [],
    );
  }
  // ==========================================
  // language SETTINGS
  // ==========================================

  Future<void> saveLanguageSettings(List<dynamic> settings) async {
    await hive.put(boxName: boxName, key: languageSettingsKey, value: settings);
  }

  List<dynamic> getLanguageSettings() {
    return List<dynamic>.from(
      hive.get<List>(boxName: boxName, key: languageSettingsKey) ?? [],
    );
  }

  Future<void> clearLanguageSettings() async {
    await hive.put(boxName: boxName, key: languageSettingsKey, value: []);
  }

  // ==========================================
  // Origin SETTINGS
  // ==========================================

  Future<void> saveOriginSettings(List<dynamic> settings) async {
    await hive.put(boxName: boxName, key: originSettingsKey, value: settings);
  }

  List<dynamic> getOriginSettings() {
    return List<dynamic>.from(
      hive.get<List>(boxName: boxName, key: originSettingsKey) ?? [],
    );
  }

  Future<void> clearOriginSettings() async {
    await hive.put(boxName: boxName, key: originSettingsKey, value: []);
  }

  // ==========================================
  // Countries SETTINGS
  // ==========================================

  Future<void> saveCountries(List<Map<dynamic, dynamic>> countries) async {
    await hive.put(boxName: boxName, key: countriesKey, value: countries);
  }

  List<Map<dynamic, dynamic>> getCountries() {
    return List<Map<dynamic, dynamic>>.from(
      hive.get<List>(boxName: boxName, key: countriesKey) ?? [],
    );
  }

  Future<void> clearCountries() async {
    await hive.put(boxName: boxName, key: countriesKey, value: []);
  }
}

import 'package:hema_fruits/shared/local_storage/hive_service.dart';
import 'package:hive/hive.dart';

class UserRepository {
  UserRepository._();

  static final UserRepository instance = UserRepository._();

  final HiveService hive = HiveService.instance;

  static const String boxName = HiveBoxes.user;

  static const String myProfileKey = 'my_profile';

  // ==========================
  // MY PROFILE
  // ==========================

  Future<void> saveMyProfile(Map<String, dynamic> profile) async {
    await hive.put(boxName: boxName, key: myProfileKey, value: profile);
  }

  Map<String, dynamic>? getMyProfile() {
    final data = hive.get<Map>(boxName: boxName, key: myProfileKey);

    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  Future<void> updateMyProfile(Map<String, dynamic> updates) async {
    final profile = getMyProfile();

    if (profile == null) return;

    profile.addAll(updates);

    await saveMyProfile(profile);
  }

  Future<void> clearMyProfile() async {
    await hive.delete(boxName: boxName, key: myProfileKey);
  }

  // ==========================
  // USERS
  // ==========================

  Future<void> saveUser(List<Map<String, dynamic>> user) async {
    await hive.put(
      boxName: boxName,
      key: user[0]['_id'].toString(),
      value: user[0],
    );
  }

  Future<void> saveUsers(List<Map<String, dynamic>> users) async {
    final data = <String, dynamic>{};

    for (final user in users) {
      data[user['_id'].toString()] = user;
    }

    await hive.putAll(boxName: boxName, values: data);
  }

  List<Map<String, dynamic>>? getUser(String userId) {
    final data = hive.get<Map>(boxName: boxName, key: userId);

    if (data == null) return null;

    return [Map<String, dynamic>.from(data)];
  }

  List<Map<String, dynamic>> getAllUsers() {
    final box = Hive.box(boxName);

    return box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['_id'] != null)
        .toList();
  }

  Future<void> updateUser(
    String userId,
    List<Map<String, dynamic>> updates,
  ) async {
    final user = getUser(userId);

    if (user == null) return;

    user.addAll(updates);

    await saveUser(user);
  }

  Future<void> deleteUser(String userId) async {
    await hive.delete(boxName: boxName, key: userId);
  }

  // ==========================
  // CLEAR
  // ==========================

  Future<void> clearUsers() async {
    await hive.clearBox(boxName: boxName);
  }
}

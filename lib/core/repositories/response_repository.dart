import 'package:hema_fruits/shared/local_storage/hive_service.dart';
import 'package:hive/hive.dart';

class ResponseRepository {
  ResponseRepository._();

  static final ResponseRepository instance = ResponseRepository._();

  final HiveService hive = HiveService.instance;

  static const String boxName = HiveBoxes.response;

  static const String responseKey = 'responses';

  static const String enquiryKey = 'enquiries';

  static const String myresponsesKey = 'myresponses';
  static const String receivedKey = 'received';

  // ==================================================
  // SAVE SINGLE ITEM
  // ==================================================

  Future<void> saveItem(Map<String, dynamic> item) async {
    await hive.put(boxName: boxName, key: item['_id'], value: item);
  }

  // ==================================================
  // SAVE MULTIPLE ITEMS
  // ==================================================

  Future<void> saveItems(List<Map<String, dynamic>> items) async {
    final Map<String, dynamic> data = {};

    for (final item in items) {
      data[item['_id']] = item;
    }

    await hive.putAll(boxName: boxName, values: data);
  }

  // ==================================================
  //  RESPONSES
  // ==================================================

  Future<void> saveResponses(List<Map<String, dynamic>> responses) async {
    await saveItems(responses);

    final ids = responses.map<String>((e) => e['_id'].toString()).toList();

    await hive.put(boxName: boxName, key: responseKey, value: ids);
  }

  List<String> getResponseIds() {
    return List<String>.from(
      hive.get<List>(boxName: boxName, key: responseKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getResponses() {
    return getItemsByIds(getResponseIds()).map(_stripOfflineFields).toList();
  }

  Future<void> clearResponses() async {
    await hive.put(boxName: boxName, key: responseKey, value: []);
  }

  // ==================================================
  // ENQUIRIES RESPONSES (ENQUIRIES)
  // ==================================================

  Future<void> saveEnquiries(List<Map<String, dynamic>> enquiries) async {
    await saveItems(enquiries);

    final ids = enquiries.map<String>((e) => e['_id'].toString()).toList();

    await hive.put(boxName: boxName, key: enquiryKey, value: ids);
  }

  List<String> getEnquiryIds() {
    return List<String>.from(
      hive.get<List>(boxName: boxName, key: enquiryKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getEnquiries() {
    return getItemsByIds(getEnquiryIds());
  }

  Future<void> clearEnquiries() async {
    await hive.put(boxName: boxName, key: enquiryKey, value: []);
  }

  // ==================================================
  // MY RESPONSES
  // ==================================================

  Future<void> addMyResponse(
    Map<String, dynamic> response,
    String postId,
  ) async {
    await saveItem(response);
    final raw = hive.get(boxName: boxName, key: myresponsesKey);
    final Map<String, dynamic> myResponses = raw is Map
        ? Map<String, dynamic>.from(raw)
        : {};
    final ids = List<String>.from(myResponses[postId] ?? []);
    if (!ids.contains(response['_id'].toString())) {
      ids.insert(0, response['_id'].toString());
    }
    myResponses[postId] = ids;
    await hive.put(boxName: boxName, key: myresponsesKey, value: myResponses);
  }

  Future<void> saveMyResponses(
    List<Map<String, dynamic>> responses,
    String userId,
  ) async {
    await saveItems(responses);

    final raw = hive.get(boxName: boxName, key: myresponsesKey);

    final Map<String, dynamic> myResponses = raw is Map
        ? Map<String, dynamic>.from(raw)
        : {};

    myResponses[userId] = responses.map((e) => e['_id'].toString()).toList();

    await hive.put(boxName: boxName, key: myresponsesKey, value: myResponses);
  }

  Map<String, dynamic> getMyResponsesMap() {
    final raw = hive.get(boxName: boxName, key: myresponsesKey);

    return raw is Map ? Map<String, dynamic>.from(raw) : {};
  }

  List<Map<String, dynamic>> getMyResponses(String userId) {
    final myResponses = getMyResponsesMap();
    final ids = List<String>.from(myResponses[userId] ?? []);
    return getItemsByIds(ids).map(_stripOfflineFields).toList();
  }

  Future<void> clearMyResponses(String userId) async {
    final myResponses = getMyResponsesMap();

    myResponses.remove(userId);

    await hive.put(boxName: boxName, key: myresponsesKey, value: myResponses);
  }

  // ==================================================
  // RECEIVED RESPONSES (ENQUIRIES)
  // ==================================================

  Future<void> saveReceivedResponses(
    List<Map<String, dynamic>> enquiries,
  ) async {
    await saveItems(enquiries);

    final ids = enquiries.map<String>((e) => e['_id'].toString()).toList();

    await hive.put(boxName: boxName, key: receivedKey, value: ids);
  }

  List<String> getReceivedResponseIds() {
    return List<String>.from(
      hive.get<List>(boxName: boxName, key: receivedKey) ?? [],
    );
  }

  List<Map<String, dynamic>> getReceivedResponses() {
    return getItemsByIds(
      getReceivedResponseIds(),
    ).map(_stripOfflineFields).toList();
  }

  Future<void> clearReceivedResponses() async {
    await hive.put(boxName: boxName, key: receivedKey, value: []);
  }

  // ==================================================
  // SINGLE ITEM
  // ==================================================

  Map<String, dynamic>? getItem(String id) {
    final data = hive.get<Map>(boxName: boxName, key: id);

    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  // ==================================================
  // COMMON GETTER
  // ==================================================

  List<Map<String, dynamic>> getItemsByIds(List<String> ids) {
    return ids.map(getItem).whereType<Map<String, dynamic>>().toList();
  }

  Map<String, dynamic> _stripOfflineFields(Map<String, dynamic> item) {
    if (!item.containsKey('offlineQueueId')) return item;
    final copy = Map<String, dynamic>.from(item)
      ..remove('offlineQueueId')
      ..remove('isOffline');
    return copy;
  }

  // ==================================================
  // UPDATE
  // ==================================================

  Future<void> updateItem(String id, Map<String, dynamic> updates) async {
    final item = getItem(id);

    if (item == null) return;

    item.addAll(updates);

    await saveItem(item);
  }

  // ==================================================
  // DELETE
  // ==================================================

  Future<void> deleteItem(String id) async {
    await hive.delete(boxName: boxName, key: id);
  }

  // ==================================================
  // CLEAR
  // ==================================================

  Future<void> clearAll() async {
    await hive.clearBox(boxName: boxName);
  }
}

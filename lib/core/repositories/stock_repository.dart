import 'package:cashew_marketplace/shared/local_storage/hive_service.dart';
import 'package:hive/hive.dart';

class StockRepository {
  StockRepository._();

  static final StockRepository instance = StockRepository._();

  final HiveService hive = HiveService.instance;

  static const String boxName = HiveBoxes.stock;

  // ==========================
  // SAVE SINGLE STOCK
  // ==========================

  Future<void> saveStock(Map<String, dynamic> stock) async {
    await hive.put(
      boxName: boxName,
      key: stock['_id'].toString(),
      value: stock,
    );
  }

  // ==========================
  // SAVE STOCKS
  // ==========================

  Future<void> saveStocks(List<Map<String, dynamic>> stocks) async {
    final stockMap = <String, dynamic>{};

    for (final stock in stocks) {
      final id = stock['_id']?.toString();

      if (id == null || id.isEmpty) {
        continue;
      }

      stockMap[id] = stock;
    }

    await hive.putAll(boxName: boxName, values: stockMap);
  }

  // ==========================
  // GET SINGLE STOCK
  // ==========================

  Map<String, dynamic>? getStock(String stockId) {
    final data = hive.get<Map>(boxName: boxName, key: stockId);

    if (data == null) return null;

    return Map<String, dynamic>.from(data);
  }

  // ==========================
  // GET ALL STOCKS
  // ==========================

  List<Map<String, dynamic>> getAllStocks() {
    final box = Hive.box(boxName);

    return box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) => e['_id'] != null)
        .toList();
  }

  // ==========================
  // UPDATE STOCK
  // ==========================

  Future<void> updateStock(String stockId, Map<String, dynamic> updates) async {
    final stock = getStock(stockId);

    if (stock == null) return;

    stock.addAll(updates);

    await saveStock(stock);
  }

  // ==========================
  // DELETE STOCK
  // ==========================

  Future<void> deleteStock(String stockId) async {
    await hive.delete(boxName: boxName, key: stockId);
  }

  // ==========================
  // CLEAR
  // ==========================

  Future<void> clearStocks() async {
    await hive.clearBox(boxName: boxName);
  }
}

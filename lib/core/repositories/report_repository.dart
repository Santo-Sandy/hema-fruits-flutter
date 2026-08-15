import 'package:hema_fruits/shared/local_storage/hive_service.dart';

class ReportRepository {
  ReportRepository._();

  static final ReportRepository instance = ReportRepository._();

  final HiveService hive = HiveService.instance;

  static const String boxName = HiveBoxes.reports;

  static const String reportsKey = 'reports';

  // ==========================================
  // SAVE REPORTS
  // ==========================================

  Future<void> saveReports(List<String> reports) async {
    await hive.put(boxName: boxName, key: reportsKey, value: reports);
  }

  // ==========================================
  // GET REPORTS
  // ==========================================

  List<String> getReports() {
    final data = hive.get<List>(boxName: boxName, key: reportsKey);

    if (data == null) return [];

    return data.map((e) => e.toString()).toList();
  }

  // ==========================================
  // ADD REPORT
  // ==========================================

  Future<void> addReport(String report) async {
    final reports = getReports();

    reports.add(report);

    await saveReports(reports);
  }

  // ==========================================
  // UPDATE REPORT
  // ==========================================

  Future<void> updateReport(
    String reportId,
    Map<String, dynamic> updates,
  ) async {
    final reports = getReports();

    final index = reports.indexWhere((e) => e == reportId);

    if (index == -1) return;

    reports[index] = reports[index].replaceFirst(
      reportId,
      updates['reason'] as String,
    );

    await saveReports(reports);
  }

  // ==========================================
  // DELETE REPORT
  // ==========================================

  Future<void> deleteReport(String reportId) async {
    final reports = getReports();

    reports.removeWhere((e) => e == reportId);

    await saveReports(reports);
  }

  // ==========================================
  // CLEAR
  // ==========================================

  Future<void> clearReports() async {
    await hive.clearBox(boxName: boxName);
  }
}

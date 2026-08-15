import 'package:hema_fruits/core/repositories/report_repository.dart';
import 'package:hema_fruits/core/repositories/settings_repository.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:hema_fruits/core/services/translate.dart';
import 'package:hema_fruits/core/services/user_service.dart';
import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String get currentLang => Translate.currentLang;

  Future<void> changeLanguage(String langCode) async {
    await Translate.load(langCode);
    notifyListeners(); // ← rebuilds every widget watching this provider
  }

  Future<void> loadSaved() async {
    await Translate.loadSaved();
    notifyListeners();
  }
}

class CountryProvider extends ChangeNotifier {
  late List<String> countries = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
  ];
  late List<String> dialnumbers = ['+91', '+1', '+7', '+809', '+44'];

  List<String> report = [
    'Fraud or scam',
    'Fake product',
    'Inappropriate content',
    'Spam',
    'Other',
  ];

  Future<void> fetchReports() async {
    try {
      final postService = ApiDioPostService();
      final response = await postService.getdata(
        endpoint: "entities/filter/quick_reports",
        data: {},
      );
      final responseData = response['data'];
      if (responseData is! List || responseData.isEmpty) {
        return;
      }
      final reportsData = responseData[0]['response'];
      if (reportsData is! List || reportsData.isEmpty) {
        return;
      }
      final reasons = reportsData[0]['reason'];

      final List<String> reports = reasons is List
          ? List<String>.from(reasons)
          : <String>[];
      await ReportRepository.instance.clearReports();
      await ReportRepository.instance.saveReports(reports);
      report = reports;
    } catch (e) {
      debugPrintStack();
    } finally {
      try {
        report = ReportRepository.instance.getReports();
      } catch (e) {
        debugPrintStack();
      }
      notifyListeners();
    }
  }

  Future<void> fetchCountry() async {
    try {
      UserService userService = UserService();
      final response = await userService.getcountry(
        endpoint: "entities/filter/countries",
        data: {},
      );
      final responseData = response['data'];
      if (responseData is! List || responseData.isEmpty) {
        return;
      }
      final countriesData = responseData[0]['response'];
      if (countriesData is! List || countriesData.isEmpty) {
        return;
      }
      final country = List<Map<String, dynamic>>.from(countriesData);

      await SettingsLocalRepository.instance.clearCountries();
      await SettingsLocalRepository.instance.saveCountries(country);
      countries = country.map((e) => "${e['flag']} ${e['name']}").toList();
      countries.sort();
      dialnumbers = country
          .map((e) => "${e['flag']} ${e['dialCode']}")
          .toList();
      dialnumbers.sort();
    } catch (e) {
      debugPrint('Error fetching country: $e');
    } finally {
      try {
        final country = SettingsLocalRepository.instance.getCountries();
        countries.sort();
        dialnumbers = country
            .map((e) => "${e['flag']} ${e['dialCode']}")
            .toList();
        dialnumbers.sort();
      } catch (e) {
        debugPrintStack();
      }
      notifyListeners();
    } // ← rebuilds every widget watching this provider
  }

  Future<void> loadSaved() async {
    await Translate.loadSaved();
    notifyListeners();
  }
}

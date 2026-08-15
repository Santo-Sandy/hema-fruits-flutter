import 'package:hema_fruits/core/providers/feature_providers.dart';
import 'package:hema_fruits/core/providers/language_provider.dart';
import 'package:hema_fruits/core/services/feature_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InitialFunction {
  Future<void> initialFunction(BuildContext context) async {
    try {
      getPosts(context);
      quickreport(context);
      Countryfetch(context);
    } catch (e) {
      debugPrintStack();
    }
  }

  static Future<bool> layoutLogin() async {
    ApiDioGetService api = ApiDioGetService();
    try {
      final dynamic response = await api.getdata(
        endpoint: "market-auth/checklayoutlogin",
      );

      if (response is Map<String, dynamic>) {
        if (response['status'] == 200) {
          if (response['data'] != null) {
            final login = response['data']['login'] ?? false;
            return login;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrintStack();
    }
    return false;
  }

  static Future<String?> getImageUrl() async {
    ApiDioGetService api = ApiDioGetService();
    try {
      final dynamic response = await api.getdata(endpoint: "market/imageurl");

      if (response is Map<String, dynamic>) {
        if (response['status'] == 200) {
          if (response['data'] != null) {
            final imageurl =
                response['data']['data'] ??
                "https://cerp.sgp1.digitaloceanspaces.com/";
            return imageurl;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrintStack();
    }
    return null;
  }

  Future<void> Countryfetch(BuildContext context) async {
    try {
      await context.read<CountryProvider>().fetchCountry();
    } catch (e) {
      debugPrintStack();
    }
  }

  Future<void> getPosts(BuildContext context) async {
    try {
      final provider = context.read<EditPostProvider>();
      await provider.fetch(
        endpoint: "entities/filter/origin",
        filterPayload: {},
      );
    } catch (e) {
      debugPrintStack();
    }
  }

  Future<void> quickreport(BuildContext context) async {
    try {
      await context.read<CountryProvider>().fetchReports();
    } catch (e) {
      debugPrintStack();
    } finally {}
  }
}

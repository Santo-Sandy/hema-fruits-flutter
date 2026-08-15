import 'package:hema_fruits/core/config/app_config.dart';
import 'package:dio/dio.dart';

class ApiService {
  ApiService._();
  static final instance = ApiService._();

  Dio get dio => AppConfig.instance.dio;

  // ── Convenience helpers ───────────────────────────────────────────────────
  static String parseError(DioException e) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          'Request failed (${e.response?.statusCode})';
    }

    return switch (e.type) {
      DioExceptionType.connectionTimeout =>
        'Connection timed out. Check your internet.',
      DioExceptionType.receiveTimeout =>
        'Server is taking too long. Try again.',
      DioExceptionType.connectionError => 'No internet connection.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}

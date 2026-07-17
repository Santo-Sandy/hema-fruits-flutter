import 'package:cashew_marketplace/core/services/auth_service/auth_service.dart';
import 'package:cashew_marketplace/core/services/notification/fcm_service.dart';
import 'package:cashew_marketplace/core/utils/context_manager.dart';
import 'package:cashew_marketplace/core/utils/initial_function.dart';
import 'package:cashew_marketplace/shared/local_storage/user_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

// ── Result wrapper ────────────────────────────────────────────────────────────
class ApiResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;

  bool get isSuccess => error == null;

  const ApiResult.success(this.data) : error = null, statusCode = null;
  const ApiResult.failure(this.error, [this.statusCode]) : data = null;
}

// ── API Service ───────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();
  static final instance = AppConfig._();

  late Dio _dio;
  static String _imageurl = "https://cerp.sgp1.digitaloceanspaces.com/";
  Dio get dio => _dio;

  static const _baseUrl = 'https://api.kajupro.com/';
  // static const _baseUrl = 'http://10.0.0.132:7002/';
  // static const _baseUrl = 'http://192.168.1.9:7002/';
  // static const _baseUrl = 'http://10.0.0.151:7004/';

  static String get imageurl => _imageurl;

  Future<void> init() async {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          "orgid": "TEAMALPHA",
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(),
      // _LogInterceptor(),
      PrettyDioLogger(requestBody: true, responseBody: true),
    ]);

    _imageurl =
        await InitialFunction.getImageUrl() ??
        "https://cerp.sgp1.digitaloceanspaces.com/";
  }

  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

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

// ── Interceptors ──────────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final fcmToken = await FcmServiceToken.getToken();
    if (fcmToken != null) {
      options.headers['fcmToken'] = fcmToken;
    }
    handler.next(options);
  }

  Future<void> logout() async {
    final authservice = AuthService();
    await authservice.signOut(isFcm: false);
    ContextManager contexts = ContextManager();
    final context = contexts.getScreenContext(contexts.currentPage);
    if (context == null) {
      debugPrint("FCM: No context for navigation");
      return;
    }
    bool login = false;
    try {
      login = await InitialFunction.layoutLogin();
    } catch (e) {
      debugPrintStack();
    }
    context.go('/login', extra: login);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await logout();
    }

    handler.next(err);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print(
      '✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}',
    );
    handler.next(err);
  }
}

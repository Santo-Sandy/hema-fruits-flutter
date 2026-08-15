import 'package:hema_fruits/core/services/api_service.dart';
import 'package:dio/dio.dart';

class UserService {
  final _dio = ApiService.instance.dio;

  Future<dynamic> getcountry({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);

      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } //b74b4669fce54e359fbc1e6a60cdde84
  }

  Future<dynamic> getUserProfile({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);

      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    } //b74b4669fce54e359fbc1e6a60cdde84
  } //69bd3b3a4a4a2f760709b28e

  Future<dynamic> getReward({required String endpoint}) async {
    try {
      final response = await _dio.post(endpoint);

      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      return error.response?.data["message"] ?? "Server error";
    } else {
      return error.message ?? "Network error";
    }
  }
}

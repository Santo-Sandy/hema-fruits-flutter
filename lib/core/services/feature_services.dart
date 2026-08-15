import 'package:hema_fruits/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';
import 'offline_queue_service.dart';

class ApiDioPostService {
  final _dio = ApiService.instance.dio;

  Future<dynamic> getdata({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'POST',
        endpoint: endpoint,
        data: data,
        actionType: 'post',
      );
      return {'status': 200, 'queued': true};
    }

    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'POST',
          endpoint: endpoint,
          data: data,
          actionType: 'post',
        );
        return {'status': 200, 'queued': true};
      }
      throw Exception(_handleError(e));
    }
  }

  Future<dynamic> deletedata({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'DELETE',
        endpoint: endpoint,
        data: data,
        actionType: 'delete',
      );
      return {'status': 200, 'queued': true};
    }

    try {
      final response = await _dio.delete(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'DELETE',
          endpoint: endpoint,
          data: data,
          actionType: 'delete',
        );
        return {'status': 200, 'queued': true};
      }
      throw Exception(_handleError(e));
    }
  }

  Future<dynamic> view({
    required String endpoint,
    Map<String, dynamic>? data,
  }) async {
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'POST',
        endpoint: endpoint,
        data: data,
        actionType: 'view',
      );
      return {'status': 200, 'queued': true};
    }

    Response response;
    try {
      if (data != null) {
        response = await _dio.post(endpoint, data: data);
      } else {
        response = await _dio.post(endpoint);
      }

      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'POST',
          endpoint: endpoint,
          data: data,
          actionType: 'view',
        );
        return {'status': 200, 'queued': true};
      }
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

class ApiDioGetService {
  final _dio = ApiService.instance.dio;

  Future<dynamic> getdata({required String endpoint}) async {
    try {
      final response = await _dio.get(endpoint);

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

class ApiDioPutService {
  final _dio = ApiService.instance.dio;

  Future<dynamic> getdata({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'PUT',
        endpoint: endpoint,
        data: data,
        actionType: 'update',
      );
      return {'status': 200, 'queued': true};
    }

    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'PUT',
          endpoint: endpoint,
          data: data,
          actionType: 'update',
        );
        return {'status': 200, 'queued': true};
      }
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

class PostService {
  final _dio = ApiService.instance.dio;
  Future<ApiResult<dynamic>> dynamicPost({
    required String collectionName,
    required String queryType,
    required Map<String, dynamic> data,
    String? requestId,
  }) async {
    final endpoint = '/capitalmarket/$collectionName/$queryType';

    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'POST',
        endpoint: endpoint,
        data: data,
        actionType: 'dynamicPost',
        id: requestId,
      );
      return const ApiResult.success({'queued': true});
    }

    try {
      final res = await _dio.post(endpoint, data: data);
      return ApiResult.success(res.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'POST',
          endpoint: endpoint,
          data: data,
          actionType: 'dynamicPost',
        );
        return const ApiResult.success({'queued': true});
      }
      return ApiResult.failure(ApiService.parseError(e));
    }
  }

  Future<ApiResult<dynamic>> dynamicUpdate({
    required String collectionName,
    required String id,
    required Map<String, dynamic> data,
    String? requestId,
  }) async {
    final endpoint = '/capitalmarket/$collectionName/$id';
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'PUT',
        endpoint: endpoint,
        data: data,
        actionType: 'dynamicUpdate',
        id: requestId,
      );
      return const ApiResult.success({'queued': true});
    }

    try {
      final res = await _dio.put(endpoint, data: data);
      return ApiResult.success(res.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'PUT',
          endpoint: endpoint,
          data: data,
          actionType: 'dynamicUpdate',
        );
        return const ApiResult.success({'queued': true});
      }
      return ApiResult.failure(ApiService.parseError(e));
    }
  }

  Future<ApiResult<dynamic>> dynamicPutUpdate({
    required String collectionName,
    required String id,
    required Map<String, dynamic> data,
    String? requestId,
  }) async {
    final endpoint = '/entities/$collectionName/$id';
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'PUT',
        endpoint: endpoint,
        data: data,
        actionType: 'dynamicPutUpdate',
        id: requestId,
      );
      return const ApiResult.success({'queued': true});
    }

    try {
      final res = await _dio.put(endpoint, data: data);
      return ApiResult.success(res.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'PUT',
          endpoint: endpoint,
          data: data,
          actionType: 'dynamicPutUpdate',
        );
        return const ApiResult.success({'queued': true});
      }
      return ApiResult.failure(ApiService.parseError(e));
    }
  }

  Future<dynamic> getPosts({
    required String endpoint,
    required Map<String, dynamic> data,
    //Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        //queryParameters: queryParams ?? {},
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<Map<String, dynamic>> getById({
    required String collectionName,
    required String id,
  }) async {
    try {
      final response = await _dio.get("entities/$collectionName/$id");

      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<dynamic> submitResponse({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParams,
  }) async {
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'POST',
        endpoint: endpoint,
        data: data,
        queryParameters: queryParams,
        actionType: 'submitResponse',
      );
      return {'status': 200, 'queued': true};
    }

    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        queryParameters: queryParams,
      );

      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'POST',
          endpoint: endpoint,
          data: data,
          queryParameters: queryParams,
          actionType: 'submitResponse',
        );
        return {'status': 200, 'queued': true};
      }
      throw Exception(_handleError(e));
    }
  }

  Future<dynamic> loadResponse({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);
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

class BiddingAndResponseService {
  final _dio = ApiService.instance.dio;

  Future<ApiResult<dynamic>> submitBiddings({
    required String collectionName,
    required Map<String, dynamic> data,
  }) async {
    final endpoint = '/capitalmarket/$collectionName';
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'POST',
        endpoint: endpoint,
        data: data,
        actionType: 'submitBiddings',
      );
      return const ApiResult.success({'queued': true});
    }

    try {
      final res = await _dio.post(endpoint, data: data);
      return ApiResult.success(res.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'POST',
          endpoint: endpoint,
          data: data,
          actionType: 'submitBiddings',
        );
        return const ApiResult.success({'queued': true});
      }
      return ApiResult.failure(ApiService.parseError(e));
    }
  }

  Future<dynamic> getBidResponse({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);
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

class ResponseService {
  final _dio = ApiService.instance.dio;

  Future<dynamic> getResponse({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future<dynamic> setStatus({
    required String endpoint,
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParams,
  }) async {
    if (await OfflineQueueService.instance.isOnline() == false) {
      await OfflineQueueService.instance.queueRequest(
        method: 'PUT',
        endpoint: endpoint,
        data: data,
        queryParameters: queryParams,
        actionType: 'setStatus',
      );
      return {'status': 200, 'queued': true};
    }

    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParams,
      );
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        await OfflineQueueService.instance.queueRequest(
          method: 'PUT',
          endpoint: endpoint,
          data: data,
          queryParameters: queryParams,
          actionType: 'setStatus',
        );
        return {'status': 200, 'queued': true};
      }
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

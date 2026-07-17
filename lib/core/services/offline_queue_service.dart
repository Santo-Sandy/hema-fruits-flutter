import 'dart:async';

import 'package:cashew_marketplace/core/services/api_service.dart';
import 'package:cashew_marketplace/shared/local_storage/hive_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class QueuedApiRequest {
  final String id;
  final String method;
  final String endpoint;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final DateTime createdAt;
  final String? actionType;

  QueuedApiRequest({
    required this.id,
    required this.method,
    required this.endpoint,
    this.data,
    this.queryParameters,
    required this.createdAt,
    this.actionType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'endpoint': endpoint,
      'data': data,
      'queryParameters': queryParameters,
      'createdAt': createdAt.toIso8601String(),
      'actionType': actionType,
    };
  }

  factory QueuedApiRequest.fromJson(Map<dynamic, dynamic> json) {
    return QueuedApiRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      endpoint: json['endpoint'] as String,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      queryParameters: json['queryParameters'] != null
          ? Map<String, dynamic>.from(json['queryParameters'] as Map)
          : null,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      actionType: json['actionType'] as String?,
    );
  }
}

class OfflineQueueService {
  OfflineQueueService._();

  static final OfflineQueueService instance = OfflineQueueService._();

  final HiveService _hive = HiveService.instance;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _initialized = false;
  static const String _queueKey = 'offline_queue';

  // Action types that are visible in the UI banner and queue list screen.
  static const _visibleTypes = {
    'dynamicPost',
    'submitResponse',
    'updateProfile',
  };

  static bool isVisible(QueuedApiRequest r) {
    return _visibleTypes.contains(r.actionType);
  }

  // Fired after the queue is fully flushed (all pending requests processed).
  // Listeners (e.g. providers) should refresh their data when this fires.
  static final ValueNotifier<int> onQueueFlushed = ValueNotifier(0);

  // Notifies UI about active upload state: (isUploading, pendingCount).
  static final ValueNotifier<({bool uploading, int count})> uploadState =
      ValueNotifier((uploading: false, count: 0));

  // Increments whenever items are added to or removed from the queue.
  // UI widgets can listen to this to refresh the pending count badge.
  static final ValueNotifier<int> queueChanged = ValueNotifier(0);

  Future<void> init() async {
    if (_initialized) return;
    _subscription = _connectivity.onConnectivityChanged.listen((
      connectivityResult,
    ) async {
      if (connectivityResult != ConnectivityResult.none) {
        await processQueue();
      }
    });
    _initialized = true;

    if (await isOnline()) {
      await processQueue();
    }
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<List<QueuedApiRequest>> getPendingRequests() async {
    final items = _hive.get<List>(boxName: HiveBoxes.queue, key: _queueKey);
    if (items == null) return [];

    return items
        .whereType<Map<dynamic, dynamic>>()
        .map(QueuedApiRequest.fromJson)
        .toList();
  }

  /// Synchronous version — reads directly from the Hive cache.
  /// Safe to call from build/ValueListenableBuilder without async.
  List<QueuedApiRequest> getPendingRequestsSync() {
    final items = _hive.get<List>(boxName: HiveBoxes.queue, key: _queueKey);
    if (items == null) return [];
    return items
        .whereType<Map<dynamic, dynamic>>()
        .map(QueuedApiRequest.fromJson)
        .toList();
  }

  Future<bool> queueRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    String? actionType,
    String? id,
  }) async {
    if (await isOnline()) return false;

    final requestId =
        id ?? '${DateTime.now().microsecondsSinceEpoch}_${endpoint.hashCode}';
    final queuedData = data != null ? Map<String, dynamic>.from(data) : null;

    if (queuedData != null) {
      queuedData['offlineQueueId'] = queuedData['offlineQueueId'] ?? requestId;
      queuedData['_id'] = queuedData['_id'] ?? requestId;
    }

    final request = QueuedApiRequest(
      id: requestId,
      method: method,
      endpoint: endpoint,
      data: queuedData,
      queryParameters: queryParameters,
      createdAt: DateTime.now().toUtc(),
      actionType: actionType,
    );

    final current = await getPendingRequests();

    // For favorite actions: deduplicate by endpoint — keep only the latest toggle.
    if (endpoint.contains('/favorite')) {
      final updated = current.where((r) => r.endpoint != endpoint).toList();
      updated.add(request);
      await _hive.put(
        boxName: HiveBoxes.queue,
        key: _queueKey,
        value: updated.map((e) => e.toJson()).toList(),
      );
      queueChanged.value++;
      return true;
    }

    current.add(request);
    await _hive.put(
      boxName: HiveBoxes.queue,
      key: _queueKey,
      value: current.map((e) => e.toJson()).toList(),
    );
    queueChanged.value++;
    return true;
  }

  Future<void> removeRequest(String id) async {
    final current = await getPendingRequests();
    final remaining = current.where((item) => item.id != id).toList();
    await _hive.put(
      boxName: HiveBoxes.queue,
      key: _queueKey,
      value: remaining.map((e) => e.toJson()).toList(),
    );
    queueChanged.value++;
  }

  Future<void> processQueue() async {
    if (!await isOnline()) return;

    final pending = await getPendingRequests();
    if (pending.isEmpty) return;

    final visibleCount = pending.where(isVisible).length;
    if (visibleCount > 0) {
      uploadState.value = (uploading: true, count: visibleCount);
    }

    bool anyProcessed = false;
    for (final request in pending) {
      try {
        await _executeRequest(request);
        await removeRequest(request.id);
        anyProcessed = true;
      } on DioException catch (e) {
        if (_isConnectionError(e)) {
          break;
        }
        await removeRequest(request.id);
        anyProcessed = true;
      } catch (_) {
        await removeRequest(request.id);
        anyProcessed = true;
      }
    }

    uploadState.value = (uploading: false, count: 0);

    if (anyProcessed) {
      onQueueFlushed.value++;
    }
  }

  /// Execute a single queued request by id. Returns the Dio [Response]
  /// when successfully executed, or null if the device is offline or request
  /// is not found. On success the queued item is removed from the queue.
  Future<Response<dynamic>?> executeRequestById(String id) async {
    if (!await isOnline()) return null;

    final pending = await getPendingRequests();
    QueuedApiRequest? request;
    try {
      request = pending.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }

    try {
      final resp = await _executeRequest(request);
      await removeRequest(id);
      return resp;
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        return null;
      }
      await removeRequest(id);
      rethrow;
    } catch (_) {
      await removeRequest(id);
      rethrow;
    }
  }

  Future<Response<dynamic>> _executeRequest(QueuedApiRequest request) async {
    final dio = ApiService.instance.dio;
    final data = request.data != null
        ? (Map<String, dynamic>.from(request.data!)
            ..remove('offlineQueueId')
            ..remove('_id'))
        : null;

    switch (request.method.toUpperCase()) {
      case 'POST':
        return await dio.post(
          request.endpoint,
          data: data,
          queryParameters: request.queryParameters,
        );
      case 'PUT':
        return await dio.put(
          request.endpoint,
          data: data,
          queryParameters: request.queryParameters,
        );
      case 'DELETE':
        return await dio.delete(
          request.endpoint,
          data: data,
          queryParameters: request.queryParameters,
        );
      default:
        throw ArgumentError('Unsupported queued method: ${request.method}');
    }
  }

  bool _isConnectionError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}

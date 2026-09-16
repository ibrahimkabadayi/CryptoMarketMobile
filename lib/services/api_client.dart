import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';

/// Dio-based HTTP client for communicating with the API Gateway.
/// Mirrors: frontend/src/api/axios.ts
///
/// Features:
/// - Automatic JWT Bearer token injection
/// - Idempotency-Key header helper
/// - Response error logging
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;
  static const _uuid = Uuid();

  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseURL: AppConstants.apiBaseUrl,
        headers: {'Content-Type': 'application/json'},
        connectTimeout: const Duration(milliseconds: AppConstants.requestTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.requestTimeout),
      ),
    );

    // Request interceptor: attach Bearer token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) {
          debugPrint(
              'API Error: ${error.response?.statusCode} - ${error.requestOptions.path}');
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// Returns headers with a unique Idempotency-Key for financial operations.
  static Map<String, String> get idempotencyHeaders => {
    'Idempotency-Key': _uuid.v4(),
  };
}

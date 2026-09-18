import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/limit_order_models.dart';
import 'api_client.dart';

/// Limit Order API service communicating with backend via gateway.
/// Mirrors: frontend/src/api/limitOrderApi.ts
class LimitOrderApi {
  final ApiClient _apiClient;
  static const _uuid = Uuid();

  LimitOrderApi(this._apiClient);

  /// Fetch all limit orders for the authenticated user.
  Future<List<LimitOrderDto>> getAll() async {
    final response = await _apiClient.dio.get(
      '/api/limit-orders',
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
    return (response.data as List)
        .map((e) => LimitOrderDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch a single limit order by ID.
  Future<LimitOrderDto> getById(String id) async {
    final response = await _apiClient.dio.get(
      '/api/limit-orders/$id',
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
    return LimitOrderDto.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create a new limit order with idempotency key.
  Future<void> create(CreateLimitOrderRequest req) async {
    await _apiClient.dio.post(
      '/api/limit-orders',
      data: req.toJson(),
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
  }

  /// Update an active limit order.
  Future<void> update(String id, UpdateLimitOrderRequest req) async {
    await _apiClient.dio.patch(
      '/api/limit-orders/$id',
      data: req.toJson(),
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
  }

  /// Cancel/delete a limit order.
  Future<void> delete(String id) async {
    await _apiClient.dio.delete(
      '/api/limit-orders/$id',
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
  }
}

import '../models/price_alert_models.dart';
import 'api_client.dart';

/// Price Alert API service communicating with backend via gateway.
/// Mirrors: frontend/src/api/priceAlertApi.ts
class PriceAlertApi {
  final ApiClient _apiClient;

  PriceAlertApi(this._apiClient);

  /// Create a price alert.
  Future<String> createAlert(CreatePriceAlertRequest request) async {
    final response = await _apiClient.dio.post(
      '/api/price-alerts',
      data: request.toJson(),
    );
    return response.data?['message']?.toString() ?? 'Alert created successfully';
  }

  /// Get active alerts for the authenticated user.
  Future<List<PriceAlertDto>> getActiveAlerts() async {
    final response = await _apiClient.dio.get('/api/price-alerts/active');
    return (response.data as List)
        .map((e) => PriceAlertDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all alerts (active + inactive) for the authenticated user.
  Future<List<PriceAlertDto>> getAllAlerts() async {
    final response = await _apiClient.dio.get('/api/price-alerts/all');
    return (response.data as List)
        .map((e) => PriceAlertDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Deactivate an active price alert.
  Future<void> deactivateAlert(String alertId) async {
    await _apiClient.dio.put('/api/price-alerts/$alertId/deactivate');
  }
}

import '../core/constants.dart';
import '../models/market_models.dart';
import 'api_client.dart';

/// Market API service communicating with Market.API via gateway.
/// Mirrors: frontend/src/api/marketApi.ts
class MarketApi {
  final ApiClient _apiClient;

  MarketApi(this._apiClient);

  /// Fetch all active cryptocurrency listings.
  Future<List<Coin>> getAllCoins() async {
    final response = await _apiClient.dio.get('/api/market');
    return (response.data as List)
        .map((e) => Coin.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch historical OHLCV candlestick data for a coin.
  Future<List<PriceHistory>> getPriceHistory(String symbol, String timeframe) async {
    final tf = AppConstants.timeframes.firstWhere(
      (t) => t['value'] == timeframe,
      orElse: () => AppConstants.timeframes[1], // default 24h
    );

    final response = await _apiClient.dio.get(
      '/api/market/$symbol/history',
      queryParameters: {
        'intervalMinutes': tf['intervalMinutes'],
        'hoursBack': tf['hoursBack'],
      },
    );

    final list = (response.data as List)
        .map((e) => PriceHistory.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return list;
  }

  /// Instant market purchase of a coin.
  Future<void> buyCoin(String symbol, double amount, double price) async {
    await _apiClient.dio.post(
      '/api/market/$symbol',
      data: {'amount': amount, 'price': price},
    );
  }
}

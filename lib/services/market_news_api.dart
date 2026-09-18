import '../models/market_news_models.dart';
import 'api_client.dart';

/// Market News API service communicating with backend via gateway.
/// Mirrors: frontend/src/api/marketNewsApi.ts
class MarketNewsApi {
  final ApiClient _apiClient;

  MarketNewsApi(this._apiClient);

  /// Get recent market-wide news articles.
  Future<List<MarketNews>> getRecentNews() async {
    final response = await _apiClient.dio.get('/api/market-news');
    return (response.data as List)
        .map((e) => MarketNews.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get news articles filtered by coin symbol.
  Future<List<MarketNews>> getNewsByCoin(String symbol) async {
    final response = await _apiClient.dio.get('/api/market-news/coin/$symbol');
    return (response.data as List)
        .map((e) => MarketNews.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

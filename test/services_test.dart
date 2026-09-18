import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/auth_api.dart';
import 'package:mobile/services/limit_order_api.dart';
import 'package:mobile/services/market_api.dart';
import 'package:mobile/services/market_news_api.dart';
import 'package:mobile/services/notification_api.dart';
import 'package:mobile/services/portfolio_api.dart';
import 'package:mobile/services/price_alert_api.dart';
import 'package:mobile/services/signalr_service.dart';

void main() {
  group('Service Layer Instantiation & Config', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    test('ApiClient configuration', () {
      expect(apiClient.dio.options.baseUrl.isNotEmpty, true);
      expect(apiClient.dio.options.headers['Content-Type'], 'application/json');
    });

    test('Idempotency headers format', () {
      final headers = ApiClient.idempotencyHeaders;
      expect(headers.containsKey('Idempotency-Key'), true);
      expect(headers['Idempotency-Key']!.isNotEmpty, true);
    });

    test('Service instances initialize with ApiClient', () {
      final authApi = AuthApi(apiClient: apiClient);
      final marketApi = MarketApi(apiClient);
      final portfolioApi = PortfolioApi(apiClient);
      final limitOrderApi = LimitOrderApi(apiClient);
      final marketNewsApi = MarketNewsApi(apiClient);
      final notificationApi = NotificationApi(apiClient);
      final priceAlertApi = PriceAlertApi(apiClient);

      expect(authApi.apiClient, apiClient);
      expect(marketApi, isNotNull);
      expect(portfolioApi, isNotNull);
      expect(limitOrderApi, isNotNull);
      expect(marketNewsApi, isNotNull);
      expect(notificationApi, isNotNull);
      expect(priceAlertApi, isNotNull);
    });

    test('SignalRService initialization and event registration', () {
      final signalR = SignalRService();
      expect(signalR.baseUrl.isNotEmpty, true);

      signalR.initCoreHubs();
      expect(signalR.getState(SignalRService.marketHub), SignalRConnectionState.disconnected);

      var eventFired = false;
      signalR.on('ReceivePriceUpdate', (data) {
        eventFired = true;
      });

      signalR.dispatchEvent('ReceivePriceUpdate', {'symbol': 'BTC', 'price': 69000.0});
      expect(eventFired, true);
    });
  });
}

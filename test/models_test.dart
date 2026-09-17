import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/auth_models.dart';
import 'package:mobile/models/limit_order_models.dart';
import 'package:mobile/models/market_models.dart';
import 'package:mobile/models/market_news_models.dart';
import 'package:mobile/models/notification_models.dart';
import 'package:mobile/models/portfolio_models.dart';
import 'package:mobile/models/price_alert_models.dart';

void main() {
  group('Auth Models', () {
    test('LoginRequest toJson', () {
      const req = LoginRequest(email: 'test@example.com', password: 'secretpassword');
      final json = req.toJson();
      expect(json['email'], 'test@example.com');
      expect(json['password'], 'secretpassword');
    });

    test('LoginResponse fromJson', () {
      final res = LoginResponse.fromJson({
        'token': 'jwt_token_123',
        'message': 'Success',
      });
      expect(res.token, 'jwt_token_123');
      expect(res.message, 'Success');
    });

    test('RegisterRequest toJson', () {
      const req = RegisterRequest(
        userName: 'crypto_trader',
        firstName: 'John',
        lastName: 'Doe',
        email: 'trader@example.com',
        password: 'Password123!',
      );
      final json = req.toJson();
      expect(json['userName'], 'crypto_trader');
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
      expect(json['email'], 'trader@example.com');
      expect(json['password'], 'Password123!');
    });
  });

  group('Market Models', () {
    test('Coin fromJson and resolvedIconUrl', () {
      final coin = Coin.fromJson({
        'name': 'Bitcoin',
        'symbol': 'BTC',
        'currentPrice': 68500.25,
        'percentChange': 3.45,
        'marketCap': 1300000000.0,
        'isCapped': true,
        'iconUrlPng': '/icons/btc.png',
        'priceChangeStatus': 'up',
      });

      expect(coin.name, 'Bitcoin');
      expect(coin.symbol, 'BTC');
      expect(coin.currentPrice, 68500.25);
      expect(coin.percentChange, 3.45);
      expect(coin.isCapped, true);
      expect(coin.priceChangeStatus, 'up');
      expect(coin.resolvedIconUrl.contains('btc.png'), true);
    });

    test('PriceHistory fromJson', () {
      final history = PriceHistory.fromJson({
        'symbol': 'ETH',
        'openPrice': 3400.0,
        'closePrice': 3550.0,
        'highPrice': 3600.0,
        'lowPrice': 3380.0,
        'volume': 15000.0,
        'timestamp': 1710000000,
      });

      expect(history.symbol, 'ETH');
      expect(history.openPrice, 3400.0);
      expect(history.closePrice, 3550.0);
      expect(history.highPrice, 3600.0);
      expect(history.lowPrice, 3380.0);
      expect(history.volume, 15000.0);
      expect(history.isUp, true);
    });
  });

  group('Portfolio Models', () {
    test('Dashboard fromJson', () {
      final dashboard = Dashboard.fromJson({
        'walletId': 'w-101',
        'address': '0x71C...B29',
        'fiatBalance': 25000.50,
        'totalInvestedValue': 78400.00,
        'assets': [
          {
            'symbol': 'BTC',
            'quantity': 1.25,
            'averageBuyPrice': 62000.0,
            'investedAmount': 77500.0,
          }
        ],
        'recentTransactions': [
          {
            'symbol': 'BTC',
            'amount': 0.5,
            'priceAtTransaction': 64000.0,
            'transactionType': 'buy',
          }
        ],
      });

      expect(dashboard.walletId, 'w-101');
      expect(dashboard.address, '0x71C...B29');
      expect(dashboard.fiatBalance, 25000.50);
      expect(dashboard.totalInvestedValue, 78400.00);
      expect(dashboard.assets.length, 1);
      expect(dashboard.assets.first.symbol, 'BTC');
      expect(dashboard.recentTransactions.length, 1);
      expect(dashboard.recentTransactions.first.isBuy, true);
    });
  });

  group('Limit Order Models', () {
    test('LimitOrderDto fromJson and isBuy', () {
      final order = LimitOrderDto.fromJson({
        'id': 'ord-001',
        'userId': 'usr-001',
        'walletId': 'w-101',
        'symbol': 'SOL',
        'targetPrice': 140.0,
        'amount': 10.0,
        'orderType': 1, // LimitOrderType.buy
        'status': 'Pending',
        'createdAt': '2026-03-10T12:00:00Z',
      });

      expect(order.id, 'ord-001');
      expect(order.symbol, 'SOL');
      expect(order.targetPrice, 140.0);
      expect(order.amount, 10.0);
      expect(order.isBuy, true);
    });
  });

  group('Notification & Price Alert Models', () {
    test('NotificationDto fromJson and copyWith', () {
      final notif = NotificationDto.fromJson({
        'id': 'notif-1',
        'userId': 'usr-001',
        'title': 'Price Alert Triggered',
        'message': 'BTC crossed \$68,000',
        'type': 'price_alert',
        'isRead': false,
        'createdAt': '2026-03-10T12:00:00Z',
      });

      expect(notif.title, 'Price Alert Triggered');
      expect(notif.isRead, false);

      final readNotif = notif.copyWith(isRead: true);
      expect(readNotif.isRead, true);
      expect(readNotif.id, notif.id);
    });

    test('PriceAlertDto fromJson and copyWith', () {
      final alert = PriceAlertDto.fromJson({
        'id': 'alt-1',
        'userId': 'usr-001',
        'symbol': 'BTC',
        'targetPrice': 70000.0,
        'isAbove': true,
        'isActive': true,
        'createdAt': '2026-03-10T12:00:00Z',
      });

      expect(alert.symbol, 'BTC');
      expect(alert.targetPrice, 70000.0);
      expect(alert.isAbove, true);
      expect(alert.isActive, true);

      final deactivated = alert.copyWith(isActive: false);
      expect(deactivated.isActive, false);
    });

    test('MarketNews fromJson', () {
      final news = MarketNews.fromJson({
        'title': 'Ethereum ETF Inflows Surge',
        'content': 'Institutional inflows into Ethereum funds reached new peaks this week.',
        'source': 'CryptoDesk',
        'relatedSymbols': ['ETH'],
        'publishedAt': '2026-03-10T12:00:00Z',
      });

      expect(news.title, 'Ethereum ETF Inflows Surge');
      expect(news.source, 'CryptoDesk');
      expect(news.relatedSymbols, ['ETH']);
    });
  });
}

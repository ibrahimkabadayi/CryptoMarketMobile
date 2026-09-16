/// Central configuration constants for the CryptoMarket mobile app.
class AppConstants {
  AppConstants._();

  // ── API ────────────────────────────────────────────────
  /// Base URL for the API Gateway.
  /// Android emulator uses 10.0.2.2 to reach host localhost.
  /// iOS simulator can use localhost directly.
  /// For web debugging, use localhost.
  static const String apiBaseUrl = 'http://10.0.2.2:5000';

  /// Request timeout in milliseconds.
  static const int requestTimeout = 10000;

  // ── SignalR Hub URLs (for future phase) ───────────────
  static const String marketHub = '/hubs/market';
  static const String portfolioHub = '/hubs/portfolio';
  static const String notificationsHub = '/hubs/notifications';
  static const String priceAlertsHub = '/hubs/price-alerts';

  // ── Secure Storage Keys ───────────────────────────────
  static const String tokenKey = 'jwt_token';

  // ── Timeframe Configurations ──────────────────────────
  static const List<Map<String, dynamic>> timeframes = [
    {'label': '1H', 'value': '1h', 'intervalMinutes': 1, 'hoursBack': 1},
    {'label': '24H', 'value': '1d', 'intervalMinutes': 15, 'hoursBack': 24},
    {'label': '7D', 'value': '7d', 'intervalMinutes': 60, 'hoursBack': 168},
    {'label': '1M', 'value': '30d', 'intervalMinutes': 240, 'hoursBack': 720},
  ];
}

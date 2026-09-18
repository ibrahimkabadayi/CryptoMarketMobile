import 'package:dio/dio.dart';
import '../models/portfolio_models.dart';
import 'api_client.dart';

/// Portfolio & Wallet API service communicating with Wallets.API via gateway.
/// Mirrors: frontend/src/api/portfolioApi.ts
class PortfolioApi {
  final ApiClient _apiClient;

  PortfolioApi(this._apiClient);

  /// Fetch full wallet dashboard with balances, assets, and transaction history.
  Future<Dashboard> getDashboard() async {
    final response = await _apiClient.dio.get('/api/wallets');
    return Dashboard.fromJson(response.data as Map<String, dynamic>);
  }

  /// Deposit fiat into user wallet.
  Future<void> deposit(String walletId, double amount) async {
    await _apiClient.dio.post(
      '/api/wallets/$walletId/transaction',
      data: {'amount': amount},
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
  }

  /// Withdraw fiat from user wallet.
  Future<void> withdraw(String walletId, double amount) async {
    await _apiClient.dio.patch(
      '/api/wallets/$walletId',
      data: {'amount': amount},
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
  }

  /// Buy coin asset from user wallet balance.
  Future<void> buyCoin(String walletId, String symbol, double amount, double price) async {
    await _apiClient.dio.post(
      '/api/wallets/$walletId/assets/$symbol',
      data: {'amount': amount, 'buyingPrice': price},
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
  }

  /// Sell coin asset to user wallet balance.
  Future<void> sellCoin(String walletId, String symbol, double amount, double price) async {
    await _apiClient.dio.patch(
      '/api/wallets/$walletId/assets/$symbol',
      data: {'amount': amount, 'price': price},
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
  }
}

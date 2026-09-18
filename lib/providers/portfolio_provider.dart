import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio_models.dart';
import '../services/portfolio_api.dart';
import 'auth_provider.dart';

/// Portfolio API service provider.
final portfolioApiProvider = Provider<PortfolioApi>(
  (ref) => PortfolioApi(ref.read(apiClientProvider)),
);

/// State for portfolio dashboard.
class PortfolioState {
  final Dashboard? dashboard;
  final bool isLoading;
  final String? errorMessage;

  const PortfolioState({
    this.dashboard,
    this.isLoading = false,
    this.errorMessage,
  });

  PortfolioState copyWith({
    Dashboard? dashboard,
    bool? isLoading,
    String? errorMessage,
  }) =>
      PortfolioState(
        dashboard: dashboard ?? this.dashboard,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final PortfolioApi _api;

  PortfolioNotifier(this._api) : super(const PortfolioState());

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dashboard = await _api.getDashboard();
      state = state.copyWith(dashboard: dashboard, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load portfolio dashboard.',
      );
    }
  }

  Future<bool> deposit(double amount) async {
    final walletId = state.dashboard?.walletId;
    if (walletId == null) return false;
    try {
      await _api.deposit(walletId, amount);
      await fetchDashboard();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> withdraw(double amount) async {
    final walletId = state.dashboard?.walletId;
    if (walletId == null) return false;
    try {
      await _api.withdraw(walletId, amount);
      await fetchDashboard();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> buyCoin(String symbol, double amount, double price) async {
    final walletId = state.dashboard?.walletId;
    if (walletId == null) return false;
    try {
      await _api.buyCoin(walletId, symbol, amount, price);
      await fetchDashboard();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sellCoin(String symbol, double amount, double price) async {
    final walletId = state.dashboard?.walletId;
    if (walletId == null) return false;
    try {
      await _api.sellCoin(walletId, symbol, amount, price);
      await fetchDashboard();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, PortfolioState>(
  (ref) => PortfolioNotifier(ref.read(portfolioApiProvider)),
);

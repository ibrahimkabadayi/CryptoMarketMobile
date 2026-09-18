import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_models.dart';
import '../services/market_api.dart';
import 'auth_provider.dart';

/// Market API service provider.
final marketApiProvider = Provider<MarketApi>(
  (ref) => MarketApi(ref.read(apiClientProvider)),
);

/// Market state
class MarketState {
  final List<Coin> coins;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  const MarketState({
    this.coins = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  MarketState copyWith({
    List<Coin>? coins,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) =>
      MarketState(
        coins: coins ?? this.coins,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  List<Coin> get filteredCoins {
    if (searchQuery.isEmpty) return coins;
    final q = searchQuery.toLowerCase();
    return coins
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.symbol.toLowerCase().contains(q))
        .toList();
  }
}

class MarketNotifier extends StateNotifier<MarketState> {
  final MarketApi _api;

  MarketNotifier(this._api) : super(const MarketState());

  Future<void> fetchCoins() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final coins = await _api.getAllCoins();
      state = state.copyWith(coins: coins, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not connect to the market server. Please try again.',
      );
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Real-time price update handler from SignalR.
  void updatePrice(PriceUpdateMessage update) {
    final updatedList = state.coins.map((coin) {
      if (coin.symbol == update.symbol) {
        final status = update.price > coin.currentPrice
            ? 'up'
            : update.price < coin.currentPrice
                ? 'down'
                : 'none';
        return coin.copyWith(
          currentPrice: update.price,
          percentChange: update.percentChange,
          marketCap: update.marketCap,
          priceChangeStatus: status,
        );
      }
      return coin;
    }).toList();

    state = state.copyWith(coins: updatedList);
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>(
  (ref) => MarketNotifier(ref.read(marketApiProvider)),
);

/// Price history state for coin detail charts
class PriceHistoryState {
  final List<PriceHistory> history;
  final bool isLoading;
  const PriceHistoryState({this.history = const [], this.isLoading = false});
}

class PriceHistoryNotifier extends StateNotifier<PriceHistoryState> {
  final MarketApi _api;

  PriceHistoryNotifier(this._api) : super(const PriceHistoryState());

  Future<void> fetchHistory(String symbol, String timeframe) async {
    state = const PriceHistoryState(isLoading: true);
    try {
      final list = await _api.getPriceHistory(symbol, timeframe);
      state = PriceHistoryState(history: list);
    } catch (_) {
      state = const PriceHistoryState();
    }
  }
}

final priceHistoryProvider =
    StateNotifierProvider<PriceHistoryNotifier, PriceHistoryState>(
  (ref) => PriceHistoryNotifier(ref.read(marketApiProvider)),
);

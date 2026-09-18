import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_news_models.dart';
import '../services/market_news_api.dart';
import 'auth_provider.dart';

/// Market News API provider.
final marketNewsApiProvider = Provider<MarketNewsApi>(
  (ref) => MarketNewsApi(ref.read(apiClientProvider)),
);

/// State for market news feed.
class MarketNewsState {
  final List<MarketNews> news;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedCoinSymbol;

  const MarketNewsState({
    this.news = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCoinSymbol,
  });

  MarketNewsState copyWith({
    List<MarketNews>? news,
    bool? isLoading,
    String? errorMessage,
    String? selectedCoinSymbol,
  }) =>
      MarketNewsState(
        news: news ?? this.news,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        selectedCoinSymbol: selectedCoinSymbol ?? this.selectedCoinSymbol,
      );
}

/// Market news state notifier mirroring frontend/src/stores/marketNewsStore.ts
class MarketNewsNotifier extends StateNotifier<MarketNewsState> {
  final MarketNewsApi _api;

  MarketNewsNotifier(this._api) : super(const MarketNewsState());

  /// Fetch latest market-wide news articles.
  Future<void> fetchRecentNews() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final news = await _api.getRecentNews();
      state = state.copyWith(news: news, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load market news reports.',
      );
    }
  }

  /// Fetch news articles for a specific coin.
  Future<void> fetchNewsByCoin(String symbol) async {
    state = state.copyWith(isLoading: true, errorMessage: null, selectedCoinSymbol: symbol);
    try {
      final news = await _api.getNewsByCoin(symbol);
      state = state.copyWith(news: news, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load news for $symbol.',
      );
    }
  }

  /// Add real-time news item from SignalR.
  void addNewsItem(MarketNews item) {
    if (state.selectedCoinSymbol == null ||
        item.relatedSymbols.contains(state.selectedCoinSymbol)) {
      state = state.copyWith(news: [item, ...state.news]);
    }
  }
}

final marketNewsProvider =
    StateNotifierProvider<MarketNewsNotifier, MarketNewsState>(
  (ref) => MarketNewsNotifier(ref.read(marketNewsApiProvider)),
);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../models/market_models.dart';
import 'widgets/shimmer_loading.dart';

/// Market API service provider.
final marketApiProvider = Provider<MarketApi>(
  (ref) => MarketApi(ref.read(apiClientProvider)),
);

class MarketApi {
  final ApiClient _apiClient;
  MarketApi(this._apiClient);

  Future<List<Coin>> getAllCoins() async {
    final response = await _apiClient.dio.get('/api/market');
    return (response.data as List)
        .map((e) => Coin.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

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
  }) => MarketState(
    coins: coins ?? this.coins,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  List<Coin> get filteredCoins {
    if (searchQuery.isEmpty) return coins;
    final q = searchQuery.toLowerCase();
    return coins.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.symbol.toLowerCase().contains(q)).toList();
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
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>(
  (ref) => MarketNotifier(ref.read(marketApiProvider)),
);

/// Market screen — coin list with search and stats.
/// Mirrors: frontend/src/views/MarketView.vue
class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch coins on first load
    Future.microtask(() => ref.read(marketProvider.notifier).fetchCoins());
  }

  @override
  Widget build(BuildContext context) {
    final market = ref.watch(marketProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Market ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextSpan(
                text: 'Overview',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppColors.voltGreen),
              ),
            ],
          ),
        ),
      ),
      body: market.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.voltGreen),
            )
          : market.errorMessage != null
              ? _buildError(context, market.errorMessage!)
              : _buildContent(context, market),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.error),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.errorDim,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('System Error',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: AppColors.error)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => ref.read(marketProvider.notifier).fetchCoins(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MarketState market) {
    final coins = market.filteredCoins;

    return RefreshIndicator(
      color: AppColors.voltGreen,
      backgroundColor: AppColors.cardBg,
      onRefresh: () => ref.read(marketProvider.notifier).fetchCoins(),
      child: CustomScrollView(
        slivers: [
          // ── Stats bar ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  _statItem(
                    context,
                    icon: Icons.generating_tokens_outlined,
                    label: 'Assets',
                    value: '${market.coins.length}',
                  ),
                  Container(width: 1, height: 40, color: AppColors.borderSubtle),
                  if (market.coins.isNotEmpty)
                    _statItem(
                      context,
                      icon: Icons.trending_up,
                      label: 'Top',
                      value: market.coins
                          .reduce((a, b) =>
                              a.currentPrice > b.currentPrice ? a : b)
                          .symbol,
                      valueColor: AppColors.voltGreen,
                    ),
                ],
              ),
            ),
          ),

          // ── Search ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (q) =>
                    ref.read(marketProvider.notifier).setSearch(q),
                decoration: const InputDecoration(
                  hintText: 'Search coins...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              ),
            ),
          ),

          // ── Coin list ─────────────────────────────────
          if (market.isLoading && market.coins.isEmpty)
            SliverList.builder(
              itemCount: 8,
              itemBuilder: (_, _) => const ShimmerListTile(),
            )
          else
            SliverList.builder(
              itemCount: coins.length,
              itemBuilder: (context, index) {
                final coin = coins[index];
                return _CoinListTile(coin: coin);
              },
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _statItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: valueColor ?? AppColors.textSecondary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual coin tile in the market list.
class _CoinListTile extends StatelessWidget {
  final Coin coin;
  const _CoinListTile({required this.coin});

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.percentChange >= 0;

    return InkWell(
      onTap: () => context.push('/market/${coin.symbol}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Coin icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                coin.resolvedIconUrl,
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) => Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.deepBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Text(
                      coin.symbol.isNotEmpty ? coin.symbol[0] : '?',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.voltGreen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name & symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    coin.symbol,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Price & change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(coin.currentPrice),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.voltGreenDim
                        : AppColors.errorDim,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 12,
                        color: isPositive
                            ? AppColors.voltGreen
                            : AppColors.error,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${isPositive ? '+' : ''}${coin.percentChange.toStringAsFixed(2)}%',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isPositive
                              ? AppColors.voltGreen
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1) {
      return '\$${value.toStringAsFixed(2)}';
    }
    return '\$${value.toStringAsFixed(4)}';
  }
}

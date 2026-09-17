import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/theme/app_colors.dart';
import '../models/limit_order_models.dart';
import '../models/market_models.dart';
import '../models/market_news_models.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';

// ═══════════════════════════════════════════════════════════
// LOCAL PROVIDERS (scoped to this screen)
// ═══════════════════════════════════════════════════════════

// ── Price History Provider ─────────────────────────────────
class _PriceHistoryState {
  final List<PriceHistory> history;
  final bool isLoading;
  const _PriceHistoryState({this.history = const [], this.isLoading = false});
}

class _PriceHistoryNotifier extends StateNotifier<_PriceHistoryState> {
  final ApiClient _apiClient;
  _PriceHistoryNotifier(this._apiClient) : super(const _PriceHistoryState());

  Future<void> fetchHistory(String symbol, String timeframe) async {
    state = const _PriceHistoryState(isLoading: true);
    try {
      final tf = AppConstants.timeframes.firstWhere((t) => t['value'] == timeframe);
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
      state = _PriceHistoryState(history: list);
    } catch (_) {
      state = const _PriceHistoryState();
    }
  }
}

final _priceHistoryProvider =
    StateNotifierProvider<_PriceHistoryNotifier, _PriceHistoryState>(
  (ref) => _PriceHistoryNotifier(ref.read(apiClientProvider)),
);

// ── Limit Order Provider ───────────────────────────────────
class _LimitOrderState {
  final List<LimitOrderDto> orders;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  const _LimitOrderState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
  _LimitOrderState copyWith({
    List<LimitOrderDto>? orders,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) => _LimitOrderState(
    orders: orders ?? this.orders,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
    successMessage: successMessage,
  );
}

class _LimitOrderNotifier extends StateNotifier<_LimitOrderState> {
  final ApiClient _apiClient;
  static const _uuid = Uuid();
  _LimitOrderNotifier(this._apiClient) : super(const _LimitOrderState());

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.dio.get('/api/limit-orders',
          options: Options(headers: ApiClient.idempotencyHeaders));
      final list = (response.data as List)
          .map((e) => LimitOrderDto.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(orders: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createOrder(CreateLimitOrderRequest req) async {
    state = state.copyWith(errorMessage: null, successMessage: null);
    try {
      await _apiClient.dio.post('/api/limit-orders',
          data: req.toJson(),
          options: Options(headers: {'Idempotency-Key': _uuid.v4()}));
      state = state.copyWith(successMessage: 'Order placed successfully');
      await fetchAll();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
          errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to place order');
      return false;
    }
  }

  Future<bool> updateOrder(String id, UpdateLimitOrderRequest req) async {
    state = state.copyWith(errorMessage: null, successMessage: null);
    try {
      await _apiClient.dio.patch('/api/limit-orders/$id',
          data: req.toJson(),
          options: Options(headers: {'Idempotency-Key': _uuid.v4()}));
      state = state.copyWith(successMessage: 'Order updated');
      await fetchAll();
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to update order');
      return false;
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _apiClient.dio.delete('/api/limit-orders/$id',
          options: Options(headers: {'Idempotency-Key': _uuid.v4()}));
      state = state.copyWith(
        orders: state.orders.where((o) => o.id != id).toList(),
        successMessage: 'Order deleted',
      );
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to delete');
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final _limitOrderProvider =
    StateNotifierProvider<_LimitOrderNotifier, _LimitOrderState>(
  (ref) => _LimitOrderNotifier(ref.read(apiClientProvider)),
);

// ── Coin News Provider ─────────────────────────────────────
class _CoinNewsState {
  final List<MarketNews> news;
  final bool isLoading;
  const _CoinNewsState({this.news = const [], this.isLoading = false});
}

class _CoinNewsNotifier extends StateNotifier<_CoinNewsState> {
  final ApiClient _apiClient;
  _CoinNewsNotifier(this._apiClient) : super(const _CoinNewsState());

  Future<void> fetchByCoin(String symbol) async {
    state = const _CoinNewsState(isLoading: true);
    try {
      final response = await _apiClient.dio.get('/api/market-news/coin/$symbol');
      final list = (response.data as List)
          .map((e) => MarketNews.fromJson(e as Map<String, dynamic>))
          .toList();
      state = _CoinNewsState(news: list);
    } catch (_) {
      state = const _CoinNewsState();
    }
  }
}

final _coinNewsProvider =
    StateNotifierProvider<_CoinNewsNotifier, _CoinNewsState>(
  (ref) => _CoinNewsNotifier(ref.read(apiClientProvider)),
);

// ── Price Alert Provider ───────────────────────────────────
class _PriceAlertFormState {
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;
  const _PriceAlertFormState({this.isSubmitting = false, this.successMessage, this.errorMessage});
}

class _PriceAlertFormNotifier extends StateNotifier<_PriceAlertFormState> {
  final ApiClient _apiClient;
  final AuthApi _authApi;
  _PriceAlertFormNotifier(this._apiClient, this._authApi)
      : super(const _PriceAlertFormState());

  Future<bool> createAlert(String symbol, double targetPrice, bool isAbove) async {
    state = const _PriceAlertFormState(isSubmitting: true);
    try {
      final userId = await _authApi.getUserIdFromToken();
      if (userId == null) {
        state = const _PriceAlertFormState(errorMessage: 'Not authenticated');
        return false;
      }
      await _apiClient.dio.post('/api/price-alerts', data: {
        'userId': userId,
        'symbol': symbol,
        'targetPrice': targetPrice,
        'isAbove': isAbove,
      });
      state = const _PriceAlertFormState(successMessage: 'Alert created successfully');
      return true;
    } on DioException catch (e) {
      state = _PriceAlertFormState(
          errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to create alert');
      return false;
    }
  }

  void clear() => state = const _PriceAlertFormState();
}

final _priceAlertFormProvider =
    StateNotifierProvider<_PriceAlertFormNotifier, _PriceAlertFormState>(
  (ref) => _PriceAlertFormNotifier(ref.read(apiClientProvider), ref.read(authApiProvider)),
);

// ═══════════════════════════════════════════════════════════
// COIN DETAIL SCREEN
// ═══════════════════════════════════════════════════════════

import '../services/auth_api.dart';
import 'market_screen.dart';

/// Coin detail screen — chart, limit orders, price alerts, news.
/// Mirrors: frontend/src/views/CoinDetailView.vue
class CoinDetailScreen extends ConsumerStatefulWidget {
  final String symbol;
  const CoinDetailScreen({super.key, required this.symbol});

  @override
  ConsumerState<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends ConsumerState<CoinDetailScreen> {
  String _selectedTimeframe = '7d';

  // Limit order form state
  final _targetPriceController = TextEditingController();
  final _orderAmountController = TextEditingController();
  String _orderType = 'Buy'; // 'Buy' or 'Sell'

  // Price alert form state
  final _alertPriceController = TextEditingController();
  String _alertDirection = 'above'; // 'above' or 'below'

  // Edit state
  String? _editingOrderId;
  final _editPriceController = TextEditingController();
  final _editAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadData);
  }

  Future<void> _loadData() async {
    final symbol = widget.symbol;
    ref.read(_priceHistoryProvider.notifier).fetchHistory(symbol, _selectedTimeframe);
    ref.read(_limitOrderProvider.notifier).fetchAll();
    ref.read(_coinNewsProvider.notifier).fetchByCoin(symbol);
    // Ensure market coins are loaded for header data
    if (ref.read(marketProvider).coins.isEmpty) {
      ref.read(marketProvider.notifier).fetchCoins();
    }
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    _orderAmountController.dispose();
    _alertPriceController.dispose();
    _editPriceController.dispose();
    _editAmountController.dispose();
    super.dispose();
  }

  Coin? get _coinData {
    final coins = ref.read(marketProvider).coins;
    try {
      return coins.firstWhere(
          (c) => c.symbol.toUpperCase() == widget.symbol.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(2)}M';
    }
    if (value >= 1) return '\$${value.toStringAsFixed(2)}';
    return '\$${value.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final coin = _coinData;
    final history = ref.watch(_priceHistoryProvider);
    final orders = ref.watch(_limitOrderProvider);
    final news = ref.watch(_coinNewsProvider);
    final auth = ref.watch(authProvider);

    final symbolOrders = orders.orders
        .where((o) => o.symbol.toUpperCase() == widget.symbol.toUpperCase())
        .toList()
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.surfaceBg,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    coin?.resolvedIconUrl ?? '',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.deepBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(widget.symbol.isNotEmpty ? widget.symbol[0] : '?',
                            style: const TextStyle(
                                color: AppColors.voltGreen, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(coin?.name ?? widget.symbol),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Card ─────────────────────────
                  _buildHeaderCard(context, coin),
                  const SizedBox(height: 12),

                  // ── Stats + Timeframe ───────────────────
                  _buildStatsRow(context, coin),
                  const SizedBox(height: 16),

                  // ── Candlestick Chart ───────────────────
                  _buildChart(context, history),
                  const SizedBox(height: 24),

                  // ── Limit Order Section ─────────────────
                  if (auth.isLoggedIn) ...[
                    _buildLimitOrderSection(context, orders),
                    const SizedBox(height: 24),

                    // ── Price Alert Section ─────────────────
                    _buildPriceAlertSection(context),
                    const SizedBox(height: 24),
                  ],

                  // ── Active Orders ───────────────────────
                  if (symbolOrders.isNotEmpty) ...[
                    _buildActiveOrders(context, symbolOrders),
                    const SizedBox(height: 24),
                  ],

                  // ── News Section ────────────────────────
                  _buildNewsSection(context, news),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER CARD ──────────────────────────────────────────
  Widget _buildHeaderCard(BuildContext context, Coin? coin) {
    final isPositive = (coin?.percentChange ?? 0) >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coin?.name ?? widget.symbol,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  Text(widget.symbol,
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(coin?.currentPrice ?? 0),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive ? AppColors.voltGreenDim : AppColors.errorDim,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPositive ? Icons.trending_up : Icons.trending_down,
                          size: 14, color: isPositive ? AppColors.voltGreen : AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        '${isPositive ? '+' : ''}${(coin?.percentChange ?? 0).toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isPositive ? AppColors.voltGreen : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── STATS + TIMEFRAME ────────────────────────────────────
  Widget _buildStatsRow(BuildContext context, Coin? coin) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Market Cap', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(_formatCurrency(coin?.marketCap ?? 0),
                      style: Theme.of(context).textTheme.labelLarge),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            color: AppColors.deepBg,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: AppConstants.timeframes.map((tf) {
                  final isSelected = _selectedTimeframe == tf['value'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTimeframe = tf['value'] as String);
                        ref.read(_priceHistoryProvider.notifier)
                            .fetchHistory(widget.symbol, _selectedTimeframe);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.voltGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            tf['label'] as String,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isSelected ? Colors.black : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── CANDLESTICK CHART ────────────────────────────────────
  Widget _buildChart(BuildContext context, _PriceHistoryState history) {
    if (history.isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator(color: AppColors.voltGreen)),
      );
    }

    if (history.history.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text('No chart data available', style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    final data = history.history;
    final minLow = data.map((d) => d.lowPrice).reduce((a, b) => a < b ? a : b);
    final maxHigh = data.map((d) => d.highPrice).reduce((a, b) => a > b ? a : b);
    final padding = (maxHigh - minLow) * 0.1;

    return Card(
      color: AppColors.deepBg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxHigh + padding,
              minY: minLow - padding,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = data[groupIndex];
                    return BarTooltipItem(
                      'O: \$${item.openPrice.toStringAsFixed(2)}\n'
                      'H: \$${item.highPrice.toStringAsFixed(2)}\n'
                      'L: \$${item.lowPrice.toStringAsFixed(2)}\n'
                      'C: \$${item.closePrice.toStringAsFixed(2)}',
                      Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                      // Show ~5 labels
                      if (data.length > 5 && idx % (data.length ~/ 5) != 0) {
                        return const SizedBox.shrink();
                      }
                      final dt = DateTime.fromMillisecondsSinceEpoch(data[idx].timestamp);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 55,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '\$${value.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.borderSubtle,
                  strokeWidth: 0.5,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(data.length, (i) {
                final d = data[i];
                final isUp = d.closePrice >= d.openPrice;
                final top = isUp ? d.closePrice : d.openPrice;
                final bottom = isUp ? d.openPrice : d.closePrice;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      fromY: bottom,
                      toY: top,
                      width: data.length > 50 ? 2 : (data.length > 20 ? 4 : 6),
                      color: isUp ? AppColors.voltGreen : AppColors.priceDown,
                      borderRadius: BorderRadius.zero,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        fromY: d.lowPrice,
                        toY: d.highPrice,
                        color: (isUp ? AppColors.voltGreen : AppColors.priceDown)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── LIMIT ORDER SECTION ──────────────────────────────────
  Widget _buildLimitOrderSection(BuildContext context, _LimitOrderState orders) {
    final alertForm = ref.watch(_priceAlertFormProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.trending_up, color: AppColors.voltGreen, size: 20),
              const SizedBox(width: 8),
              Text('Set Limit Order',
                  style: Theme.of(context).textTheme.headlineSmall),
            ]),
            const SizedBox(height: 16),

            // Buy/Sell toggle
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _orderType = 'Buy'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _orderType == 'Buy' ? AppColors.voltGreen : Colors.transparent,
                      border: Border.all(
                        color: _orderType == 'Buy' ? AppColors.voltGreen : AppColors.borderSubtle,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, size: 16,
                            color: _orderType == 'Buy' ? Colors.black : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Buy',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _orderType == 'Buy' ? Colors.black : AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _orderType = 'Sell'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _orderType == 'Sell' ? AppColors.error : Colors.transparent,
                      border: Border.all(
                        color: _orderType == 'Sell' ? AppColors.error : AppColors.borderSubtle,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_down, size: 16,
                            color: _orderType == 'Sell' ? Colors.black : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Sell',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _orderType == 'Sell' ? Colors.black : AppColors.textSecondary,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Form fields
            TextField(
              controller: _targetPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Target Price (USD)',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (${widget.symbol})',
                hintText: '0.00',
              ),
            ),
            const SizedBox(height: 12),

            // Order summary
            Builder(builder: (ctx) {
              final tp = double.tryParse(_targetPriceController.text);
              final amt = double.tryParse(_orderAmountController.text);
              if (tp != null && amt != null && tp > 0 && amt > 0) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Value', style: Theme.of(ctx).textTheme.bodySmall),
                      Text(_formatCurrency(tp * amt),
                          style: Theme.of(ctx).textTheme.labelLarge),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 16),

            // Submit button
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orderType == 'Buy' ? AppColors.voltGreen : AppColors.error,
                ),
                onPressed: () => _submitLimitOrder(),
                child: Text('Place $_orderType Order'),
              ),
            ),

            // Messages
            if (orders.successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.voltGreenDim,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.voltGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(orders.successMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.voltGreen)),
                ]),
              ),
            ],
            if (orders.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorDim,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(orders.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error)),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitLimitOrder() async {
    final targetPrice = double.tryParse(_targetPriceController.text);
    final amount = double.tryParse(_orderAmountController.text);
    if (targetPrice == null || amount == null || targetPrice <= 0 || amount <= 0) return;

    final userId = await ref.read(authApiProvider).getUserIdFromToken();
    if (userId == null) return;

    final success = await ref.read(_limitOrderProvider.notifier).createOrder(
      CreateLimitOrderRequest(
        userId: userId,
        walletId: '', // backend will resolve
        symbol: widget.symbol,
        targetPrice: targetPrice,
        amount: amount,
        orderType: _orderType == 'Buy' ? LimitOrderType.buy : LimitOrderType.sell,
      ),
    );

    if (success) {
      _targetPriceController.clear();
      _orderAmountController.clear();
    }
  }

  // ── PRICE ALERT SECTION ──────────────────────────────────
  Widget _buildPriceAlertSection(BuildContext context) {
    final alertState = ref.watch(_priceAlertFormProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.notifications_active, color: AppColors.voltGreen, size: 20),
              const SizedBox(width: 8),
              Text('Set Price Alert', style: Theme.of(context).textTheme.headlineSmall),
            ]),
            const SizedBox(height: 16),

            // Direction toggle
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _alertDirection = 'above'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _alertDirection == 'above' ? AppColors.voltGreen : Colors.transparent,
                      border: Border.all(
                        color: _alertDirection == 'above' ? AppColors.voltGreen : AppColors.borderSubtle,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up, size: 16,
                            color: _alertDirection == 'above' ? Colors.black : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Above', style: TextStyle(fontWeight: FontWeight.w700,
                            color: _alertDirection == 'above' ? Colors.black : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _alertDirection = 'below'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _alertDirection == 'below' ? AppColors.error : Colors.transparent,
                      border: Border.all(
                        color: _alertDirection == 'below' ? AppColors.error : AppColors.borderSubtle,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_down, size: 16,
                            color: _alertDirection == 'below' ? Colors.black : AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text('Below', style: TextStyle(fontWeight: FontWeight.w700,
                            color: _alertDirection == 'below' ? Colors.black : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            TextField(
              controller: _alertPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Price (USD)',
                hintText: '0.00',
                helperText: 'Alert when ${widget.symbol} goes $_alertDirection this price',
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alertDirection == 'above' ? AppColors.voltGreen : AppColors.error,
                ),
                onPressed: alertState.isSubmitting ? null : () => _submitPriceAlert(),
                child: alertState.isSubmitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text('Set ${_alertDirection == 'above' ? 'Above' : 'Below'} Alert'),
              ),
            ),

            if (alertState.successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.voltGreenDim, borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  const Icon(Icons.check_circle, color: AppColors.voltGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(alertState.successMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.voltGreen)),
                ]),
              ),
            ],
            if (alertState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorDim, borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(alertState.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error))),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitPriceAlert() async {
    final price = double.tryParse(_alertPriceController.text);
    if (price == null || price <= 0) return;

    final success = await ref.read(_priceAlertFormProvider.notifier)
        .createAlert(widget.symbol, price, _alertDirection == 'above');
    if (success) _alertPriceController.clear();
  }

  // ── ACTIVE ORDERS ────────────────────────────────────────
  Widget _buildActiveOrders(BuildContext context, List<LimitOrderDto> orders) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const Icon(Icons.receipt_long, color: AppColors.voltGreen, size: 20),
              const SizedBox(width: 8),
              Text('Active Orders — ${widget.symbol}',
                  style: Theme.of(context).textTheme.headlineSmall),
            ]),
          ),
          const Divider(height: 0),
          ...orders.map((order) => _buildOrderTile(context, order)),
        ],
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, LimitOrderDto order) {
    final isEditing = _editingOrderId == order.id;
    final isBuy = order.isBuy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle, width: 0.5)),
      ),
      child: isEditing ? _buildEditRow(context, order) : _buildViewRow(context, order, isBuy),
    );
  }

  Widget _buildViewRow(BuildContext context, LimitOrderDto order, bool isBuy) {
    return Row(
      children: [
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isBuy ? AppColors.voltGreenDim : AppColors.errorDim,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isBuy ? AppColors.voltGreen : AppColors.error,
              width: 0.5,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isBuy ? Icons.trending_up : Icons.trending_down,
                size: 12, color: isBuy ? AppColors.voltGreen : AppColors.error),
            const SizedBox(width: 4),
            Text(isBuy ? 'Buy' : 'Sell',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isBuy ? AppColors.voltGreen : AppColors.error,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        const SizedBox(width: 12),

        // Price & amount
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatCurrency(order.targetPrice),
                  style: Theme.of(context).textTheme.labelLarge),
              Text('${order.amount} ${order.symbol} • ${_formatCurrency(order.targetPrice * order.amount)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),

        // Actions
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          color: AppColors.textMuted,
          onPressed: () {
            setState(() {
              _editingOrderId = order.id;
              _editPriceController.text = order.targetPrice.toString();
              _editAmountController.text = order.amount.toString();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: AppColors.error,
          onPressed: () => ref.read(_limitOrderProvider.notifier).deleteOrder(order.id),
        ),
      ],
    );
  }

  Widget _buildEditRow(BuildContext context, LimitOrderDto order) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _editPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price', isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _editAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', isDense: true),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed: () => setState(() => _editingOrderId = null),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(_editPriceController.text);
              final amount = double.tryParse(_editAmountController.text);
              if (price == null || amount == null) return;
              final success = await ref.read(_limitOrderProvider.notifier)
                  .updateOrder(order.id, UpdateLimitOrderRequest(amount: amount, targetPrice: price));
              if (success) setState(() => _editingOrderId = null);
            },
            child: const Text('Save'),
          ),
        ]),
      ],
    );
  }

  // ── NEWS SECTION ─────────────────────────────────────────
  Widget _buildNewsSection(BuildContext context, _CoinNewsState news) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.newspaper, color: AppColors.voltGreen, size: 20),
          const SizedBox(width: 8),
          Text('Intel: ${widget.symbol}',
              style: Theme.of(context).textTheme.headlineSmall),
        ]),
        const SizedBox(height: 12),
        if (news.isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.voltGreen),
          ))
        else if (news.news.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(
                'No intelligence reports for ${widget.symbol}.',
                style: Theme.of(context).textTheme.bodySmall,
              )),
            ),
          )
        else
          ...news.news.take(5).map((article) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/news/${Uri.encodeComponent(article.title)}'),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.voltGreenDim,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(article.source,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.voltGreen, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(article.title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          )),
      ],
    );
  }
}

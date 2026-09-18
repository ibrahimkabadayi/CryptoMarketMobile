import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../models/limit_order_models.dart';
import '../models/market_models.dart';
import '../providers/auth_provider.dart';
import '../providers/limit_order_provider.dart';
import '../providers/market_news_provider.dart';
import '../providers/market_provider.dart';
import '../providers/price_alert_provider.dart';
import 'widgets/candlestick_chart.dart';




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
    ref.read(priceHistoryProvider.notifier).fetchHistory(symbol, _selectedTimeframe);
    ref.read(limitOrderProvider.notifier).fetchAll();
    ref.read(marketNewsProvider.notifier).fetchNewsByCoin(symbol);
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
    final history = ref.watch(priceHistoryProvider);
    final orders = ref.watch(limitOrderProvider);
    final news = ref.watch(marketNewsProvider);
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
                    errorBuilder: (_, _, _) => Container(
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

                  // ── Market Cap Stat ─────────────────────
                  _buildMarketCapCard(context, coin),
                  const SizedBox(height: 16),

                  // ── Candlestick Chart ───────────────────
                  CandlestickChart(
                    history: history.history,
                    isLoading: history.isLoading,
                    symbol: widget.symbol,
                    selectedTimeframe: _selectedTimeframe,
                    onTimeframeChanged: (tf) {
                      setState(() => _selectedTimeframe = tf);
                      ref.read(priceHistoryProvider.notifier)
                          .fetchHistory(widget.symbol, _selectedTimeframe);
                    },
                  ),
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

  // ── MARKET CAP STAT CARD ─────────────────────────────────
  Widget _buildMarketCapCard(BuildContext context, Coin? coin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Market Cap', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(_formatCurrency(coin?.marketCap ?? 0),
                    style: Theme.of(context).textTheme.headlineSmall),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                coin?.isCapped == true ? 'Capped Supply' : 'Variable Supply',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.voltGreen,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LIMIT ORDER SECTION ──────────────────────────────────
  Widget _buildLimitOrderSection(BuildContext context, LimitOrderState orders) {
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

    final success = await ref.read(limitOrderProvider.notifier).createOrder(
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
    final alertState = ref.watch(priceAlertProvider);

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
                onPressed: alertState.isLoading ? null : () => _submitPriceAlert(),
                child: alertState.isLoading
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

    final success = await ref.read(priceAlertProvider.notifier)
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
          onPressed: () => ref.read(limitOrderProvider.notifier).deleteOrder(order.id),
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
              final success = await ref.read(limitOrderProvider.notifier)
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
  Widget _buildNewsSection(BuildContext context, MarketNewsState news) {
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

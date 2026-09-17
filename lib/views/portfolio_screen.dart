import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../models/portfolio_models.dart';

// ── Portfolio API ──────────────────────────────────────────
final portfolioApiProvider = Provider<PortfolioApi>(
  (ref) => PortfolioApi(ref.read(apiClientProvider)),
);

class PortfolioApi {
  final ApiClient _apiClient;
  PortfolioApi(this._apiClient);

  Future<Dashboard> getDashboard() async {
    final response = await _apiClient.dio.get('/api/wallets');
    return Dashboard.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deposit(String walletId, double amount) async {
    await _apiClient.dio.post(
      '/api/wallets/$walletId/transaction',
      data: {'amount': amount},
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
  }

  Future<void> withdraw(String walletId, double amount) async {
    await _apiClient.dio.patch(
      '/api/wallets/$walletId',
      data: {'amount': amount},
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
  }

  Future<void> buyCoin(String walletId, String symbol, double amount, double price) async {
    await _apiClient.dio.post(
      '/api/wallets/$walletId/assets/$symbol',
      data: {'amount': amount, 'buyingPrice': price},
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
  }

  Future<void> sellCoin(String walletId, String symbol, double amount, double price) async {
    await _apiClient.dio.patch(
      '/api/wallets/$walletId/assets/$symbol',
      data: {'amount': amount, 'price': price},
      options: Options(headers: ApiClient.idempotencyHeaders),
    );
  }
}

// ── Portfolio State ────────────────────────────────────────
class PortfolioState {
  final Dashboard? dashboard;
  final bool isLoading;
  final String? errorMessage;

  const PortfolioState({this.dashboard, this.isLoading = false, this.errorMessage});

  PortfolioState copyWith({
    Dashboard? dashboard,
    bool? isLoading,
    String? errorMessage,
  }) => PortfolioState(
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
        errorMessage: 'Failed to load portfolio.',
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
}

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>(
  (ref) => PortfolioNotifier(ref.read(portfolioApiProvider)),
);

// ── Portfolio Screen ───────────────────────────────────────
/// Portfolio screen — balances, wallet info, assets, and transactions.
/// Mirrors: frontend/src/views/PortfolioView.vue
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(portfolioProvider.notifier).fetchDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final portfolio = ref.watch(portfolioProvider);

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(title: const Text('Portfolio')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Sign in to view your portfolio',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(children: [
            TextSpan(text: 'Portfolio ', style: Theme.of(context).textTheme.headlineSmall),
            TextSpan(text: 'Manager', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.voltGreen)),
          ]),
        ),
        actions: [
          if (portfolio.dashboard != null) ...[
            IconButton(
              icon: const Icon(Icons.download, size: 20),
              tooltip: 'Deposit',
              onPressed: () => _showTransactionSheet(context, 'deposit'),
            ),
            IconButton(
              icon: const Icon(Icons.upload, size: 20),
              tooltip: 'Withdraw',
              onPressed: () => _showTransactionSheet(context, 'withdraw'),
            ),
          ],
        ],
      ),
      body: portfolio.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.voltGreen))
          : portfolio.errorMessage != null
              ? _buildError(context, portfolio.errorMessage!)
              : portfolio.dashboard != null
                  ? _buildDashboard(context, portfolio.dashboard!)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => ref.read(portfolioProvider.notifier).fetchDashboard(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, Dashboard dashboard) {
    return RefreshIndicator(
      color: AppColors.voltGreen,
      backgroundColor: AppColors.cardBg,
      onRefresh: () => ref.read(portfolioProvider.notifier).fetchDashboard(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Balance Cards ───────────────────────────
          Row(
            children: [
              Expanded(child: _balanceCard(
                context,
                label: 'Fiat Balance',
                value: '\$${dashboard.fiatBalance.toStringAsFixed(2)}',
                icon: Icons.account_balance,
                color: AppColors.voltGreen,
              )),
              const SizedBox(width: 12),
              Expanded(child: _balanceCard(
                context,
                label: 'Total Invested',
                value: '\$${dashboard.totalInvestedValue.toStringAsFixed(2)}',
                icon: Icons.attach_money,
                color: AppColors.textPrimary,
              )),
            ],
          ),
          const SizedBox(height: 16),

          // ── Wallet Info ────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.deepBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Icon(Icons.wallet, size: 20, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wallet', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 2),
                        Text(
                          dashboard.address,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.voltGreen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: AppColors.textMuted),
                    onPressed: () {
                      // Copy to clipboard
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Assets ─────────────────────────────────
          Text('Assets', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (dashboard.assets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No assets yet', style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            )
          else
            ...dashboard.assets.map((asset) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.deepBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Center(
                    child: Text(asset.symbol.isNotEmpty ? asset.symbol[0] : '?',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.voltGreen)),
                  ),
                ),
                title: Text(asset.symbol, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Qty: ${asset.quantity.toStringAsFixed(4)} • Avg: \$${asset.averageBuyPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall),
                trailing: Text('\$${asset.investedAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
            )),
          const SizedBox(height: 24),

          // ── Transactions ───────────────────────────
          Text('Recent Transactions', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          if (dashboard.recentTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text('No transactions yet', style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            )
          else
            ...dashboard.recentTransactions.map((tx) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _txIcon(tx.transactionType),
                title: Text('${tx.transactionType.toUpperCase()} ${tx.symbol}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                subtitle: Text('${tx.amount.toStringAsFixed(4)} @ \$${tx.priceAtTransaction.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _balanceCard(BuildContext context, {required String label, required String value, required IconData icon, required Color color}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
            ]),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _txIcon(String type) {
    final (IconData icon, Color color) = switch (type.toLowerCase()) {
      'buy' => (Icons.trending_up, AppColors.voltGreen),
      'sell' => (Icons.trending_down, AppColors.error),
      'deposit' => (Icons.download, AppColors.info),
      'withdraw' => (Icons.upload, AppColors.warning),
      _ => (Icons.swap_horiz, AppColors.textMuted),
    };
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  void _showTransactionSheet(BuildContext context, String type) {
    final amountController = TextEditingController();
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Icon(
                    type == 'deposit' ? Icons.download : Icons.upload,
                    color: type == 'deposit' ? AppColors.voltGreen : AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${type[0].toUpperCase()}${type.substring(1)} Fiat',
                    style: Theme.of(ctx).textTheme.headlineSmall,
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Balance: \$${ref.read(portfolioProvider).dashboard?.fiatBalance.toStringAsFixed(2) ?? '0.00'}',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount (USD)',
                    hintText: '0.00',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: type == 'withdraw'
                          ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                          : null,
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          setSheetState(() => error = 'Enter a valid amount');
                          return;
                        }
                        final balance = ref.read(portfolioProvider).dashboard?.fiatBalance ?? 0;
                        if (type == 'withdraw' && amount > balance) {
                          setSheetState(() => error = 'Insufficient balance');
                          return;
                        }
                        Navigator.pop(ctx);
                        if (type == 'deposit') {
                          await ref.read(portfolioProvider.notifier).deposit(amount);
                        } else {
                          await ref.read(portfolioProvider.notifier).withdraw(amount);
                        }
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}

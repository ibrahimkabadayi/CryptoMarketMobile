import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../models/price_alert_models.dart';
import '../providers/price_alert_provider.dart';

/// Price Alerts management screen.
/// Displays user's configured price alerts with ability to filter and deactivate.
class PriceAlertsScreen extends ConsumerStatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  ConsumerState<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends ConsumerState<PriceAlertsScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(priceAlertProvider.notifier).fetchAlerts();
    });
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceAlertProvider);
    final alerts = state.sortedAlerts;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Price Alerts'),
        actions: [
          Row(
            children: [
              Text(
                'Show Inactive',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              Switch(
                value: state.showAllAlerts,
                activeThumbColor: AppColors.voltGreen,
                onChanged: (_) => ref.read(priceAlertProvider.notifier).toggleShowAll(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.voltGreen,
        backgroundColor: AppColors.surfaceBg,
        onRefresh: () => ref.read(priceAlertProvider.notifier).fetchAlerts(),
        child: state.isLoading && alerts.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.voltGreen),
              )
            : alerts.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.deepBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: const Icon(
                                Icons.add_alert_outlined,
                                color: AppColors.textMuted,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No price alerts configured',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Set alerts from any coin detail page to get notified when prices move.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/market'),
                              icon: const Icon(Icons.explore_outlined, size: 18),
                              label: const Text('Explore Markets'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: alerts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _buildAlertCard(context, alert);
                    },
                  ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, PriceAlertDto alert) {
    final isAbove = alert.isAbove;
    final directionColor = isAbove ? AppColors.voltGreen : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert.isActive
              ? directionColor.withValues(alpha: 0.3)
              : AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Coin Symbol Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.deepBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Center(
                  child: Text(
                    alert.symbol.isNotEmpty ? alert.symbol.substring(0, alert.symbol.length > 3 ? 3 : alert.symbol.length) : '?',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Target Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          alert.symbol,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: directionColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAbove ? Icons.arrow_upward : Icons.arrow_downward,
                                size: 12,
                                color: directionColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                isAbove ? 'Above' : 'Below',
                                style: TextStyle(
                                  color: directionColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${_currencyFormat.format(alert.targetPrice)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              // Status / Action
              if (alert.isActive)
                TextButton(
                  onPressed: () =>
                      ref.read(priceAlertProvider.notifier).deactivateAlert(alert.id),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Deactivate', style: TextStyle(fontSize: 12)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.deepBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Inactive',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
            ],
          ),
          if (alert.createdAt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Created: ${_formatDate(alert.createdAt)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Coin detail screen — shows chart, limit orders, price alerts, and news.
/// Mirrors: frontend/src/views/CoinDetailView.vue
/// Full implementation in Phase 2.
class CoinDetailScreen extends StatelessWidget {
  final String symbol;
  const CoinDetailScreen({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(symbol),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.candlestick_chart,
                size: 64, color: AppColors.voltGreen),
            const SizedBox(height: 16),
            Text(
              symbol,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Coin detail — chart, orders & alerts',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 2',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.voltGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

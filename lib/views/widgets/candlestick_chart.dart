import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/market_models.dart';

/// Reusable Candlestick OHLCV Chart component using fl_chart.
/// Renders financial candlestick bodies and wicks with responsive timeframes.
class CandlestickChart extends StatelessWidget {
  final List<PriceHistory> history;
  final bool isLoading;
  final String symbol;
  final String selectedTimeframe;
  final ValueChanged<String>? onTimeframeChanged;

  const CandlestickChart({
    super.key,
    required this.history,
    this.isLoading = false,
    required this.symbol,
    this.selectedTimeframe = '24h',
    this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Timeframe Selector ─────────────────────────────
        if (onTimeframeChanged != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: AppConstants.timeframes.map((tf) {
                    final isSelected = selectedTimeframe == tf['value'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTimeframeChanged!(tf['value'] as String),
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

        // ── Chart Canvas ───────────────────────────────────
        if (isLoading)
          const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator(color: AppColors.voltGreen)),
          )
        else if (history.isEmpty)
          SizedBox(
            height: 300,
            child: Center(
              child: Text(
                'No chart data available for $symbol',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          )
        else
          _buildBarChart(context),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final data = history;
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
                final isUp = d.isUp;
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
}

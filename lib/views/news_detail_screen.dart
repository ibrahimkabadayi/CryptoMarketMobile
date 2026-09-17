import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../models/market_news_models.dart';
import 'market_news_screen.dart';

/// News detail screen — full article view.
/// Mirrors: frontend/src/views/NewsDetailView.vue
class NewsDetailScreen extends ConsumerWidget {
  final String title;
  const NewsDetailScreen({super.key, required this.title});

  String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year} at '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsState = ref.watch(marketNewsProvider);
    final decodedTitle = Uri.decodeComponent(title);

    // Find the article from the store
    MarketNews? article;
    try {
      article = newsState.news.firstWhere((n) => n.title == decodedTitle);
    } catch (_) {
      article = null;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Article'),
      ),
      body: newsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.voltGreen))
          : article == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Article not found', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source & date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.voltGreenDim,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.voltGreen.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              article.source,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.voltGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDate(article.publishedAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      const Divider(),
                      const SizedBox(height: 24),

                      // Content
                      Text(
                        article.content,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.7,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      // Related symbols
                      if (article.relatedSymbols.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'RELATED ASSETS',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: article.relatedSymbols.map((symbol) =>
                            ActionChip(
                              label: Text(symbol),
                              onPressed: () => context.push('/market/$symbol'),
                            ),
                          ).toList(),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}

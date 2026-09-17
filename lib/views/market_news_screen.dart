import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../models/market_news_models.dart';

// ── Market News API ────────────────────────────────────────
final marketNewsApiProvider = Provider<MarketNewsApi>(
  (ref) => MarketNewsApi(ref.read(apiClientProvider)),
);

class MarketNewsApi {
  final ApiClient _apiClient;
  MarketNewsApi(this._apiClient);

  Future<List<MarketNews>> getRecentNews() async {
    final response = await _apiClient.dio.get('/api/market-news');
    return (response.data as List)
        .map((e) => MarketNews.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MarketNews>> getNewsByCoin(String symbol) async {
    final response = await _apiClient.dio.get('/api/market-news/coin/$symbol');
    return (response.data as List)
        .map((e) => MarketNews.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Market News State ──────────────────────────────────────
class MarketNewsState {
  final List<MarketNews> news;
  final bool isLoading;
  final String? errorMessage;

  const MarketNewsState({this.news = const [], this.isLoading = false, this.errorMessage});

  MarketNewsState copyWith({
    List<MarketNews>? news,
    bool? isLoading,
    String? errorMessage,
  }) => MarketNewsState(
    news: news ?? this.news,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: errorMessage,
  );
}

class MarketNewsNotifier extends StateNotifier<MarketNewsState> {
  final MarketNewsApi _api;
  MarketNewsNotifier(this._api) : super(const MarketNewsState());

  Future<void> fetchRecentNews() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final news = await _api.getRecentNews();
      state = state.copyWith(news: news, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load news.');
    }
  }
}

final marketNewsProvider = StateNotifierProvider<MarketNewsNotifier, MarketNewsState>(
  (ref) => MarketNewsNotifier(ref.read(marketNewsApiProvider)),
);

// ── Market News Screen ─────────────────────────────────────
/// News feed screen.
/// Mirrors: frontend/src/views/MarketNewsView.vue
class MarketNewsScreen extends ConsumerStatefulWidget {
  const MarketNewsScreen({super.key});

  @override
  ConsumerState<MarketNewsScreen> createState() => _MarketNewsScreenState();
}

class _MarketNewsScreenState extends ConsumerState<MarketNewsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(marketNewsProvider.notifier).fetchRecentNews());
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final newsState = ref.watch(marketNewsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(children: [
            TextSpan(text: 'Market ', style: Theme.of(context).textTheme.headlineSmall),
            TextSpan(text: 'Intel', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.voltGreen)),
          ]),
        ),
      ),
      body: newsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.voltGreen))
          : newsState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(newsState.errorMessage!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => ref.read(marketNewsProvider.notifier).fetchRecentNews(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.voltGreen,
                  backgroundColor: AppColors.cardBg,
                  onRefresh: () => ref.read(marketNewsProvider.notifier).fetchRecentNews(),
                  child: newsState.news.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Center(
                                child: Text('No news available',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: newsState.news.length,
                          itemBuilder: (context, index) {
                            final article = newsState.news[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => context.push('/news/${Uri.encodeComponent(article.title)}'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Source & date
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.voltGreenDim,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(article.source,
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: AppColors.voltGreen, fontWeight: FontWeight.w700)),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(_formatDate(article.publishedAt),
                                              style: Theme.of(context).textTheme.labelSmall),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Title
                                      Text(
                                        article.title,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      // Content preview
                                      Text(
                                        article.content,
                                        style: Theme.of(context).textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // Related symbols
                                      if (article.relatedSymbols.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          children: article.relatedSymbols.map((s) => Chip(
                                            label: Text(s),
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: EdgeInsets.zero,
                                            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                                          )).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

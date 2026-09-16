/// Market news data models.
/// Mirrors: frontend/src/types/marketNewsTypes.ts

class MarketNews {
  final String title;
  final String content;
  final String source;
  final List<String> relatedSymbols;
  final DateTime publishedAt;

  const MarketNews({
    required this.title,
    required this.content,
    required this.source,
    required this.relatedSymbols,
    required this.publishedAt,
  });

  factory MarketNews.fromJson(Map<String, dynamic> json) => MarketNews(
    title: json['title'] as String? ?? '',
    content: json['content'] as String? ?? '',
    source: json['source'] as String? ?? '',
    relatedSymbols: (json['relatedSymbols'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    publishedAt: json['publishedAt'] != null
        ? DateTime.parse(json['publishedAt'].toString())
        : DateTime.now(),
  );
}

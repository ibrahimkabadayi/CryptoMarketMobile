/// Market data models.
/// Mirrors: frontend/src/types/marketTypes.ts

class Coin {
  final String name;
  final String symbol;
  final double currentPrice;
  final double percentChange;
  final double marketCap;
  final bool isCapped;
  final String? iconUrlPng;
  final String priceChangeStatus; // 'up', 'down', 'none'

  const Coin({
    required this.name,
    required this.symbol,
    required this.currentPrice,
    required this.percentChange,
    required this.marketCap,
    required this.isCapped,
    this.iconUrlPng,
    this.priceChangeStatus = 'none',
  });

  factory Coin.fromJson(Map<String, dynamic> json) => Coin(
    name: json['name'] as String? ?? '',
    symbol: json['symbol'] as String? ?? '',
    currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
    percentChange: (json['percentChange'] as num?)?.toDouble() ?? 0.0,
    marketCap: (json['marketCap'] as num?)?.toDouble() ?? 0.0,
    isCapped: json['isCapped'] as bool? ?? false,
    iconUrlPng: json['iconUrlPng'] as String? ?? json['IconUrlPng'] as String?,
  );

  Coin copyWith({
    String? name,
    String? symbol,
    double? currentPrice,
    double? percentChange,
    double? marketCap,
    bool? isCapped,
    String? iconUrlPng,
    String? priceChangeStatus,
  }) => Coin(
    name: name ?? this.name,
    symbol: symbol ?? this.symbol,
    currentPrice: currentPrice ?? this.currentPrice,
    percentChange: percentChange ?? this.percentChange,
    marketCap: marketCap ?? this.marketCap,
    isCapped: isCapped ?? this.isCapped,
    iconUrlPng: iconUrlPng ?? this.iconUrlPng,
    priceChangeStatus: priceChangeStatus ?? this.priceChangeStatus,
  );

  /// Resolve icon URL: prefer explicit iconUrlPng, fall back to spothq repo.
  String get resolvedIconUrl =>
      iconUrlPng ??
      'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/${symbol.toLowerCase()}.png';
}

class PriceHistory {
  final String symbol;
  final double openPrice;
  final double closePrice;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final int timestamp;

  const PriceHistory({
    required this.symbol,
    required this.openPrice,
    required this.closePrice,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.timestamp,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) => PriceHistory(
    symbol: json['symbol'] as String? ?? '',
    openPrice: (json['openPrice'] as num?)?.toDouble() ?? 0.0,
    closePrice: (json['closePrice'] as num?)?.toDouble() ?? 0.0,
    highPrice: (json['highPrice'] as num?)?.toDouble() ?? 0.0,
    lowPrice: (json['lowPrice'] as num?)?.toDouble() ?? 0.0,
    volume: (json['volume'] as num?)?.toDouble() ?? 0.0,
    timestamp: json['timestamp'] is int
        ? json['timestamp'] as int
        : DateTime.parse(json['timestamp'].toString()).millisecondsSinceEpoch,
  );
}

class PriceUpdateMessage {
  final String symbol;
  final double price;
  final double marketCap;
  final double percentChange;

  const PriceUpdateMessage({
    required this.symbol,
    required this.price,
    required this.marketCap,
    required this.percentChange,
  });

  factory PriceUpdateMessage.fromJson(Map<String, dynamic> json) =>
      PriceUpdateMessage(
        symbol: json['symbol'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        marketCap: (json['marketCap'] as num?)?.toDouble() ?? 0.0,
        percentChange: (json['percentChange'] as num?)?.toDouble() ?? 0.0,
      );
}

class SetLimitOrderRequest {
  final String symbol;
  final double targetPrice;
  final double amount;
  final String orderType; // 'Buy' or 'Sell'

  const SetLimitOrderRequest({
    required this.symbol,
    required this.targetPrice,
    required this.amount,
    required this.orderType,
  });

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'targetPrice': targetPrice,
    'amount': amount,
    'orderType': orderType,
  };
}

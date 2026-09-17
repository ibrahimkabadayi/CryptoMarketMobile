// Price alert data models.
// Mirrors: frontend/src/types/priceAlertTypes.ts

class PriceAlertDto {
  final String id;
  final String userId;
  final String symbol;
  final double targetPrice;
  final bool isAbove;
  final bool isActive;
  final String createdAt;

  const PriceAlertDto({
    required this.id,
    required this.userId,
    required this.symbol,
    required this.targetPrice,
    required this.isAbove,
    required this.isActive,
    required this.createdAt,
  });

  factory PriceAlertDto.fromJson(Map<String, dynamic> json) => PriceAlertDto(
    id: json['id'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    symbol: json['symbol'] as String? ?? '',
    targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0.0,
    isAbove: json['isAbove'] as bool? ?? true,
    isActive: json['isActive'] as bool? ?? true,
    createdAt: json['createdAt'] as String? ?? '',
  );

  PriceAlertDto copyWith({bool? isActive}) => PriceAlertDto(
    id: id,
    userId: userId,
    symbol: symbol,
    targetPrice: targetPrice,
    isAbove: isAbove,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
  );
}

class CreatePriceAlertRequest {
  final String userId;
  final String symbol;
  final double targetPrice;
  final bool isAbove;

  const CreatePriceAlertRequest({
    required this.userId,
    required this.symbol,
    required this.targetPrice,
    required this.isAbove,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'symbol': symbol,
    'targetPrice': targetPrice,
    'isAbove': isAbove,
  };
}

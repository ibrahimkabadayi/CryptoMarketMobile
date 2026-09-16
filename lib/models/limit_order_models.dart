/// Limit order data models.
/// Mirrors: frontend/src/types/limitOrderTypes.ts

class LimitOrderDto {
  final String id;
  final String userId;
  final String walletId;
  final String symbol;
  final double targetPrice;
  final double amount;
  final int orderType; // 1 = Buy, 2 = Sell
  final String? status;
  final String? createdAt;

  const LimitOrderDto({
    required this.id,
    required this.userId,
    required this.walletId,
    required this.symbol,
    required this.targetPrice,
    required this.amount,
    required this.orderType,
    this.status,
    this.createdAt,
  });

  factory LimitOrderDto.fromJson(Map<String, dynamic> json) => LimitOrderDto(
    id: json['id'] as String? ?? '',
    userId: json['userId'] as String? ?? '',
    walletId: json['walletId'] as String? ?? '',
    symbol: json['symbol'] as String? ?? '',
    targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0.0,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    orderType: json['orderType'] as int? ?? 1,
    status: json['status'] as String?,
    createdAt: json['createdAt'] as String?,
  );

  LimitOrderDto copyWith({
    double? targetPrice,
    double? amount,
  }) => LimitOrderDto(
    id: id,
    userId: userId,
    walletId: walletId,
    symbol: symbol,
    targetPrice: targetPrice ?? this.targetPrice,
    amount: amount ?? this.amount,
    orderType: orderType,
    status: status,
    createdAt: createdAt,
  );

  bool get isBuy => orderType == LimitOrderType.buy;
  bool get isSell => orderType == LimitOrderType.sell;
}

class CreateLimitOrderRequest {
  final String userId;
  final String walletId;
  final String symbol;
  final double targetPrice;
  final double amount;
  final int orderType; // 1 = Buy, 2 = Sell

  const CreateLimitOrderRequest({
    required this.userId,
    required this.walletId,
    required this.symbol,
    required this.targetPrice,
    required this.amount,
    required this.orderType,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'walletId': walletId,
    'symbol': symbol,
    'targetPrice': targetPrice,
    'amount': amount,
    'orderType': orderType,
  };
}

class UpdateLimitOrderRequest {
  final double amount;
  final double targetPrice;

  const UpdateLimitOrderRequest({
    required this.amount,
    required this.targetPrice,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'targetPrice': targetPrice,
  };
}

/// Enum-like constants for limit order type.
class LimitOrderType {
  LimitOrderType._();
  static const int buy = 1;
  static const int sell = 2;
}

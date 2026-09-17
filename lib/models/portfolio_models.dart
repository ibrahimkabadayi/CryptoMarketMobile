// Portfolio data models.
// Mirrors: frontend/src/types/portfolioTypes.ts

class Dashboard {
  final String walletId;
  final String address;
  final double fiatBalance;
  final double totalInvestedValue;
  final List<Asset> assets;
  final List<Transaction> recentTransactions;

  const Dashboard({
    required this.walletId,
    required this.address,
    required this.fiatBalance,
    required this.totalInvestedValue,
    required this.assets,
    required this.recentTransactions,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) {
    final data = json['result'] ?? json;
    return Dashboard(
      walletId: data['walletId'] as String? ?? '',
      address: data['address'] as String? ?? '',
      fiatBalance: (data['fiatBalance'] as num?)?.toDouble() ?? 0.0,
      totalInvestedValue:
          (data['totalInvestedValue'] as num?)?.toDouble() ?? 0.0,
      assets: (data['assets'] as List<dynamic>?)
              ?.map((e) => Asset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentTransactions: (data['recentTransactions'] as List<dynamic>?)
              ?.map((e) => Transaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Dashboard copyWith({
    String? walletId,
    String? address,
    double? fiatBalance,
    double? totalInvestedValue,
    List<Asset>? assets,
    List<Transaction>? recentTransactions,
  }) => Dashboard(
    walletId: walletId ?? this.walletId,
    address: address ?? this.address,
    fiatBalance: fiatBalance ?? this.fiatBalance,
    totalInvestedValue: totalInvestedValue ?? this.totalInvestedValue,
    assets: assets ?? this.assets,
    recentTransactions: recentTransactions ?? this.recentTransactions,
  );
}

class Asset {
  final String symbol;
  final double quantity;
  final double averageBuyPrice;
  final double investedAmount;

  const Asset({
    required this.symbol,
    required this.quantity,
    required this.averageBuyPrice,
    required this.investedAmount,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
    symbol: json['symbol'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    averageBuyPrice: (json['averageBuyPrice'] as num?)?.toDouble() ?? 0.0,
    investedAmount: (json['investedAmount'] as num?)?.toDouble() ?? 0.0,
  );
}

class Transaction {
  final String symbol;
  final double amount;
  final double priceAtTransaction;
  final String transactionType;

  const Transaction({
    required this.symbol,
    required this.amount,
    required this.priceAtTransaction,
    required this.transactionType,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    symbol: json['symbol'] as String? ?? '',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    priceAtTransaction:
        (json['priceAtTransaction'] as num?)?.toDouble() ?? 0.0,
    transactionType: _mapTransactionType(json['transactionType']),
  );

  static String _mapTransactionType(dynamic type) {
    if (type is String) return type;
    if (type is int) {
      switch (type) {
        case 0: return 'sell';
        case 1: return 'buy';
        case 2: return 'transfer';
        case 3: return 'deposit';
        case 4: return 'withdraw';
        default: return 'unknown';
      }
    }
    return 'unknown';
  }

  bool get isBuy => transactionType.toLowerCase() == 'buy';
}

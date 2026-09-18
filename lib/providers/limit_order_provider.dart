import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/limit_order_models.dart';
import '../services/limit_order_api.dart';
import 'auth_provider.dart';

/// Limit Order API service provider.
final limitOrderApiProvider = Provider<LimitOrderApi>(
  (ref) => LimitOrderApi(ref.read(apiClientProvider)),
);

/// State for limit orders.
class LimitOrderState {
  final List<LimitOrderDto> orders;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const LimitOrderState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  List<LimitOrderDto> get buyOrders =>
      orders.where((o) => o.isBuy).toList();

  List<LimitOrderDto> get sellOrders =>
      orders.where((o) => o.isSell).toList();

  List<LimitOrderDto> ordersForSymbol(String symbol) =>
      orders.where((o) => o.symbol.toUpperCase() == symbol.toUpperCase()).toList();

  LimitOrderState copyWith({
    List<LimitOrderDto>? orders,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) =>
      LimitOrderState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        successMessage: successMessage,
      );
}

class LimitOrderNotifier extends StateNotifier<LimitOrderState> {
  final LimitOrderApi _api;

  LimitOrderNotifier(this._api) : super(const LimitOrderState());

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _api.getAll();
      state = state.copyWith(orders: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> createOrder(CreateLimitOrderRequest req) async {
    state = state.copyWith(errorMessage: null, successMessage: null);
    try {
      await _api.create(req);
      state = state.copyWith(successMessage: 'Limit order placed successfully');
      await fetchAll();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        errorMessage: e.response?.data?['message']?.toString() ?? 'Failed to place limit order',
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> updateOrder(String id, UpdateLimitOrderRequest req) async {
    state = state.copyWith(errorMessage: null, successMessage: null);
    try {
      await _api.update(id, req);
      state = state.copyWith(successMessage: 'Limit order updated');
      await fetchAll();
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to update limit order');
      return false;
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      await _api.delete(id);
      state = state.copyWith(
        orders: state.orders.where((o) => o.id != id).toList(),
        successMessage: 'Limit order cancelled',
      );
    } catch (_) {
      state = state.copyWith(errorMessage: 'Failed to cancel order');
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final limitOrderProvider =
    StateNotifierProvider<LimitOrderNotifier, LimitOrderState>(
  (ref) => LimitOrderNotifier(ref.read(limitOrderApiProvider)),
);

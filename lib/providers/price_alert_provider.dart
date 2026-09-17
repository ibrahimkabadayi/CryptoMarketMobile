import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_alert_models.dart';
import '../services/auth_api.dart';
import '../services/price_alert_api.dart';
import 'auth_provider.dart';

final priceAlertApiProvider = Provider<PriceAlertApi>(
  (ref) => PriceAlertApi(ref.read(apiClientProvider)),
);

/// State for price alerts.
class PriceAlertState {
  final List<PriceAlertDto> alerts;
  final bool isLoading;
  final bool showAllAlerts;
  final String? errorMessage;
  final String? successMessage;

  const PriceAlertState({
    this.alerts = const [],
    this.isLoading = false,
    this.showAllAlerts = false,
    this.errorMessage,
    this.successMessage,
  });

  List<PriceAlertDto> get activeAlerts =>
      alerts.where((a) => a.isActive).toList();

  int get activeCount => activeAlerts.length;

  List<PriceAlertDto> get sortedAlerts {
    final list = List<PriceAlertDto>.from(alerts);
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  PriceAlertState copyWith({
    List<PriceAlertDto>? alerts,
    bool? isLoading,
    bool? showAllAlerts,
    String? errorMessage,
    String? successMessage,
  }) =>
      PriceAlertState(
        alerts: alerts ?? this.alerts,
        isLoading: isLoading ?? this.isLoading,
        showAllAlerts: showAllAlerts ?? this.showAllAlerts,
        errorMessage: errorMessage,
        successMessage: successMessage,
      );
}

/// Price alert state notifier mirroring frontend/src/stores/priceAlertStore.ts
class PriceAlertNotifier extends StateNotifier<PriceAlertState> {
  final PriceAlertApi _api;
  final AuthApi _authApi;

  PriceAlertNotifier(this._api, this._authApi)
      : super(const PriceAlertState());

  /// Fetch price alerts (active only or all depending on showAllAlerts).
  Future<void> fetchAlerts() async {
    final userId = await _authApi.getUserIdFromToken();
    if (userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = state.showAllAlerts
          ? await _api.getAllAlerts(userId)
          : await _api.getActiveAlerts(userId);
      state = state.copyWith(alerts: list, isLoading: false);
    } catch (e) {
      debugPrint('[PriceAlertNotifier] Failed to fetch alerts: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load price alerts.',
      );
    }
  }

  /// Toggle showing all vs active-only alerts and refetch.
  Future<void> toggleShowAll() async {
    state = state.copyWith(showAllAlerts: !state.showAllAlerts);
    await fetchAlerts();
  }

  /// Create a price alert.
  Future<bool> createAlert(String symbol, double targetPrice, bool isAbove) async {
    final userId = await _authApi.getUserIdFromToken();
    if (userId == null) {
      state = state.copyWith(errorMessage: 'User not authenticated.');
      return false;
    }

    state = state.copyWith(errorMessage: null, successMessage: null);
    try {
      final msg = await _api.createAlert(
        CreatePriceAlertRequest(
          userId: userId,
          symbol: symbol,
          targetPrice: targetPrice,
          isAbove: isAbove,
        ),
      );
      state = state.copyWith(successMessage: msg);
      await fetchAlerts();
      return true;
    } on DioException catch (e) {
      final err = e.response?.data?['message']?.toString() ?? 'Failed to create price alert';
      state = state.copyWith(errorMessage: err);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'An unexpected error occurred.');
      return false;
    }
  }

  /// Deactivate an active price alert.
  Future<void> deactivateAlert(String alertId) async {
    final userId = await _authApi.getUserIdFromToken();
    if (userId == null) return;

    try {
      await _api.deactivateAlert(alertId, userId);
      final updated = state.alerts.map((a) {
        if (a.id == alertId) {
          return a.copyWith(isActive: false);
        }
        return a;
      }).toList();

      state = state.copyWith(
        alerts: state.showAllAlerts ? updated : updated.where((a) => a.isActive).toList(),
        successMessage: 'Alert deactivated',
      );
    } catch (e) {
      debugPrint('[PriceAlertNotifier] Failed to deactivate: $e');
      state = state.copyWith(errorMessage: 'Failed to deactivate alert');
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

final priceAlertProvider =
    StateNotifierProvider<PriceAlertNotifier, PriceAlertState>(
  (ref) => PriceAlertNotifier(
    ref.read(priceAlertApiProvider),
    ref.read(authApiProvider),
  ),
);

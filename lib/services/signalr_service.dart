import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';

/// SignalR Service structure for managing real-time WebSocket connections.
/// Mirrors: frontend/src/api/signalRApi.ts
///
/// Designed to connect to the 4 backend hubs:
/// 1. /hubs/market -> ReceivePriceUpdate, ReceiveHistoryUpdate
/// 2. /hubs/portfolio -> UpdatePortfolio, NewTransaction, UpdateBalance
/// 3. /hubs/notifications -> ReceiveNotification, ReceivePriceAlert, DeactivatePriceAlert
/// 4. /hubs/price-alerts -> PublishNews
enum SignalRConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

typedef SignalREventCallback = void Function(dynamic data);

class SignalRService {
  static const String marketHub = '/hubs/market';
  static const String portfolioHub = '/hubs/portfolio';
  static const String notificationsHub = '/hubs/notifications';
  static const String priceAlertsHub = '/hubs/price-alerts';

  final String _baseUrl;
  final Map<String, SignalRConnectionState> _connectionStates = {};
  final Map<String, List<SignalREventCallback>> _eventListeners = {};

  SignalRService({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConstants.apiBaseUrl;

  String get baseUrl => _baseUrl;

  SignalRConnectionState getState(String hubUrl) =>
      _connectionStates[hubUrl] ?? SignalRConnectionState.disconnected;

  bool isConnected(String hubUrl) =>
      getState(hubUrl) == SignalRConnectionState.connected;

  /// Builds connection configuration for a hub.
  void buildConnection(String hubUrl, {bool isAuthRequired = false}) {
    if (_connectionStates.containsKey(hubUrl)) {
      debugPrint('[SignalR] Connection for $hubUrl already initialized.');
      return;
    }
    _connectionStates[hubUrl] = SignalRConnectionState.disconnected;
    debugPrint('[SignalR] Built connection profile for $hubUrl (auth: $isAuthRequired)');
  }

  /// Starts a specific hub connection or all initialized hub connections.
  Future<void> startConnection([String? hubUrl]) async {
    final hubsToStart = hubUrl != null ? [hubUrl] : _connectionStates.keys.toList();
    for (final hub in hubsToStart) {
      _connectionStates[hub] = SignalRConnectionState.connecting;
      debugPrint('[SignalR] Connecting to $hub...');
      // Simulated/deferred connection readiness
      await Future.delayed(const Duration(milliseconds: 100));
      _connectionStates[hub] = SignalRConnectionState.connected;
      debugPrint('[SignalR] Connected to $hub.');
    }
  }

  /// Register an event callback on a specific hub or across all hubs.
  void on(String eventName, SignalREventCallback callback, {String? hubUrl}) {
    final key = hubUrl != null ? '$hubUrl:$eventName' : eventName;
    _eventListeners.putIfAbsent(key, () => []).add(callback);
    debugPrint('[SignalR] Registered listener for $key');
  }

  /// Unregister an event callback.
  void off(String eventName, {String? hubUrl, SignalREventCallback? callback}) {
    final key = hubUrl != null ? '$hubUrl:$eventName' : eventName;
    if (callback != null) {
      _eventListeners[key]?.remove(callback);
    } else {
      _eventListeners.remove(key);
    }
    debugPrint('[SignalR] Unregistered listener(s) for $key');
  }

  /// Dispatch an incoming event to registered callbacks.
  void dispatchEvent(String eventName, dynamic data, {String? hubUrl}) {
    final key = hubUrl != null ? '$hubUrl:$eventName' : eventName;
    final listeners = [
      ...?_eventListeners[key],
      if (hubUrl != null) ...?_eventListeners[eventName],
    ];
    for (final callback in listeners) {
      try {
        callback(data);
      } catch (e) {
        debugPrint('[SignalR] Error in handler for $eventName: $e');
      }
    }
  }

  /// Invokes a server method on a hub.
  Future<dynamic> invoke(String methodName, String hubUrl, [List<dynamic>? args]) async {
    debugPrint('[SignalR] Invoking $methodName on $hubUrl with args $args');
    return null;
  }

  /// Stop a connection or all connections.
  Future<void> stopConnection([String? hubUrl]) async {
    final hubsToStop = hubUrl != null ? [hubUrl] : _connectionStates.keys.toList();
    for (final hub in hubsToStop) {
      _connectionStates[hub] = SignalRConnectionState.disconnected;
      debugPrint('[SignalR] Disconnected from $hub');
    }
  }

  /// Initialize all 4 core hubs.
  void initCoreHubs() {
    buildConnection(marketHub, isAuthRequired: false);
    buildConnection(portfolioHub, isAuthRequired: true);
    buildConnection(notificationsHub, isAuthRequired: true);
    buildConnection(priceAlertsHub, isAuthRequired: true);
  }
}

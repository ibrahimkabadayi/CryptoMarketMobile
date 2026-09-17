import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_models.dart';
import '../services/auth_api.dart';
import '../services/notification_api.dart';
import 'auth_provider.dart';

final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.read(apiClientProvider)),
);

/// State for notifications.
class NotificationState {
  final List<NotificationDto> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  List<NotificationDto> get sortedNotifications {
    final list = List<NotificationDto>.from(notifications);
    list.sort((a, b) {
      final aDate = DateTime.tryParse(a.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b.createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  NotificationState copyWith({
    List<NotificationDto>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

/// Notification state notifier mirroring frontend/src/stores/notificationStore.ts
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationApi _notificationApi;
  final AuthApi _authApi;

  NotificationNotifier(this._notificationApi, this._authApi)
      : super(const NotificationState());

  /// Fetch all notifications for the authenticated user.
  Future<void> fetchNotifications() async {
    final userId = await _authApi.getUserIdFromToken();
    if (userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _notificationApi.getUserNotifications(userId);
      final unread = list.where((n) => !n.isRead).length;
      state = state.copyWith(
        notifications: list,
        unreadCount: unread,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('[NotificationNotifier] Failed to fetch: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load notifications.',
      );
    }
  }

  /// Fetch the unread notification count.
  Future<void> fetchUnreadCount() async {
    final userId = await _authApi.getUserIdFromToken();
    if (userId == null) return;

    try {
      final count = await _notificationApi.getUnreadCount(userId);
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      debugPrint('[NotificationNotifier] Failed to fetch unread count: $e');
    }
  }

  /// Mark a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    final userId = await _authApi.getUserIdFromToken();
    if (userId == null) return;

    try {
      await _notificationApi.markAsRead(notificationId, userId);
      final updatedList = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final newUnread = updatedList.where((n) => !n.isRead).length;
      state = state.copyWith(notifications: updatedList, unreadCount: newUnread);
    } catch (e) {
      debugPrint('[NotificationNotifier] Failed to mark as read: $e');
    }
  }

  /// Mark all notifications as read.
  Future<void> markAllAsRead() async {
    final userId = await _authApi.getUserIdFromToken();
    if (userId == null) return;

    try {
      await _notificationApi.markAllAsRead(userId);
      final updatedList = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updatedList, unreadCount: 0);
    } catch (e) {
      debugPrint('[NotificationNotifier] Failed to mark all as read: $e');
    }
  }

  /// Add a real-time incoming notification.
  void addNotification(NotificationDto notification) {
    final updated = [notification, ...state.notifications];
    final unread = updated.where((n) => !n.isRead).length;
    state = state.copyWith(notifications: updated, unreadCount: unread);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(
    ref.read(notificationApiProvider),
    ref.read(authApiProvider),
  ),
);

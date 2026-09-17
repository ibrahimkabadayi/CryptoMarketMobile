import 'package:dio/dio.dart';
import '../models/notification_models.dart';
import 'api_client.dart';

/// Notification API service communicating with Notifications.API via gateway.
/// Mirrors: frontend/src/api/notificationApi.ts
class NotificationApi {
  final ApiClient _apiClient;

  NotificationApi(this._apiClient);

  /// Fetch all notifications for a given user.
  Future<List<NotificationDto>> getUserNotifications(String userId) async {
    final response = await _apiClient.dio.get('/api/notifications/user/$userId');
    return (response.data as List)
        .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get the total count of unread notifications for a user.
  Future<int> getUnreadCount(String userId) async {
    final response = await _apiClient.dio.get('/api/notifications/user/$userId/unread-count');
    return (response.data as num?)?.toInt() ?? 0;
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId, String userId) async {
    await _apiClient.dio.put(
      '/api/notifications/$notificationId/read',
      data: '"$userId"',
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  /// Mark all notifications for a user as read.
  Future<void> markAllAsRead(String userId) async {
    await _apiClient.dio.put('/api/notifications/user/$userId/mark-all-read');
  }

  /// Create a notification.
  Future<void> createNotification(CreateNotificationRequest request) async {
    await _apiClient.dio.post('/api/notifications', data: request.toJson());
  }
}

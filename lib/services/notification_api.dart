import '../models/notification_models.dart';
import 'api_client.dart';

/// Notification API service communicating with Notifications.API via gateway.
/// Mirrors: frontend/src/api/notificationApi.ts
class NotificationApi {
  final ApiClient _apiClient;

  NotificationApi(this._apiClient);

  /// Fetch all notifications for the authenticated user.
  Future<List<NotificationDto>> getUserNotifications() async {
    final response = await _apiClient.dio.get('/api/notifications');
    return (response.data as List)
        .map((e) => NotificationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get the total count of unread notifications for the authenticated user.
  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get('/api/notifications/unread-count');
    return (response.data as num?)?.toInt() ?? 0;
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.dio.put('/api/notifications/$notificationId/read');
  }

  /// Mark all notifications for the authenticated user as read.
  Future<void> markAllAsRead() async {
    await _apiClient.dio.put('/api/notifications/mark-all-read');
  }

  /// Create a notification.
  Future<void> createNotification(CreateNotificationRequest request) async {
    await _apiClient.dio.post('/api/notifications', data: request.toJson());
  }
}

/// Notification data models.
/// Mirrors: frontend/src/types/notificationTypes.ts

class NotificationDto {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;
  final String? relatedEntityId;

  const NotificationDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedEntityId,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      NotificationDto(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: json['type'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
        relatedEntityId: json['relatedEntityId'] as String?,
      );

  NotificationDto copyWith({bool? isRead}) => NotificationDto(
    id: id,
    userId: userId,
    title: title,
    message: message,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    relatedEntityId: relatedEntityId,
  );
}

class CreateNotificationRequest {
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? relatedEntityId;

  const CreateNotificationRequest({
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedEntityId,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    if (relatedEntityId != null) 'relatedEntityId': relatedEntityId,
  };
}

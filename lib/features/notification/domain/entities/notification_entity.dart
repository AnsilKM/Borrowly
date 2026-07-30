import 'package:equatable/equatable.dart';

enum NotificationType { request, chat, system }

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final DateTime timestamp;
  final String? targetRoute;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.timestamp,
    this.targetRoute,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    bool? isRead,
    DateTime? timestamp,
    String? targetRoute,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      targetRoute: targetRoute ?? this.targetRoute,
    );
  }

  @override
  List<Object?> get props => [id, title, body, type, isRead, timestamp, targetRoute];
}

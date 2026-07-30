import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final String? imageUrl;
  final bool isRead;
  final DateTime timestamp;

  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.imageUrl,
    this.isRead = false,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        text,
        imageUrl,
        isRead,
        timestamp,
      ];
}

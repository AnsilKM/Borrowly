import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemImage;
  final String otherParticipantId;
  final String otherParticipantName;
  final String? otherParticipantAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ConversationEntity({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemImage,
    required this.otherParticipantId,
    required this.otherParticipantName,
    this.otherParticipantAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemTitle,
        itemImage,
        otherParticipantId,
        otherParticipantName,
        otherParticipantAvatar,
        lastMessage,
        lastMessageTime,
        unreadCount,
      ];
}

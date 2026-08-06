import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemImage;
  final String borrowerId;
  final String ownerId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  // Helper fields for UI display (mapped from users table join or metadata)
  final String otherParticipantName;
  final String? otherParticipantAvatar;

  const ConversationEntity({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemImage,
    required this.borrowerId,
    required this.ownerId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.otherParticipantName = 'Neighbor',
    this.otherParticipantAvatar,
  });

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemTitle,
        itemImage,
        borrowerId,
        ownerId,
        lastMessage,
        lastMessageTime,
        unreadCount,
        otherParticipantName,
        otherParticipantAvatar,
      ];
}

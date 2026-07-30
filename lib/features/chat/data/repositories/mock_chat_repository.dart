import 'package:borrowly/features/chat/domain/entities/chat_message_entity.dart';
import 'package:borrowly/features/chat/domain/entities/conversation_entity.dart';
import 'package:borrowly/features/chat/domain/repositories/chat_repository.dart';

class MockChatRepository implements ChatRepository {
  final List<ConversationEntity> _conversations = [
    ConversationEntity(
      id: 'conv_1',
      itemId: 'item_1',
      itemTitle: 'DeWalt 20V Cordless Hammer Drill',
      itemImage: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600',
      otherParticipantId: 'user_1',
      otherParticipantName: 'Marcus Vance',
      otherParticipantAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      lastMessage: 'Hi! Is tomorrow morning good for physical pickup on Oakwood Drive?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 25)),
      unreadCount: 1,
    ),
    ConversationEntity(
      id: 'conv_2',
      itemId: 'item_2',
      itemTitle: 'Coleman 4-Person Camping Tent',
      itemImage: 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=600',
      otherParticipantId: 'user_2',
      otherParticipantName: 'Sarah Jenkins',
      otherParticipantAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      lastMessage: 'Thanks for returning the tent in great shape!',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
    ),
  ];

  final Map<String, List<ChatMessageEntity>> _messagesMap = {
    'conv_1': [
      ChatMessageEntity(
        id: 'msg_1',
        conversationId: 'conv_1',
        senderId: 'user_1',
        senderName: 'Marcus Vance',
        text: 'Hello neighbor! I received your borrow request for the DeWalt drill.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ChatMessageEntity(
        id: 'msg_2',
        conversationId: 'conv_1',
        senderId: 'guest_user_id',
        senderName: 'Alex Morgan',
        text: 'Awesome! Can I pick it up at 10 AM?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      ChatMessageEntity(
        id: 'msg_3',
        conversationId: 'conv_1',
        senderId: 'user_1',
        senderName: 'Marcus Vance',
        text: 'Hi! Is tomorrow morning good for physical pickup on Oakwood Drive?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ],
  };

  @override
  Future<List<ConversationEntity>> getConversations(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _conversations;
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _messagesMap[conversationId] ?? [];
  }

  @override
  Future<ChatMessageEntity> sendMessage(ChatMessageEntity message) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list = _messagesMap[message.conversationId] ?? [];
    list.add(message);
    _messagesMap[message.conversationId] = list;
    return message;
  }
}

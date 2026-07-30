import '../entities/chat_message_entity.dart';
import '../entities/conversation_entity.dart';

abstract class ChatRepository {
  Future<List<ConversationEntity>> getConversations(String userId);
  Future<List<ChatMessageEntity>> getMessages(String conversationId);
  Future<ChatMessageEntity> sendMessage(ChatMessageEntity message);
}

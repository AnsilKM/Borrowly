import 'package:flutter/foundation.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import 'mock_chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  final MockChatRepository _fallbackMockRepo = MockChatRepository();

  ConversationEntity _mapRowToConversation(Map<String, dynamic> row) {
    return ConversationEntity(
      id: row['id'] as String? ?? '',
      itemId: row['item_id'] as String? ?? '',
      itemTitle: row['item_title'] as String? ?? 'Borrow Item',
      itemImage: row['item_image'] as String? ?? 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600',
      otherParticipantId: row['other_participant_id'] as String? ?? 'user_1',
      otherParticipantName: row['other_participant_name'] as String? ?? 'Neighbor',
      otherParticipantAvatar: row['other_participant_avatar'] as String?,
      lastMessage: row['last_message'] as String? ?? '',
      lastMessageTime: DateTime.tryParse(row['last_message_time'] as String? ?? '') ?? DateTime.now(),
      unreadCount: row['unread_count'] as int? ?? 0,
    );
  }

  ChatMessageEntity _mapRowToMessage(Map<String, dynamic> row) {
    return ChatMessageEntity(
      id: row['id'] as String? ?? '',
      conversationId: row['conversation_id'] as String? ?? '',
      senderId: row['sender_id'] as String? ?? '',
      senderName: row['sender_name'] as String? ?? 'Neighbor',
      text: row['text'] as String? ?? '',
      imageUrl: row['image_url'] as String?,
      isRead: row['is_read'] as bool? ?? false,
      timestamp: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  Future<List<ConversationEntity>> getConversations(String userId) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client
            .from('conversations')
            .select()
            .order('last_message_time', ascending: false);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapRowToConversation(r as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Supabase getConversations fallback to local: $e');
      }
    }

    return _fallbackMockRepo.getConversations(userId);
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client
            .from('messages')
            .select()
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: true);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapRowToMessage(r as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Supabase getMessages fallback to local: $e');
      }
    }

    return _fallbackMockRepo.getMessages(conversationId);
  }

  @override
  Future<ChatMessageEntity> sendMessage(ChatMessageEntity message) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final row = {
          'conversation_id': message.conversationId,
          'sender_id': message.senderId,
          'sender_name': message.senderName,
          'text': message.text,
          'image_url': message.imageUrl,
          'is_read': false,
        };

        final response = await client.from('messages').insert(row).select().single();
        return _mapRowToMessage(response);
      } catch (e) {
        debugPrint('Supabase sendMessage fallback to local: $e');
      }
    }

    return _fallbackMockRepo.sendMessage(message);
  }
}

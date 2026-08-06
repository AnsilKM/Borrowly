import '../../../../core/network/supabase_service.dart';
import '../../../../core/utils/borrowly_logger.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  ConversationEntity _mapRowToConversation(Map<String, dynamic> row, String currentUserId) {
    final borrowerId = row['borrower_id'] as String? ?? '';
    final ownerId = row['owner_id'] as String? ?? '';

    // Logic to determine "other participant" info based on who is viewing
    final isBorrower = currentUserId == borrowerId;

    return ConversationEntity(
      id: row['id'] as String? ?? '',
      itemId: row['item_id'] as String? ?? '',
      itemTitle: row['item_title'] as String? ?? 'Borrow Item',
      itemImage: row['item_image'] as String? ?? 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600',
      borrowerId: borrowerId,
      ownerId: ownerId,
      lastMessage: row['last_message'] as String? ?? '',
      lastMessageTime: DateTime.tryParse(row['last_message_time'] as String? ?? '') ?? DateTime.now(),
      unreadCount: row['unread_count'] as int? ?? 0,
      // For now we use placeholders; in a real app these would come from a join or profile fetch
      otherParticipantName: isBorrower ? 'Owner' : 'Borrower',
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
    BorrowlyLogger.event('Chat: Fetch Conversations', parameters: {'userId': userId});
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client
            .from('conversations')
            .select()
            .or('borrower_id.eq.$userId,owner_id.eq.$userId')
            .order('last_message_time', ascending: false);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapRowToConversation(r as Map<String, dynamic>, userId)).toList();
      } catch (e) {
        BorrowlyLogger.warning('getConversations error: $e');
      }
    }

    return [];
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId) async {
    BorrowlyLogger.event('Chat: Fetch Messages', parameters: {'conversationId': conversationId});
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
        BorrowlyLogger.warning('getMessages error: $e');
      }
    }

    return [];
  }

  @override
  Future<ChatMessageEntity> sendMessage(ChatMessageEntity message) async {
    BorrowlyLogger.event('Chat: Send Message', parameters: {
      'conversationId': message.conversationId,
      'senderId': message.senderId,
    });

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
        final sent = _mapRowToMessage(response);
        BorrowlyLogger.info('Message sent via Supabase: ${sent.id}');
        return sent;
      } catch (e, stack) {
        BorrowlyLogger.error('sendMessage error', e, stack);
        rethrow;
      }
    }

    throw Exception('Supabase service is not available');
  }

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String itemId,
    required String borrowerId,
    required String ownerId,
    required String itemTitle,
    required String itemImage,
  }) async {
    final client = SupabaseService.client;
    if (client == null || !SupabaseService.isConfigured) {
      throw Exception('Supabase service is not available');
    }

    try {
      // 1. Check if conversation already exists
      final existing = await client
          .from('conversations')
          .select()
          .eq('item_id', itemId)
          .eq('borrower_id', borrowerId)
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (existing != null) {
        return _mapRowToConversation(existing as Map<String, dynamic>, borrowerId);
      }

      // 2. Create new conversation if not found
      final row = {
        'item_id': itemId,
        'item_title': itemTitle,
        'item_image': itemImage,
        'borrower_id': borrowerId,
        'owner_id': ownerId,
        'last_message': 'Started a new conversation',
        'last_message_time': DateTime.now().toIso8601String(),
      };

      final response = await client.from('conversations').insert(row).select().single();
      return _mapRowToConversation(response as Map<String, dynamic>, borrowerId);
    } catch (e, stack) {
      BorrowlyLogger.error('getOrCreateConversation error', e, stack);
      rethrow;
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:borrowly/features/chat/data/repositories/supabase_chat_repository.dart';
import 'package:borrowly/features/chat/domain/entities/chat_message_entity.dart';
import 'package:borrowly/features/chat/domain/entities/conversation_entity.dart';
import 'package:borrowly/features/chat/domain/repositories/chat_repository.dart';
import 'package:borrowly/features/chat/domain/usecases/get_conversations_usecase.dart';
import 'package:borrowly/features/chat/domain/usecases/send_message_usecase.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository();
});

final getConversationsUseCaseProvider = Provider<GetConversationsUseCase>((ref) {
  return GetConversationsUseCase(ref.watch(chatRepositoryProvider));
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final conversationsProvider = FutureProvider<List<ConversationEntity>>((ref) async {
  final usecase = ref.watch(getConversationsUseCaseProvider);
  final result = await usecase('guest_user_id');
  return result.fold(
    onSuccess: (list) => list,
    onError: (failure) => throw Exception(failure.message),
  );
});

final conversationMessagesProvider = FutureProvider.family<List<ChatMessageEntity>, String>((ref, convId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(convId);
});

class ChatController extends StateNotifier<List<ChatMessageEntity>> {
  final ChatRepository _repository;
  final String _conversationId;

  ChatController(this._repository, this._conversationId) : super([]) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final msgs = await _repository.getMessages(_conversationId);
    state = msgs;
  }

  Future<void> sendTextMessage({
    required String text,
    required String senderId,
    required String senderName,
  }) async {
    if (text.trim().isEmpty) return;

    final newMsg = ChatMessageEntity(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: _conversationId,
      senderId: senderId,
      senderName: senderName,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    state = [...state, newMsg];
    await _repository.sendMessage(newMsg);
  }
}

final chatControllerProvider = StateNotifierProvider.family<ChatController, List<ChatMessageEntity>, String>((ref, convId) {
  return ChatController(ref.watch(chatRepositoryProvider), convId);
});

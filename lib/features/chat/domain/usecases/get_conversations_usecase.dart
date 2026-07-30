import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/conversation_entity.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase implements UseCase<List<ConversationEntity>, String> {
  final ChatRepository repository;

  GetConversationsUseCase(this.repository);

  @override
  Future<Result<List<ConversationEntity>, Failure>> call(String userId) async {
    try {
      final conversations = await repository.getConversations(userId);
      return Success(conversations);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

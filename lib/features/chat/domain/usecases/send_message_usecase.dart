import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/chat_message_entity.dart';
import '../repositories/chat_repository.dart';

class SendMessageUseCase implements UseCase<ChatMessageEntity, ChatMessageEntity> {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Result<ChatMessageEntity, Failure>> call(ChatMessageEntity message) async {
    try {
      final sent = await repository.sendMessage(message);
      return Success(sent);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

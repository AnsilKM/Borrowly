import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class ContinueAsGuestUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  ContinueAsGuestUseCase(this.repository);

  @override
  Future<Result<UserEntity, Failure>> call(NoParams params) async {
    try {
      final guest = await repository.continueAsGuest();
      return Success(guest);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }
}

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Result<UserEntity?, Failure>> call(NoParams params) async {
    try {
      final user = await repository.getCurrentUser();
      return Success(user);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }
}

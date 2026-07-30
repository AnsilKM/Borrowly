import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase implements UseCase<UserEntity, UserEntity> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Result<UserEntity, Failure>> call(UserEntity profile) async {
    try {
      final updated = await repository.updateProfile(profile);
      return Success(updated);
    } catch (e) {
      return Error(AuthFailure(e.toString()));
    }
  }
}

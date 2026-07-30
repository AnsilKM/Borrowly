import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/borrow_request_entity.dart';
import '../repositories/borrow_repository.dart';

class CreateBorrowRequestUseCase implements UseCase<BorrowRequestEntity, BorrowRequestEntity> {
  final BorrowRepository repository;

  CreateBorrowRequestUseCase(this.repository);

  @override
  Future<Result<BorrowRequestEntity, Failure>> call(BorrowRequestEntity request) async {
    try {
      final result = await repository.createBorrowRequest(request);
      return Success(result);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

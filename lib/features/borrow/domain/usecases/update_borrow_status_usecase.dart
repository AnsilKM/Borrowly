import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/borrow_request_entity.dart';
import '../repositories/borrow_repository.dart';

class UpdateBorrowStatusParams extends Equatable {
  final String requestId;
  final BorrowRequestStatus newStatus;

  const UpdateBorrowStatusParams({
    required this.requestId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [requestId, newStatus];
}

class UpdateBorrowStatusUseCase implements UseCase<BorrowRequestEntity, UpdateBorrowStatusParams> {
  final BorrowRepository repository;

  UpdateBorrowStatusUseCase(this.repository);

  @override
  Future<Result<BorrowRequestEntity, Failure>> call(UpdateBorrowStatusParams params) async {
    try {
      final updated = await repository.updateRequestStatus(
        requestId: params.requestId,
        newStatus: params.newStatus,
      );
      return Success(updated);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

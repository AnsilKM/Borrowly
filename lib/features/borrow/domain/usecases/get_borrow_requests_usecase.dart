import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/borrow_request_entity.dart';
import '../repositories/borrow_repository.dart';

class GetBorrowRequestsParams extends Equatable {
  final String userId;
  final bool isOwner;

  const GetBorrowRequestsParams({
    required this.userId,
    this.isOwner = false,
  });

  @override
  List<Object?> get props => [userId, isOwner];
}

class GetBorrowRequestsUseCase implements UseCase<List<BorrowRequestEntity>, GetBorrowRequestsParams> {
  final BorrowRepository repository;

  GetBorrowRequestsUseCase(this.repository);

  @override
  Future<Result<List<BorrowRequestEntity>, Failure>> call(GetBorrowRequestsParams params) async {
    try {
      final list = await repository.getBorrowRequests(
        userId: params.userId,
        isOwner: params.isOwner,
      );
      return Success(list);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

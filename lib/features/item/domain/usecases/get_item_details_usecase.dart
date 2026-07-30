import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

class GetItemDetailsUseCase implements UseCase<ItemEntity?, String> {
  final ItemRepository repository;

  GetItemDetailsUseCase(this.repository);

  @override
  Future<Result<ItemEntity?, Failure>> call(String id) async {
    try {
      final item = await repository.getItemById(id);
      return Success(item);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

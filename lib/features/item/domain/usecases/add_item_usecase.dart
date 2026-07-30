import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

class AddItemUseCase implements UseCase<ItemEntity, ItemEntity> {
  final ItemRepository repository;

  AddItemUseCase(this.repository);

  @override
  Future<Result<ItemEntity, Failure>> call(ItemEntity item) async {
    try {
      final created = await repository.addItem(item);
      return Success(created);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

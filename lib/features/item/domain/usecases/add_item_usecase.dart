import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

class AddItemParams {
  final ItemEntity item;
  final double? lat;
  final double? lng;

  const AddItemParams({required this.item, this.lat, this.lng});
}

class AddItemUseCase implements UseCase<ItemEntity, AddItemParams> {
  final ItemRepository repository;

  AddItemUseCase(this.repository);

  @override
  Future<Result<ItemEntity, Failure>> call(AddItemParams params) async {
    try {
      final created = await repository.addItem(params.item, lat: params.lat, lng: params.lng);
      return Success(created);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

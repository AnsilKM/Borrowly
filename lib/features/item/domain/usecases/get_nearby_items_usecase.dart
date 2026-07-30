import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/item_category.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

class GetNearbyItemsParams extends Equatable {
  final double maxDistanceKm;
  final ItemCategory category;

  const GetNearbyItemsParams({
    required this.maxDistanceKm,
    this.category = ItemCategory.all,
  });

  @override
  List<Object?> get props => [maxDistanceKm, category];
}

class GetNearbyItemsUseCase implements UseCase<List<ItemEntity>, GetNearbyItemsParams> {
  final ItemRepository repository;

  GetNearbyItemsUseCase(this.repository);

  @override
  Future<Result<List<ItemEntity>, Failure>> call(GetNearbyItemsParams params) async {
    try {
      final items = await repository.getNearbyItems(
        maxDistanceKm: params.maxDistanceKm,
        category: params.category,
      );
      return Success(items);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

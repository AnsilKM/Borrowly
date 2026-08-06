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
  final double? lat;
  final double? lng;

  const GetNearbyItemsParams({
    required this.maxDistanceKm,
    this.category = ItemCategory.all,
    this.lat,
    this.lng,
  });

  @override
  List<Object?> get props => [maxDistanceKm, category, lat, lng];
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
        lat: params.lat,
        lng: params.lng,
      );
      return Success(items);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

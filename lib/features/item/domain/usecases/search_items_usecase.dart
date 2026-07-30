import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/item_category.dart';
import '../entities/item_entity.dart';
import '../repositories/item_repository.dart';

class SearchItemsParams extends Equatable {
  final String query;
  final double maxDistanceKm;
  final ItemCategory category;
  final ItemPricingFilter pricingFilter;
  final bool onlyAvailable;
  final ItemSortOption sortBy;

  const SearchItemsParams({
    required this.query,
    required this.maxDistanceKm,
    this.category = ItemCategory.all,
    this.pricingFilter = ItemPricingFilter.all,
    this.onlyAvailable = false,
    this.sortBy = ItemSortOption.nearest,
  });

  @override
  List<Object?> get props => [
        query,
        maxDistanceKm,
        category,
        pricingFilter,
        onlyAvailable,
        sortBy,
      ];
}

class SearchItemsUseCase implements UseCase<List<ItemEntity>, SearchItemsParams> {
  final ItemRepository repository;

  SearchItemsUseCase(this.repository);

  @override
  Future<Result<List<ItemEntity>, Failure>> call(SearchItemsParams params) async {
    try {
      final items = await repository.searchItems(
        query: params.query,
        maxDistanceKm: params.maxDistanceKm,
        category: params.category,
        pricingFilter: params.pricingFilter,
        onlyAvailable: params.onlyAvailable,
        sortBy: params.sortBy,
      );
      return Success(items);
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}

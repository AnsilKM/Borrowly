import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:borrowly/features/item/domain/entities/item_category.dart';
import 'package:borrowly/features/item/domain/entities/item_entity.dart';
import 'package:borrowly/features/item/domain/repositories/item_repository.dart';
import 'package:borrowly/features/item/domain/usecases/search_items_usecase.dart';
import 'package:borrowly/features/item/presentation/providers/home_items_provider.dart';

class SearchState {
  final String query;
  final double maxDistanceKm;
  final ItemCategory category;
  final ItemPricingFilter pricingFilter;
  final bool onlyAvailable;
  final ItemSortOption sortBy;

  const SearchState({
    this.query = '',
    this.maxDistanceKm = 5.0,
    this.category = ItemCategory.all,
    this.pricingFilter = ItemPricingFilter.all,
    this.onlyAvailable = false,
    this.sortBy = ItemSortOption.nearest,
  });

  int get activeFilterCount {
    int count = 0;
    if (maxDistanceKm < 5.0) count++;
    if (category != ItemCategory.all) count++;
    if (pricingFilter != ItemPricingFilter.all) count++;
    if (onlyAvailable) count++;
    if (sortBy != ItemSortOption.nearest) count++;
    return count;
  }

  SearchState copyWith({
    String? query,
    double? maxDistanceKm,
    ItemCategory? category,
    ItemPricingFilter? pricingFilter,
    bool? onlyAvailable,
    ItemSortOption? sortBy,
  }) {
    return SearchState(
      query: query ?? this.query,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      category: category ?? this.category,
      pricingFilter: pricingFilter ?? this.pricingFilter,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void setQuery(String query) => state = state.copyWith(query: query);
  void setMaxDistance(double radius) => state = state.copyWith(maxDistanceKm: radius);
  void setCategory(ItemCategory category) => state = state.copyWith(category: category);
  void setPricingFilter(ItemPricingFilter filter) => state = state.copyWith(pricingFilter: filter);
  void setOnlyAvailable(bool value) => state = state.copyWith(onlyAvailable: value);
  void setSortBy(ItemSortOption sort) => state = state.copyWith(sortBy: sort);

  void resetFilters() => state = SearchState(query: state.query);
}

final searchStateProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

final searchItemsUseCaseProvider = Provider<SearchItemsUseCase>((ref) {
  return SearchItemsUseCase(ref.watch(itemRepositoryProvider));
});

final searchResultsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final usecase = ref.watch(searchItemsUseCaseProvider);
  final state = ref.watch(searchStateProvider);

  final result = await usecase(SearchItemsParams(
    query: state.query,
    maxDistanceKm: state.maxDistanceKm,
    category: state.category,
    pricingFilter: state.pricingFilter,
    onlyAvailable: state.onlyAvailable,
    sortBy: state.sortBy,
  ));

  return result.fold(
    onSuccess: (items) => items,
    onError: (failure) => throw Exception(failure.message),
  );
});

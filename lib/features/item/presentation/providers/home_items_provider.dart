import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_item_repository.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/item_repository.dart';
import '../../domain/usecases/get_nearby_items_usecase.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return SupabaseItemRepository();
});

final getNearbyItemsUseCaseProvider = Provider<GetNearbyItemsUseCase>((ref) {
  return GetNearbyItemsUseCase(ref.watch(itemRepositoryProvider));
});

final selectedRadiusProvider = StateProvider<int>((ref) => 5); // 1, 2, 3, 5 km

final selectedCategoryProvider = StateProvider<ItemCategory>((ref) => ItemCategory.all);

final nearbyItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final usecase = ref.watch(getNearbyItemsUseCaseProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();
  final category = ref.watch(selectedCategoryProvider);

  final result = await usecase(GetNearbyItemsParams(
    maxDistanceKm: maxRadius,
    category: category,
  ));

  return result.fold(
    onSuccess: (items) => items,
    onError: (failure) => throw Exception(failure.message),
  );
});

final freeItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();

  return repository.getFreeItems(maxDistanceKm: maxRadius);
});

final recentlyAddedItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();

  return repository.getRecentlyAdded(maxDistanceKm: maxRadius);
});

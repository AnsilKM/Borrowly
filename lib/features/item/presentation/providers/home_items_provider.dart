import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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

/// Explore / Home Screen feed: excludes current user's own listings so neighbors' items are shown
final nearbyItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final usecase = ref.watch(getNearbyItemsUseCaseProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();
  final category = ref.watch(selectedCategoryProvider);
  final user = ref.watch(authProvider).user;

  final result = await usecase(GetNearbyItemsParams(
    maxDistanceKm: maxRadius,
    category: category,
  ));

  return result.fold(
    onSuccess: (items) {
      if (user != null && !user.isGuest) {
        return items.where((i) => i.ownerId != user.id && i.ownerName != user.fullName).toList();
      }
      return items;
    },
    onError: (failure) => throw Exception(failure.message),
  );
});

final freeItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();
  final user = ref.watch(authProvider).user;

  final items = await repository.getFreeItems(maxDistanceKm: maxRadius);
  if (user != null && !user.isGuest) {
    return items.where((i) => i.ownerId != user.id && i.ownerName != user.fullName).toList();
  }
  return items;
});

final recentlyAddedItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();
  final user = ref.watch(authProvider).user;

  final items = await repository.getRecentlyAdded(maxDistanceKm: maxRadius);
  if (user != null && !user.isGuest) {
    return items.where((i) => i.ownerId != user.id && i.ownerName != user.fullName).toList();
  }
  return items;
});

/// Dedicated provider to fetch current user's own posted listings for Profile screen
final userListingsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final user = ref.watch(authProvider).user;
  if (user == null || user.isGuest) return [];

  final allItems = await repository.getNearbyItems(maxDistanceKm: 15.0);
  return allItems.where((i) => i.ownerId == user.id || i.ownerName == user.fullName).toList();
});

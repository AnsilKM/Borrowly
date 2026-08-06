import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:borrowly/core/location/location_provider.dart';
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

final selectedRadiusProvider = StateProvider<int>((ref) {
  final user = ref.watch(authProvider).user;
  if (user != null && user.searchRadiusKm > 0) {
    return user.searchRadiusKm;
  }
  return 5;
});

final selectedCategoryProvider = StateProvider<ItemCategory>((ref) => ItemCategory.all);

/// Explore / Home Screen feed: uses real GPS coordinates when available
/// to call the PostGIS RPC, filters out the current user's own listings.
final nearbyItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final usecase = ref.watch(getNearbyItemsUseCaseProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();
  final category = ref.watch(selectedCategoryProvider);
  final user = ref.watch(authProvider).user;

  // Derive real lat/lng from GPS location if available
  final locationState = ref.watch(activeLocationProvider).valueOrNull;
  final lat = locationState?.fix?.lat;
  final lng = locationState?.fix?.lng;

  final result = await usecase(GetNearbyItemsParams(
    maxDistanceKm: maxRadius,
    category: category,
    lat: lat,
    lng: lng,
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

/// Calculates the exact count of unique real neighbors who own items within the selected radius
final uniqueNearbyNeighborsProvider = Provider<int>((ref) {
  final items = ref.watch(nearbyItemsProvider).valueOrNull ?? [];
  final user = ref.watch(authProvider).user;

  final Set<String> uniqueNeighborIds = {};

  for (final item in items) {
    if (item.ownerId.isNotEmpty && (user == null || item.ownerId != user.id)) {
      uniqueNeighborIds.add(item.ownerId);
    } else if (item.ownerName.isNotEmpty && (user == null || item.ownerName != user.fullName)) {
      uniqueNeighborIds.add(item.ownerName);
    }
  }

  return uniqueNeighborIds.length;
});

final freeItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();
  final user = ref.watch(authProvider).user;

  final locationState = ref.watch(activeLocationProvider).valueOrNull;
  final lat = locationState?.fix?.lat;
  final lng = locationState?.fix?.lng;

  final items = await repository.getFreeItems(
    maxDistanceKm: maxRadius,
    lat: lat,
    lng: lng,
  );
  if (user != null && !user.isGuest) {
    return items.where((i) => i.ownerId != user.id && i.ownerName != user.fullName).toList();
  }
  return items;
});

final recentlyAddedItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final repository = ref.watch(itemRepositoryProvider);
  final maxRadius = ref.watch(selectedRadiusProvider).toDouble();
  final user = ref.watch(authProvider).user;

  final locationState = ref.watch(activeLocationProvider).valueOrNull;
  final lat = locationState?.fix?.lat;
  final lng = locationState?.fix?.lng;

  final items = await repository.getRecentlyAdded(
    maxDistanceKm: maxRadius,
    lat: lat,
    lng: lng,
  );
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

extension ItemProvidersInvalidator on WidgetRef {
  void invalidateAllItemProviders() {
    invalidate(nearbyItemsProvider);
    invalidate(recentlyAddedItemsProvider);
    invalidate(freeItemsProvider);
    invalidate(userListingsProvider);
  }
}

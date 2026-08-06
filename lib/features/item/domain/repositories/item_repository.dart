import '../entities/item_category.dart';
import '../entities/item_entity.dart';

enum ItemSortOption { nearest, priceLowToHigh, priceHighToLow, newest }

enum ItemPricingFilter { all, freeOnly, paidOnly }

abstract class ItemRepository {
  /// Fetch nearby items matching distance radius and optional category.
  /// When [lat]/[lng] are provided, delegates to the PostGIS RPC for real geospatial queries.
  Future<List<ItemEntity>> getNearbyItems({
    required double maxDistanceKm,
    ItemCategory category = ItemCategory.all,
    double? lat,
    double? lng,
  });

  /// Fetch recently added items within neighborhood radius
  Future<List<ItemEntity>> getRecentlyAdded({
    required double maxDistanceKm,
    double? lat,
    double? lng,
  });

  /// Fetch items offered completely free by neighbors
  Future<List<ItemEntity>> getFreeItems({
    required double maxDistanceKm,
    double? lat,
    double? lng,
  });

  /// Search items with query string, radius, category, pricing, availability, and sorting
  Future<List<ItemEntity>> searchItems({
    required String query,
    required double maxDistanceKm,
    ItemCategory category = ItemCategory.all,
    ItemPricingFilter pricingFilter = ItemPricingFilter.all,
    bool onlyAvailable = false,
    ItemSortOption sortBy = ItemSortOption.nearest,
  });

  /// Add new item listing to neighborhood marketplace with PostGIS coordinates
  Future<ItemEntity> addItem(ItemEntity item, {double? lat, double? lng});

  /// Update existing item listing details in marketplace
  Future<ItemEntity> updateItem(ItemEntity item);

  /// Fetch item details by ID
  Future<ItemEntity?> getItemById(String id);

  /// Permanently delete item listing from neighborhood marketplace
  Future<void> deleteItem(String id);

  /// Toggle item availability (Available vs Paused / Currently Borrowed)
  Future<void> toggleItemAvailability(String id, bool isAvailable);
}

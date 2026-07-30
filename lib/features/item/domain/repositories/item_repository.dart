import '../entities/item_category.dart';
import '../entities/item_entity.dart';

enum ItemSortOption { nearest, priceLowToHigh, priceHighToLow, newest }

enum ItemPricingFilter { all, freeOnly, paidOnly }

abstract class ItemRepository {
  /// Fetch nearby items matching distance radius and optional category
  Future<List<ItemEntity>> getNearbyItems({
    required double maxDistanceKm,
    ItemCategory category = ItemCategory.all,
  });

  /// Fetch recently added items within neighborhood radius
  Future<List<ItemEntity>> getRecentlyAdded({
    required double maxDistanceKm,
  });

  /// Fetch items offered completely free by neighbors
  Future<List<ItemEntity>> getFreeItems({
    required double maxDistanceKm,
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

  /// Add new item listing to neighborhood marketplace
  Future<ItemEntity> addItem(ItemEntity item);

  /// Fetch item details by ID
  Future<ItemEntity?> getItemById(String id);
}

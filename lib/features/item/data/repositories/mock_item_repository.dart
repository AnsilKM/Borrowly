import 'package:flutter/foundation.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/item_repository.dart';

class _SearchParam {
  final List<ItemEntity> items;
  final String query;
  final double maxDistanceKm;
  final ItemCategory category;
  final ItemPricingFilter pricingFilter;
  final bool onlyAvailable;
  final ItemSortOption sortBy;

  _SearchParam({
    required this.items,
    required this.query,
    required this.maxDistanceKm,
    required this.category,
    required this.pricingFilter,
    required this.onlyAvailable,
    required this.sortBy,
  });
}

List<ItemEntity> _filterAndSortItemsIsolate(_SearchParam param) {
  final q = param.query.trim().toLowerCase();

  List<ItemEntity> filtered = param.items.where((item) {
    final matchesDistance = item.distanceKm <= param.maxDistanceKm;
    final matchesCategory = param.category == ItemCategory.all || item.category == param.category;

    final matchesPricing = switch (param.pricingFilter) {
      ItemPricingFilter.all => true,
      ItemPricingFilter.freeOnly => item.isFree,
      ItemPricingFilter.paidOnly => !item.isFree,
    };

    final matchesAvailability = !param.onlyAvailable || item.isAvailable;

    final matchesQuery = q.isEmpty ||
        item.title.toLowerCase().contains(q) ||
        item.description.toLowerCase().contains(q) ||
        item.category.label.toLowerCase().contains(q);

    return matchesDistance && matchesCategory && matchesPricing && matchesAvailability && matchesQuery;
  }).toList();

  switch (param.sortBy) {
    case ItemSortOption.nearest:
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      break;
    case ItemSortOption.priceLowToHigh:
      filtered.sort((a, b) => a.dailyPrice.compareTo(b.dailyPrice));
      break;
    case ItemSortOption.priceHighToLow:
      filtered.sort((a, b) => b.dailyPrice.compareTo(a.dailyPrice));
      break;
    case ItemSortOption.newest:
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
  }

  return filtered;
}

class MockItemRepository implements ItemRepository {
  final List<ItemEntity> _mockItems = [
    ItemEntity(
      id: 'item_1',
      title: 'DeWalt 20V Cordless Hammer Drill',
      description: 'Includes 2 batteries, charger, and heavy-duty drill bit set. Perfect for home projects, shelving, and masonry work. Well maintained and sanitized after every borrow.',
      category: ItemCategory.tools,
      dailyPrice: 8.0,
      isFree: false,
      depositAmount: 50.0,
      images: const [
        'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600',
        'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?w=600',
      ],
      ownerId: 'user_1',
      ownerName: 'Marcus Vance',
      ownerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      distanceKm: 0.8,
      isAvailable: true,
      locationName: 'Oakwood Drive (0.8 km)',
      ratingScore: 4.9,
      reviewCount: 24,
      ownerResponseRate: '< 15 mins',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    ItemEntity(
      id: 'item_2',
      title: 'Coleman 4-Person Camping Tent',
      description: 'Waterproof WeatherTec tent with easy 10-minute setup. Includes rainfly, stakes, and ground tarp. Great for weekend camping trips.',
      category: ItemCategory.camping,
      dailyPrice: 0.0,
      isFree: true,
      depositAmount: 20.0,
      images: const [
        'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=600',
        'https://images.unsplash.com/photo-1478131143081-80f7f84ca84d?w=600',
      ],
      ownerId: 'user_2',
      ownerName: 'Sarah Jenkins',
      ownerAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      distanceKm: 1.2,
      isAvailable: true,
      locationName: 'Pine Street (1.2 km)',
      ratingScore: 5.0,
      reviewCount: 18,
      ownerResponseRate: '< 30 mins',
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    ItemEntity(
      id: 'item_3',
      title: 'Honda Self-Propelled Lawn Mower',
      description: 'Gas-powered 21-inch lawn mower with bagger and mulching blade. Full tank of gas provided on pickup.',
      category: ItemCategory.lawnCare,
      dailyPrice: 12.0,
      isFree: false,
      depositAmount: 60.0,
      images: const ['https://images.unsplash.com/photo-1592417817098-8f3d6ef23a8d?w=600'],
      ownerId: 'user_3',
      ownerName: 'David Miller',
      ownerAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      distanceKm: 1.8,
      isAvailable: true,
      locationName: 'Maple Avenue (1.8 km)',
      ratingScore: 4.8,
      reviewCount: 15,
      ownerResponseRate: '< 1 hour',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ItemEntity(
      id: 'item_4',
      title: 'Sony Alpha 7 III Camera Body + 24-70mm Lens',
      description: 'Full-frame mirrorless camera for professional photography or video projects. Includes 2 batteries, dual SD cards, and padded neck strap.',
      category: ItemCategory.electronics,
      dailyPrice: 25.0,
      isFree: false,
      depositAmount: 150.0,
      images: const ['https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600'],
      ownerId: 'user_4',
      ownerName: 'Elena Rostova',
      ownerAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      distanceKm: 2.4,
      isAvailable: true,
      locationName: 'Highland Ridge (2.4 km)',
      ratingScore: 5.0,
      reviewCount: 32,
      ownerResponseRate: '< 10 mins',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ItemEntity(
      id: 'item_5',
      title: 'Karcher Electric Pressure Washer 2000 PSI',
      description: 'Great for deep cleaning driveways, patio decks, fencing, and car detailing. Includes turbo nozzle and soap applicator.',
      category: ItemCategory.tools,
      dailyPrice: 0.0,
      isFree: true,
      depositAmount: 30.0,
      images: const ['https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600'],
      ownerId: 'user_5',
      ownerName: 'Brian Cox',
      ownerAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      distanceKm: 2.9,
      isAvailable: true,
      locationName: 'Cedar Heights (2.9 km)',
      ratingScore: 4.7,
      reviewCount: 9,
      ownerResponseRate: '< 45 mins',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ItemEntity(
      id: 'item_6',
      title: 'Telescopic Aluminum Extension Ladder 12.5ft',
      description: 'Compact retractable ladder. Fits in small car trunks easily and locks securely. Perfect for roof inspection or high light fixtures.',
      category: ItemCategory.tools,
      dailyPrice: 6.0,
      isFree: false,
      depositAmount: 40.0,
      images: const ['https://images.unsplash.com/photo-1513694203232-719a280e022f?w=600'],
      ownerId: 'user_1',
      ownerName: 'Marcus Vance',
      ownerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      distanceKm: 3.5,
      isAvailable: true,
      locationName: 'Oakwood Drive (3.5 km)',
      ratingScore: 4.9,
      reviewCount: 14,
      ownerResponseRate: '< 15 mins',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    ItemEntity(
      id: 'item_7',
      title: 'Catan & Ticket to Ride Board Game Bundle',
      description: 'Complete family game night bundle. All cards, tiles, and pieces accounted for and in pristine condition.',
      category: ItemCategory.books,
      dailyPrice: 0.0,
      isFree: true,
      depositAmount: 10.0,
      images: const ['https://images.unsplash.com/photo-1610890716171-6b1bb98ffd09?w=600'],
      ownerId: 'user_2',
      ownerName: 'Sarah Jenkins',
      ownerAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      distanceKm: 4.2,
      isAvailable: true,
      locationName: 'Pine Street (4.2 km)',
      ratingScore: 5.0,
      reviewCount: 22,
      ownerResponseRate: '< 30 mins',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  Future<List<ItemEntity>> getNearbyItems({
    required double maxDistanceKm,
    ItemCategory category = ItemCategory.all,
  }) async {
    return compute(
      _filterAndSortItemsIsolate,
      _SearchParam(
        items: List.of(_mockItems),
        query: '',
        maxDistanceKm: maxDistanceKm,
        category: category,
        pricingFilter: ItemPricingFilter.all,
        onlyAvailable: false,
        sortBy: ItemSortOption.nearest,
      ),
    );
  }

  @override
  Future<List<ItemEntity>> getRecentlyAdded({required double maxDistanceKm}) async {
    return compute(
      _filterAndSortItemsIsolate,
      _SearchParam(
        items: List.of(_mockItems),
        query: '',
        maxDistanceKm: maxDistanceKm,
        category: ItemCategory.all,
        pricingFilter: ItemPricingFilter.all,
        onlyAvailable: false,
        sortBy: ItemSortOption.newest,
      ),
    );
  }

  @override
  Future<List<ItemEntity>> getFreeItems({required double maxDistanceKm}) async {
    return compute(
      _filterAndSortItemsIsolate,
      _SearchParam(
        items: List.of(_mockItems),
        query: '',
        maxDistanceKm: maxDistanceKm,
        category: ItemCategory.all,
        pricingFilter: ItemPricingFilter.freeOnly,
        onlyAvailable: false,
        sortBy: ItemSortOption.nearest,
      ),
    );
  }

  @override
  Future<List<ItemEntity>> searchItems({
    required String query,
    required double maxDistanceKm,
    ItemCategory category = ItemCategory.all,
    ItemPricingFilter pricingFilter = ItemPricingFilter.all,
    bool onlyAvailable = false,
    ItemSortOption sortBy = ItemSortOption.nearest,
  }) async {
    return compute(
      _filterAndSortItemsIsolate,
      _SearchParam(
        items: List.of(_mockItems),
        query: query,
        maxDistanceKm: maxDistanceKm,
        category: category,
        pricingFilter: pricingFilter,
        onlyAvailable: onlyAvailable,
        sortBy: sortBy,
      ),
    );
  }

  @override
  Future<ItemEntity> addItem(ItemEntity item) async {
    _mockItems.insert(0, item);
    return item;
  }

  @override
  Future<ItemEntity?> getItemById(String id) async {
    try {
      return _mockItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }
}

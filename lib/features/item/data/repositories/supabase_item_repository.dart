import 'package:flutter/foundation.dart';
import '../../../../core/network/supabase_service.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/item_repository.dart';
import 'mock_item_repository.dart';

class SupabaseItemRepository implements ItemRepository {
  final MockItemRepository _fallbackMockRepo = MockItemRepository();

  ItemEntity _mapSupabaseRowToEntity(Map<String, dynamic> row) {
    final catString = row['category'] as String? ?? 'tools';
    final category = ItemCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == catString.toLowerCase(),
      orElse: () => ItemCategory.tools,
    );

    return ItemEntity(
      id: row['id'] as String? ?? '',
      title: row['title'] as String? ?? 'Untitled Item',
      description: row['description'] as String? ?? '',
      category: category,
      dailyPrice: (row['daily_price'] as num?)?.toDouble() ?? 0.0,
      isFree: row['is_free'] as bool? ?? false,
      depositAmount: (row['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      images: (row['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600'],
      ownerId: row['owner_id'] as String? ?? 'user_1',
      ownerName: row['owner_name'] as String? ?? 'Neighbor',
      ownerAvatar: row['owner_avatar'] as String?,
      distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 1.2,
      isAvailable: row['is_available'] as bool? ?? true,
      locationName: row['location_name'] as String? ?? 'Nearby Neighborhood',
      ratingScore: (row['rating_score'] as num?)?.toDouble() ?? 4.9,
      reviewCount: row['review_count'] as int? ?? 12,
      ownerResponseRate: row['owner_response_rate'] as String? ?? '< 30 mins',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  Future<List<ItemEntity>> getNearbyItems({
    required double maxDistanceKm,
    ItemCategory category = ItemCategory.all,
  }) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client.rpc(
          'get_nearby_items',
          params: {
            'user_lat': 37.7749,
            'user_lng': -122.4194,
            'radius_km': maxDistanceKm,
          },
        ).select();

        final rows = response as List<dynamic>;
        final items = rows.map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>)).toList();

        if (category != ItemCategory.all) {
          return items.where((i) => i.category == category).toList();
        }
        return items;
      } catch (e) {
        debugPrint('Supabase getNearbyItems fallback to local isolate: $e');
      }
    }

    return _fallbackMockRepo.getNearbyItems(maxDistanceKm: maxDistanceKm, category: category);
  }

  @override
  Future<List<ItemEntity>> getRecentlyAdded({required double maxDistanceKm}) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client
            .from('items')
            .select()
            .order('created_at', ascending: false)
            .limit(20);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Supabase getRecentlyAdded fallback to local isolate: $e');
      }
    }

    return _fallbackMockRepo.getRecentlyAdded(maxDistanceKm: maxDistanceKm);
  }

  @override
  Future<List<ItemEntity>> getFreeItems({required double maxDistanceKm}) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client
            .from('items')
            .select()
            .eq('is_free', true)
            .limit(20);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Supabase getFreeItems fallback to local isolate: $e');
      }
    }

    return _fallbackMockRepo.getFreeItems(maxDistanceKm: maxDistanceKm);
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
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured && query.isNotEmpty) {
      try {
        final response = await client
            .from('items')
            .select()
            .ilike('title', '%$query%')
            .limit(30);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Supabase searchItems fallback to local isolate: $e');
      }
    }

    return _fallbackMockRepo.searchItems(
      query: query,
      maxDistanceKm: maxDistanceKm,
      category: category,
      pricingFilter: pricingFilter,
      onlyAvailable: onlyAvailable,
      sortBy: sortBy,
    );
  }

  @override
  Future<ItemEntity> addItem(ItemEntity item) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final row = {
          'title': item.title,
          'description': item.description,
          'category': item.category.name,
          'daily_price': item.dailyPrice,
          'is_free': item.isFree,
          'deposit_amount': item.depositAmount,
          'images': item.images,
          'owner_id': item.ownerId,
          'owner_name': item.ownerName,
          'location_name': item.locationName,
          'is_available': true,
        };

        final response = await client.from('items').insert(row).select().single();
        return _mapSupabaseRowToEntity(response);
      } catch (e) {
        debugPrint('Supabase addItem fallback to local: $e');
      }
    }

    return _fallbackMockRepo.addItem(item);
  }

  @override
  Future<ItemEntity?> getItemById(String id) async {
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client.from('items').select().eq('id', id).maybeSingle();
        if (response != null) {
          return _mapSupabaseRowToEntity(response);
        }
      } catch (e) {
        debugPrint('Supabase getItemById fallback to local: $e');
      }
    }

    return _fallbackMockRepo.getItemById(id);
  }
}

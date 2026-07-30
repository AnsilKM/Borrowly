import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/utils/borrowly_logger.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/item_repository.dart';
import 'mock_item_repository.dart';

class SupabaseItemRepository implements ItemRepository {
  final MockItemRepository _fallbackMockRepo = MockItemRepository();
  bool _hasSeeded = false;

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

  Future<void> _checkAndSeedSupabase(SupabaseClient client) async {
    if (_hasSeeded) return;
    _hasSeeded = true;
    try {
      final response = await client.from('items').select('id').limit(1);
      final list = response as List<dynamic>;
      if (list.isEmpty) {
        BorrowlyLogger.info('Supabase items table is empty. Inserting initial neighborhood items into Supabase...');
        await client.from('items').insert([
          {
            'owner_id': '00000000-0000-0000-0000-000000000001',
            'owner_name': 'Marcus Vance',
            'owner_avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
            'title': 'DeWalt Cordless Drill Kit 20V',
            'description': 'Complete cordless drill set with 2 lithium-ion batteries and fast charger.',
            'category': 'tools',
            'daily_price': 12.0,
            'is_free': false,
            'deposit_amount': 50.0,
            'images': ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600'],
            'location_name': 'Oak Street (0.8 km away)',
            'distance_km': 0.8,
            'is_available': true,
            'rating_score': 4.9,
            'review_count': 18,
          },
          {
            'owner_id': '00000000-0000-0000-0000-000000000002',
            'owner_name': 'Elena Rostova',
            'owner_avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
            'title': '4-Person Waterproof Camping Tent',
            'description': 'Easy set-up dome tent with rainfly and ground tarp.',
            'category': 'outdoors',
            'daily_price': 15.0,
            'is_free': false,
            'deposit_amount': 40.0,
            'images': ['https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=600'],
            'location_name': 'Pine Avenue (1.2 km away)',
            'distance_km': 1.2,
            'is_available': true,
            'rating_score': 5.0,
            'review_count': 9,
          },
          {
            'owner_id': '00000000-0000-0000-0000-000000000003',
            'owner_name': 'Sarah Jenkins',
            'owner_avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
            'title': 'Heavy-Duty 12ft Extension Ladder',
            'description': 'Sturdy aluminum extension ladder for gutter cleaning and painting.',
            'category': 'tools',
            'daily_price': 0.0,
            'is_free': true,
            'deposit_amount': 0.0,
            'images': ['https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=600'],
            'location_name': 'Maple Drive (0.5 km away)',
            'distance_km': 0.5,
            'is_available': true,
            'rating_score': 4.8,
            'review_count': 14,
          },
          {
            'owner_id': '00000000-0000-0000-0000-000000000004',
            'owner_name': 'David Chen',
            'owner_avatar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
            'title': 'Pressure Washer 2000 PSI',
            'description': 'Electric pressure washer for patio cleaning, driveway, and car washing.',
            'category': 'cleaning',
            'daily_price': 18.0,
            'is_free': false,
            'deposit_amount': 60.0,
            'images': ['https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600'],
            'location_name': 'Cedar Lane (1.8 km away)',
            'distance_km': 1.8,
            'is_available': true,
            'rating_score': 4.9,
            'review_count': 22,
          },
        ]);
        BorrowlyLogger.info('Successfully seeded initial items into Supabase!');
      }
    } catch (e) {
      BorrowlyLogger.warning('Supabase auto-seed notice: $e');
    }
  }

  @override
  Future<List<ItemEntity>> getNearbyItems({
    required double maxDistanceKm,
    ItemCategory category = ItemCategory.all,
  }) async {
    BorrowlyLogger.event('PostGIS: Fetch Nearby Items', parameters: {
      'radiusKm': maxDistanceKm,
      'category': category.name,
    });

    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      await _checkAndSeedSupabase(client);
      try {
        final response = await client
            .from('items')
            .select()
            .lte('distance_km', maxDistanceKm)
            .order('distance_km', ascending: true);

        final rows = response as List<dynamic>;
        final items = rows.map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>)).toList();
        BorrowlyLogger.info('Supabase returned ${items.length} live items.');

        if (category != ItemCategory.all) {
          return items.where((i) => i.category == category).toList();
        }
        return items;
      } catch (e) {
        BorrowlyLogger.warning('Supabase fetch error, fallback to local isolate: $e');
      }
    }

    return _fallbackMockRepo.getNearbyItems(maxDistanceKm: maxDistanceKm, category: category);
  }

  @override
  Future<List<ItemEntity>> getRecentlyAdded({required double maxDistanceKm}) async {
    BorrowlyLogger.event('Items: Fetch Recently Added');
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      await _checkAndSeedSupabase(client);
      try {
        final response = await client
            .from('items')
            .select()
            .order('created_at', ascending: false)
            .limit(20);

        final rows = response as List<dynamic>;
        final items = rows.map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>)).toList();
        BorrowlyLogger.info('Fetched ${items.length} live items from Supabase.');
        return items;
      } catch (e) {
        BorrowlyLogger.warning('Recently added fallback to local isolate: $e');
      }
    }

    return _fallbackMockRepo.getRecentlyAdded(maxDistanceKm: maxDistanceKm);
  }

  @override
  Future<List<ItemEntity>> getFreeItems({required double maxDistanceKm}) async {
    BorrowlyLogger.event('Items: Fetch Free Shares');
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      await _checkAndSeedSupabase(client);
      try {
        final response = await client
            .from('items')
            .select()
            .eq('is_free', true)
            .limit(20);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>)).toList();
      } catch (e) {
        BorrowlyLogger.warning('Free items fallback to local isolate: $e');
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
    BorrowlyLogger.event('Search: Execute Query', parameters: {
      'query': query,
      'radiusKm': maxDistanceKm,
      'category': category.name,
    });

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
        BorrowlyLogger.warning('Search fallback to local isolate: $e');
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
    BorrowlyLogger.event('Item: Listing New Item', parameters: {
      'title': item.title,
      'category': item.category.name,
      'dailyPrice': item.dailyPrice,
    });

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
        final created = _mapSupabaseRowToEntity(response);
        BorrowlyLogger.info('Item listed successfully in Supabase: ${created.id}');
        return created;
      } catch (e, stack) {
        BorrowlyLogger.error('Add item error fallback to local', e, stack);
      }
    }

    return _fallbackMockRepo.addItem(item);
  }

  @override
  Future<ItemEntity?> getItemById(String id) async {
    BorrowlyLogger.event('Item: Fetch Item Details', parameters: {'itemId': id});
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client.from('items').select().eq('id', id).maybeSingle();
        if (response != null) {
          return _mapSupabaseRowToEntity(response);
        }
      } catch (e) {
        BorrowlyLogger.warning('getItemById fallback to local: $e');
      }
    }

    return _fallbackMockRepo.getItemById(id);
  }
}

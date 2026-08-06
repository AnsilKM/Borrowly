import 'package:flutter/foundation.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/network/supabase_storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/borrowly_logger.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/item_repository.dart';

class SupabaseItemRepository implements ItemRepository {
  static final Map<String, bool> _availabilityOverrides = {};

  ItemEntity _mapSupabaseRowToEntity(Map<String, dynamic> row) {
    final rawCategoryStr = row['category'] as String? ?? 'other';
    final category = ItemCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == rawCategoryStr.toLowerCase(),
      orElse: () => ItemCategory.other,
    );

    final itemId = row['id'] as String? ?? '';
    final rawIsAvailable = row['is_available'] as bool? ?? true;
    final persistentOverrides = _localStorageService.getAvailabilityOverrides();
    final isAvailable = _availabilityOverrides.containsKey(itemId)
        ? _availabilityOverrides[itemId]!
        : (persistentOverrides.containsKey(itemId)
            ? persistentOverrides[itemId]!
            : rawIsAvailable);

    final ownerId = row['owner_id'] as String? ?? 'user_1';
    var ownerName = row['owner_name'] as String? ?? 'Neighbor';
    var ownerAvatar = row['owner_avatar'] as String?;

    try {
      final cachedUser = _localStorageService.getCachedUserProfile();
      if (cachedUser != null) {
        final cachedId = cachedUser['id'] as String? ?? '';
        final cachedName = cachedUser['full_name'] as String? ?? '';
        final cachedAvatar = cachedUser['avatar_url'] as String?;
        final isGuest = cachedUser['is_guest'] as bool? ?? false;

        if (!isGuest && (ownerId == cachedId || ownerId == '00000000-0000-0000-0000-000000000001')) {
          if (cachedName.isNotEmpty) {
            ownerName = cachedName;
          }
          if (cachedAvatar != null && cachedAvatar.isNotEmpty) {
            ownerAvatar = cachedAvatar;
          } else {
            ownerAvatar = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(ownerName.isNotEmpty ? ownerName : "Neighbor")}&background=0D9488&color=ffffff&bold=true&size=200';
          }
        }
      }
    } catch (_) {}

    return ItemEntity(
      id: itemId,
      title: row['title'] as String? ?? 'Untitled Item',
      description: row['description'] as String? ?? '',
      category: category,
      dailyPrice: (row['daily_price'] as num?)?.toDouble() ?? 0.0,
      isFree: row['is_free'] as bool? ?? false,
      depositAmount: (row['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      images: (row['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600'],
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatar: ownerAvatar,
      distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 1.2,
      isAvailable: isAvailable,
      locationName: row['location_name'] as String? ?? 'Nearby Neighborhood',
      ratingScore: (row['rating_score'] as num?)?.toDouble() ?? 4.9,
      reviewCount: row['review_count'] as int? ?? 12,
      ownerResponseRate: row['owner_response_rate'] as String? ?? '< 30 mins',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final LocalStorageService _localStorageService = LocalStorageService();

  @override
  Future<List<ItemEntity>> getNearbyItems({
    required double maxDistanceKm,
    ItemCategory category = ItemCategory.all,
    double? lat,
    double? lng,
  }) async {
    BorrowlyLogger.event('PostGIS: Fetch Nearby Items', parameters: {
      'radiusKm': maxDistanceKm,
      'category': category.name,
      'hasCoords': lat != null,
    });

    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        List<dynamic> rows;

        if (lat != null && lng != null) {
          // ── Real PostGIS RPC: filters by actual GPS distance ─────────────
          BorrowlyLogger.info('Using PostGIS RPC get_nearby_items at ($lat, $lng)');
          try {
            rows = await client.rpc('get_nearby_items', params: {
              'lat': lat,
              'lng': lng,
              'radius_km': maxDistanceKm,
              'category_filter': category == ItemCategory.all ? 'all' : category.name,
            });
          } catch (e) {
            BorrowlyLogger.warning('RPC get_nearby_items notice: $e — using items query fallback');
            rows = await client
                .from('items')
                .select()
                .order('created_at', ascending: false);
          }
        } else {
          // ── Fallback: static distance_km column (no GPS) ─────────────────
          BorrowlyLogger.info('No GPS coordinates — using static distance_km fallback.');
          rows = await client
              .from('items')
              .select()
              .order('created_at', ascending: false);
        }

        final deletedIds = _localStorageService.getDeletedItemIds();
        final rawRows = rows
            .map((r) => Map<String, dynamic>.from(r as Map))
            .where((r) => !deletedIds.contains(r['id'] as String? ?? ''))
            .toList();
        _localStorageService.cacheNearbyItems(rawRows);

        final items = rawRows
            .map((r) => _mapSupabaseRowToEntity(r))
            .toList();
        BorrowlyLogger.info('Supabase returned ${items.length} live items after filtering deleted items.');

        if (category != ItemCategory.all && lat != null) {
          // RPC already filters by category — no double-filter needed.
          return items;
        }
        if (category != ItemCategory.all) {
          return items.where((i) => i.category == category).toList();
        }
        return items;
      } catch (e) {
        BorrowlyLogger.warning('Supabase fetch error, reading Hive local cache: $e');
      }
    }

    // Fast Hive Local Cache Fallback (< 5ms response time)
    final deletedIds = _localStorageService.getDeletedItemIds();
    final cachedRaw = _localStorageService.getCachedNearbyItems();
    if (cachedRaw.isNotEmpty) {
      final cachedItems = cachedRaw
          .map((r) => _mapSupabaseRowToEntity(r))
          .where((i) => !deletedIds.contains(i.id))
          .toList();
      BorrowlyLogger.info('Loaded ${cachedItems.length} items from Hive local storage cache.');
      if (category != ItemCategory.all) {
        return cachedItems.where((i) => i.category == category).toList();
      }
      return cachedItems;
    }

    return [];
  }

  @override
  Future<List<ItemEntity>> getRecentlyAdded({
    required double maxDistanceKm,
    double? lat,
    double? lng,
  }) async {
    BorrowlyLogger.event('Items: Fetch Recently Added');
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        List<dynamic> rows;
        if (lat != null && lng != null) {
          try {
            rows = await client.rpc('get_nearby_items', params: {
              'lat': lat,
              'lng': lng,
              'radius_km': maxDistanceKm,
              'category_filter': 'all',
            });
            // Sort by created_at descending for "recently added" semantics
            rows = List<dynamic>.from(rows)
              ..sort((a, b) {
                final aDate = a['created_at'] as String? ?? '';
                final bDate = b['created_at'] as String? ?? '';
                return bDate.compareTo(aDate);
              });
            if (rows.length > 20) rows = rows.sublist(0, 20);
          } catch (e) {
            rows = await client
                .from('items')
                .select()
                .order('created_at', ascending: false)
                .limit(20);
          }
        } else {
          rows = await client
              .from('items')
              .select()
              .order('created_at', ascending: false)
              .limit(20);
        }
        final deletedIds = _localStorageService.getDeletedItemIds();
        final items = rows
            .map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>))
            .where((i) => !deletedIds.contains(i.id))
            .toList();
        BorrowlyLogger.info('Fetched ${items.length} recently added items from Supabase.');
        return items;
      } catch (e) {
        BorrowlyLogger.warning('Recently added fetch error: $e');
      }
    }
    return [];
  }

  @override
  Future<List<ItemEntity>> getFreeItems({
    required double maxDistanceKm,
    double? lat,
    double? lng,
  }) async {
    BorrowlyLogger.event('Items: Fetch Free Shares');
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        List<dynamic> rows;
        if (lat != null && lng != null) {
          final allNearby = await client.rpc('get_nearby_items', params: {
            'lat': lat,
            'lng': lng,
            'radius_km': maxDistanceKm,
            'category_filter': 'all',
          }) as List<dynamic>;
          rows = allNearby.where((r) => (r as Map)['is_free'] == true).toList();
        } else {
          rows = await client
              .from('items')
              .select()
              .eq('is_free', true)
              .limit(20);
        }
        final deletedIds = _localStorageService.getDeletedItemIds();
        return rows
            .map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>))
            .where((i) => !deletedIds.contains(i.id))
            .toList();
      } catch (e) {
        BorrowlyLogger.warning('Free items fetch error: $e');
      }
    }
    return [];
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
            .or('title.ilike.%$query%,description.ilike.%$query%');

        final rows = response as List<dynamic>;
        final deletedIds = _localStorageService.getDeletedItemIds();
        return rows
            .map((r) => _mapSupabaseRowToEntity(r as Map<String, dynamic>))
            .where((i) => !deletedIds.contains(i.id))
            .toList();
      } catch (e) {
        BorrowlyLogger.warning('Search error: $e');
      }
    }

    return [];
  }

  @override
  Future<ItemEntity> addItem(ItemEntity item, {double? lat, double? lng}) async {
    BorrowlyLogger.event('Item: Listing New Item', parameters: {
      'title': item.title,
      'category': item.category.name,
      'dailyPrice': item.dailyPrice,
    });

    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final authUser = client.auth.currentUser;
        final validOwnerId = authUser != null
            ? authUser.id
            : ((item.ownerId.length == 36 && item.ownerId.contains('-'))
                ? item.ownerId
                : '00000000-0000-0000-0000-000000000001');

        if (validOwnerId.length == 36 && validOwnerId.contains('-')) {
          try {
            await client.from('users').upsert({
              'id': validOwnerId,
              'full_name': item.ownerName,
              'email': authUser?.email ?? 'neighbor@borrowly.com',
              'avatar_url': item.ownerAvatar,
            });
            BorrowlyLogger.info('Ensured owner ID $validOwnerId exists in public.users table.');
          } catch (e) {
            BorrowlyLogger.warning('Owner upsert notice: $e');
          }
        }

        // Upload local device images to Supabase Storage Bucket ('item-images')
        final cloudImageUrls = await SupabaseStorageService.uploadItemImages(item.images);

        final pointWkt = (lat != null && lng != null)
            ? 'POINT($lng $lat)'
            : 'POINT(75.8285 11.2548)';

        final row = {
          'title': item.title,
          'description': item.description,
          'category': item.category.name,
          'daily_price': item.dailyPrice,
          'is_free': item.isFree,
          'deposit_amount': item.depositAmount,
          'images': cloudImageUrls.isNotEmpty ? cloudImageUrls : item.images,
          'owner_id': validOwnerId,
          'owner_name': item.ownerName,
          'location_name': item.locationName,
          'location': pointWkt,
          'is_available': true,
        };

        final response = await client.from('items').insert(row).select().single();
        final created = _mapSupabaseRowToEntity(response);
        BorrowlyLogger.info('Item listed successfully in Supabase: ${created.id}');
        return created;
      } catch (e, stack) {
        BorrowlyLogger.error('Add item error in Supabase', e, stack);
        debugPrint('❌ [SUPABASE ADD ITEM LOGCAT ERROR]: $e \n $stack');
        rethrow;
      }
    }

    throw Exception('Supabase service is not available');
  }

  @override
  Future<ItemEntity?> getItemById(String id) async {
    if (id.isEmpty) return null;
    BorrowlyLogger.event('Item: Fetch Item Details', parameters: {'itemId': id});
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final response = await client.from('items').select().eq('id', id).maybeSingle();
        if (response != null) {
          return _mapSupabaseRowToEntity(response);
        }
      } catch (e) {
        BorrowlyLogger.warning('getItemById error: $e');
      }
    }

    // Local storage fallback for offline / test items
    try {
      final cachedItems = LocalStorageService().getCachedNearbyItems();
      for (final itemMap in cachedItems) {
        if (itemMap['id'] == id) {
          return _mapSupabaseRowToEntity(itemMap);
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<ItemEntity> updateItem(ItemEntity item) async {
    BorrowlyLogger.event('Item: Update Listing', parameters: {'itemId': item.id, 'title': item.title});

    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final updatedRows = await client.from('items').update({
          'title': item.title,
          'description': item.description,
          'category': item.category.name,
          'daily_price': item.dailyPrice,
          'is_free': item.isFree,
          'deposit_amount': item.depositAmount,
          'images': item.images,
          'location_name': item.locationName,
        }).eq('id', item.id).select();
        BorrowlyLogger.info('Listing updated successfully in Supabase: ${item.id}. Result: $updatedRows');
      } catch (e) {
        BorrowlyLogger.warning('Supabase item update notice: $e');
      }
    }

    try {
      final cached = _localStorageService.getCachedNearbyItems();
      final updated = cached.map((m) {
        if (m['id'] == item.id) {
          final map = Map<String, dynamic>.from(m);
          map['title'] = item.title;
          map['description'] = item.description;
          map['category'] = item.category.name;
          map['daily_price'] = item.dailyPrice;
          map['is_free'] = item.isFree;
          map['deposit_amount'] = item.depositAmount;
          map['images'] = item.images;
          map['location_name'] = item.locationName;
          return map;
        }
        return m;
      }).toList();
      _localStorageService.cacheNearbyItems(updated);
    } catch (_) {}

    return item;
  }

  @override
  Future<void> deleteItem(String id) async {
    if (id.isEmpty) return;
    BorrowlyLogger.event('Item: Delete Listing', parameters: {'itemId': id});

    // 1. Local Hive Cache Cleanup & Persistent Deleted ID Tracking
    try {
      await _localStorageService.deleteCachedItem(id);
    } catch (e) {
      BorrowlyLogger.warning('Local cache item delete notice: $e');
    }

    // 2. Supabase Cloud Delete
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final deletedRows = await client.from('items').delete().eq('id', id).select();
        BorrowlyLogger.info('Item $id permanently deleted from Supabase. Result: $deletedRows');
      } catch (e) {
        BorrowlyLogger.error('Supabase delete item error notice: $e');
      }
    }
  }

  @override
  Future<void> toggleItemAvailability(String id, bool isAvailable) async {
    if (id.isEmpty) return;
    BorrowlyLogger.event('Item: Toggle Availability', parameters: {'itemId': id, 'isAvailable': isAvailable});

    // 0. Set in-memory and persistent availability overrides
    _availabilityOverrides[id] = isAvailable;
    await _localStorageService.setAvailabilityOverride(id, isAvailable);

    // 1. Update Hive Local Storage Cache immediately
    try {
      final cached = _localStorageService.getCachedNearbyItems();
      final updated = cached.map((itemMap) {
        if (itemMap['id'] == id) {
          final m = Map<String, dynamic>.from(itemMap);
          m['is_available'] = isAvailable;
          return m;
        }
        return itemMap;
      }).toList();
      _localStorageService.cacheNearbyItems(updated);
    } catch (e) {
      BorrowlyLogger.warning('Local cache update availability notice: $e');
    }

    // 2. Update Supabase Database
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final res = await client.from('items').update({'is_available': isAvailable}).eq('id', id).select();
        BorrowlyLogger.info('Item $id availability updated to $isAvailable in Supabase. Result: $res');
      } catch (e) {
        BorrowlyLogger.error('Supabase toggle availability notice: $e');
      }
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:borrowly/core/network/supabase_service.dart';
import 'package:borrowly/core/utils/borrowly_logger.dart';
import '../../domain/entities/item_entity.dart';
import 'home_items_provider.dart';

class WishlistNotifier extends StateNotifier<Set<String>> {
  static const String _boxName = 'borrowly_wishlist';
  static const String _key = 'wishlist_ids';
  Box? _box;

  WishlistNotifier() : super({}) {
    _init();
  }

  Future<void> _init() async {
    try {
      _box = await Hive.openBox(_boxName);
      final List<dynamic>? savedList = _box?.get(_key);
      if (savedList != null) {
        state = Set<String>.from(savedList);
      }
    } catch (_) {
      // Fallback to initial empty set if Hive not ready
    }

    // Sync remote favorites from Supabase backend if authenticated
    final client = SupabaseService.client;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        final response = await client
            .from('favorites')
            .select('item_id')
            .eq('user_id', userId);
        final List<dynamic> rows = response as List<dynamic>;
        final remoteIds = rows.map((r) => r['item_id'] as String).toSet();

        final merged = {...state, ...remoteIds};
        state = merged;
        await _box?.put(_key, merged.toList());
        BorrowlyLogger.info('Wishlist synced with Supabase DB for user: $userId');
      } catch (e) {
        BorrowlyLogger.info('Supabase favorites table sync note (offline or initial): $e');
      }
    }
  }

  Future<void> toggleWishlist(String itemId) async {
    final isAdding = !state.contains(itemId);
    final nextState = Set<String>.from(state);
    if (isAdding) {
      nextState.add(itemId);
    } else {
      nextState.remove(itemId);
    }
    state = nextState;

    // 1. Fast Local Hive Storage
    try {
      _box ??= await Hive.openBox(_boxName);
      await _box?.put(_key, state.toList());
    } catch (_) {}

    // 2. Sync with Supabase PostgreSQL Backend
    final client = SupabaseService.client;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        if (isAdding) {
          await client.from('favorites').upsert(
            {
              'user_id': userId,
              'item_id': itemId,
            },
            onConflict: 'user_id, item_id',
          );
        } else {
          await client
              .from('favorites')
              .delete()
              .eq('user_id', userId)
              .eq('item_id', itemId);
        }
      } catch (e) {
        BorrowlyLogger.warning('Notice updating Supabase favorites DB: $e');
      }
    }
  }

  bool isWishlisted(String itemId) => state.contains(itemId);
}

final wishlistIdsProvider = StateNotifierProvider<WishlistNotifier, Set<String>>((ref) {
  return WishlistNotifier();
});

final isItemWishlistedProvider = Provider.family<bool, String>((ref, itemId) {
  final wishlistedIds = ref.watch(wishlistIdsProvider);
  return wishlistedIds.contains(itemId);
});

final wishlistItemsProvider = FutureProvider<List<ItemEntity>>((ref) async {
  final wishlistedIds = ref.watch(wishlistIdsProvider);
  if (wishlistedIds.isEmpty) return [];

  final repository = ref.watch(itemRepositoryProvider);
  final allItems = await repository.getNearbyItems(maxDistanceKm: 100);

  return allItems.where((item) => wishlistedIds.contains(item.id)).toList();
});
